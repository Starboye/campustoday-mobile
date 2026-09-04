<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TeacherAllocationService
{
    public function hasAllocationTable(): bool
    {
        return Schema::hasTable('teacher_subject_allocation');
    }

    /**
     * @return Collection<int, object>
     */
    public function allocations(string $teacherId): Collection
    {
        if (! $this->hasAllocationTable()) {
            return collect();
        }

        $columns = ['id', 'teacher_id', 'standard', 'section'];
        foreach (['subject_id', 'subject_name', 'subject', 'is_class_teacher'] as $column) {
            if (Schema::hasColumn('teacher_subject_allocation', $column)) {
                $columns[] = $column;
            }
        }

        return DB::table('teacher_subject_allocation')
            ->where('teacher_id', $teacherId)
            ->orderBy('standard')
            ->orderBy('section')
            ->orderBy('subject_name')
            ->get($columns);
    }

    /**
     * @return array<int, array{standard: int, section: string}>
     */
    public function distinctClassSections(string $teacherId): array
    {
        $seen = [];
        $result = [];

        foreach ($this->allocations($teacherId) as $row) {
            if ($row->standard === null || $row->section === null) {
                continue;
            }

            $key = (int) $row->standard.'|'.(string) $row->section;
            if (isset($seen[$key])) {
                continue;
            }

            $seen[$key] = true;
            $result[] = [
                'standard' => (int) $row->standard,
                'section' => (string) $row->section,
            ];
        }

        return $result;
    }

    public function isAllocatedToClass(string $teacherId, int $standard, string $section): bool
    {
        foreach ($this->distinctClassSections($teacherId) as $classSection) {
            if ($classSection['standard'] === $standard && $classSection['section'] === $section) {
                return true;
            }
        }

        return false;
    }

    public function isAllocatedToSubject(
        string $teacherId,
        int $standard,
        string $section,
        ?string $subjectName = null,
        ?string $subjectId = null,
    ): bool {
        foreach ($this->allocations($teacherId) as $row) {
            if ((int) $row->standard !== $standard || (string) $row->section !== $section) {
                continue;
            }

            if ($subjectName === null && $subjectId === null) {
                return true;
            }

            $rowSubjectName = $this->subjectName($row);
            $rowSubjectId = $this->subjectId($row);

            if ($subjectName !== null && strcasecmp($rowSubjectName, $subjectName) === 0) {
                return true;
            }

            if ($subjectId !== null && (string) $rowSubjectId === (string) $subjectId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return array{standard: int, section: string}|null
     */
    public function classTeacherOf(string $teacherId): ?array
    {
        if ($this->hasAllocationTable() && Schema::hasColumn('teacher_subject_allocation', 'is_class_teacher')) {
            $row = DB::table('teacher_subject_allocation')
                ->where('teacher_id', $teacherId)
                ->where('is_class_teacher', 1)
                ->first(['standard', 'section']);

            if ($row && $row->standard !== null && $row->section !== null) {
                return ['standard' => (int) $row->standard, 'section' => (string) $row->section];
            }
        }

        if (Schema::hasTable('class_timetables')) {
            $query = DB::table('class_timetables');
            if (Schema::hasColumn('class_timetables', 'class_teacher_id')) {
                $row = $query->where('class_teacher_id', $teacherId)->first(['standard', 'section']);
            } elseif (Schema::hasColumn('class_timetables', 'teacher_id')) {
                $row = $query->where('teacher_id', $teacherId)->first(['standard', 'section']);
            } else {
                $row = null;
            }

            if ($row && $row->standard !== null && $row->section !== null) {
                return ['standard' => (int) $row->standard, 'section' => (string) $row->section];
            }
        }

        if (Schema::hasTable('student_info') && Schema::hasColumn('student_info', 'class_teacher_id')) {
            $row = DB::table('student_info')
                ->where('class_teacher_id', $teacherId)
                ->whereNotNull('standard')
                ->whereNotNull('section')
                ->select(['standard', 'section'])
                ->first();

            if ($row) {
                return ['standard' => (int) $row->standard, 'section' => (string) $row->section];
            }
        }

        return null;
    }

    public function isClassTeacher(string $teacherId, int $standard, string $section): bool
    {
        $classTeacher = $this->classTeacherOf($teacherId);

        return $classTeacher !== null
            && $classTeacher['standard'] === $standard
            && $classTeacher['section'] === $section;
    }

    /**
     * @return Collection<int, object>
     */
    public function studentsInAllocatedClasses(string $teacherId): Collection
    {
        $classSections = $this->distinctClassSections($teacherId);
        if ($classSections === []) {
            return collect();
        }

        return DB::table('student_info')
            ->where(function ($query) use ($classSections) {
                foreach ($classSections as $classSection) {
                    $query->orWhere(function ($q) use ($classSection) {
                        $q->where('standard', $classSection['standard'])
                            ->where('section', $classSection['section']);
                    });
                }
            })
            ->orderBy('standard')
            ->orderBy('section')
            ->orderBy('name')
            ->get();
    }

    public function canAccessStudent(string $teacherId, string $studentId): bool
    {
        $student = DB::table('student_info')->where('id', $studentId)->first(['standard', 'section']);
        if (! $student || $student->standard === null || $student->section === null) {
            return false;
        }

        return $this->isAllocatedToClass($teacherId, (int) $student->standard, (string) $student->section);
    }

    public function formatAllocation(object $row): array
    {
        return [
            'id' => (string) $row->id,
            'standard' => (int) $row->standard,
            'section' => (string) $row->section,
            'subject_id' => (string) $this->subjectId($row),
            'subject_name' => (string) $this->subjectName($row),
            'is_class_teacher' => (bool) ($row->is_class_teacher ?? false),
        ];
    }

    private function subjectName(object $row): string
    {
        return (string) ($row->subject_name ?? $row->subject ?? '');
    }

    private function subjectId(object $row): string
    {
        return (string) ($row->subject_id ?? $row->subject_name ?? $row->subject ?? $row->id);
    }
}
