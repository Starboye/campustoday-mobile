<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class StudentsController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function index(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $students = $this->allocations->studentsInAllocatedClasses($teacherId);

        if ($request->filled('class')) {
            $students = $students->where('standard', (int) $request->query('class'));
        }

        if ($request->filled('section')) {
            $students = $students->where('section', (string) $request->query('section'));
        }

        $items = $students
            ->map(fn ($student) => $this->formatStudentSummary($student))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        if (! $this->allocations->canAccessStudent($teacherId, $id)) {
            return response()->json(['message' => 'Student not found or not in your classes.'], 404);
        }

        $student = DB::table('student_info')->where('id', $id)->first();
        if (! $student) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        $profile = $this->formatStudentProfile($student);
        $marks = $this->fetchMarks($teacherId, $id);
        $attendance = $this->fetchAttendance($id);
        $homework = $this->fetchHomework($teacherId, $student);

        return response()->json([
            'profile' => $profile,
            'marks' => $marks,
            'attendance' => $attendance,
            'homework' => $homework,
        ]);
    }

    private function formatStudentSummary(object $student): array
    {
        return [
            'id' => (string) $student->id,
            'name' => (string) ($student->name ?? ''),
            'standard' => isset($student->standard) ? (int) $student->standard : null,
            'section' => isset($student->section) ? (string) $student->section : null,
        ];
    }

    private function formatStudentProfile(object $student): array
    {
        $profile = $this->formatStudentSummary($student);

        foreach (['email', 'phone', 'father_name', 'mother_name', 'dob', 'gender', 'blood_group', 'address'] as $field) {
            if (isset($student->{$field})) {
                $profile[$field] = $student->{$field};
            }
        }

        return $profile;
    }

    private function fetchMarks(string $teacherId, string $studentId): array
    {
        if (! Schema::hasTable('marks')) {
            return [];
        }

        $student = DB::table('student_info')->where('id', $studentId)->first(['standard', 'section']);
        if (! $student) {
            return [];
        }

        $subjects = $this->allocations
            ->allocations($teacherId)
            ->filter(fn ($row) => (int) $row->standard === (int) $student->standard
                && (string) $row->section === (string) $student->section)
            ->map(fn ($row) => (string) ($row->subject_name ?? $row->subject ?? ''))
            ->filter()
            ->unique()
            ->values()
            ->all();

        if ($subjects === []) {
            return [];
        }

        $columns = ['id', 'subject_name', 'marks'];
        foreach (['term', 'exam_type', 'grade', 'max_marks'] as $column) {
            if (Schema::hasColumn('marks', $column)) {
                $columns[] = $column;
            }
        }

        return DB::table('marks')
            ->where('student_id', $studentId)
            ->whereIn('subject_name', $subjects)
            ->orderByDesc('id')
            ->get($columns)
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'subject_name' => (string) $row->subject_name,
                'marks' => $row->marks,
                'term' => $row->term ?? null,
                'exam_type' => $row->exam_type ?? null,
                'grade' => $row->grade ?? null,
                'max_marks' => $row->max_marks ?? null,
            ])
            ->values()
            ->all();
    }

    private function fetchAttendance(string $studentId): array
    {
        if (! Schema::hasTable('attendance')) {
            return [];
        }

        return DB::table('attendance')
            ->where('student_id', $studentId)
            ->orderByDesc('date')
            ->limit(30)
            ->get(['date', 'morning', 'afternoon', 'evening'])
            ->map(fn ($row) => [
                'date' => (string) $row->date,
                'morning' => $row->morning,
                'afternoon' => $row->afternoon,
                'evening' => $row->evening,
            ])
            ->values()
            ->all();
    }

    private function fetchHomework(string $teacherId, object $student): array
    {
        if (! Schema::hasTable('homeworks') || $student->standard === null || $student->section === null) {
            return [];
        }

        return DB::table('homeworks')
            ->where('standard', $student->standard)
            ->where('section', $student->section)
            ->where(function ($query) use ($student) {
                $query->where('target_type', 'class')
                    ->orWhere('student_id', $student->id)
                    ->orWhereNull('target_type');
            })
            ->orderByDesc('date')
            ->limit(20)
            ->get(['id', 'subject_name', 'teacher_id', 'date', 'title', 'description', 'target_type', 'student_id'])
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'subject_name' => (string) $row->subject_name,
                'teacher_id' => (string) $row->teacher_id,
                'date' => (string) $row->date,
                'title' => (string) $row->title,
                'description' => (string) ($row->description ?? ''),
                'target_type' => $row->target_type ?? 'class',
                'student_id' => $row->student_id,
                'is_mine' => (string) $row->teacher_id === $teacherId,
            ])
            ->values()
            ->all();
    }
}
