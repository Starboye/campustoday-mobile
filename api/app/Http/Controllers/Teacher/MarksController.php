<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MarksController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('marks')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Marks not available.'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $standard = $request->query('class') !== null ? (int) $request->query('class') : null;
        $section = $request->query('section');
        $subjectName = $request->query('subject_name');
        $term = $request->query('term');

        if ($standard !== null && $section !== null
            && ! $this->allocations->isAllocatedToClass($teacherId, $standard, (string) $section)) {
            return response()->json(['message' => 'Not allocated to this class.'], 403);
        }

        $allocatedSubjects = $this->allocations
            ->allocations($teacherId)
            ->map(fn ($row) => [
                'standard' => (int) $row->standard,
                'section' => (string) $row->section,
                'subject_name' => (string) ($row->subject_name ?? $row->subject ?? ''),
            ]);

        $query = DB::table('marks as m')
            ->join('student_info as s', 's.id', '=', 'm.student_id');

        $query->where(function ($q) use ($allocatedSubjects) {
            foreach ($allocatedSubjects as $allocation) {
                $q->orWhere(function ($inner) use ($allocation) {
                    $inner->where('s.standard', $allocation['standard'])
                        ->where('s.section', $allocation['section'])
                        ->where('m.subject_name', $allocation['subject_name']);
                });
            }
        });

        if ($standard !== null) {
            $query->where('s.standard', $standard);
        }

        if ($section !== null) {
            $query->where('s.section', $section);
        }

        if ($subjectName !== null) {
            if (! $this->allocations->isAllocatedToSubject($teacherId, (int) ($standard ?? 0), (string) ($section ?? ''), (string) $subjectName)) {
                $classSections = $this->allocations->distinctClassSections($teacherId);
                $allowed = false;
                foreach ($classSections as $classSection) {
                    if ($this->allocations->isAllocatedToSubject(
                        $teacherId,
                        $classSection['standard'],
                        $classSection['section'],
                        (string) $subjectName,
                    )) {
                        $allowed = true;
                        break;
                    }
                }
                if (! $allowed) {
                    return response()->json(['message' => 'Not allocated to this subject.'], 403);
                }
            }
            $query->where('m.subject_name', $subjectName);
        }

        if ($term !== null) {
            $query->where('m.term', (int) $term);
        }

        $columns = ['m.id', 'm.student_id', 's.name as student_name', 's.standard', 's.section', 'm.subject_name', 'm.marks'];
        foreach (['term', 'exam_type', 'grade', 'max_marks'] as $column) {
            if (Schema::hasColumn('marks', $column)) {
                $columns[] = 'm.'.$column;
            }
        }

        $items = $query
            ->orderBy('s.standard')
            ->orderBy('s.section')
            ->orderBy('s.name')
            ->orderBy('m.subject_name')
            ->get($columns)
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'student_id' => (string) $row->student_id,
                'student_name' => (string) ($row->student_name ?? ''),
                'standard' => (int) $row->standard,
                'section' => (string) $row->section,
                'subject_name' => (string) $row->subject_name,
                'marks' => $row->marks,
                'term' => isset($row->term) ? (int) $row->term : null,
                'exam_type' => $row->exam_type ?? null,
                'grade' => $row->grade ?? null,
                'max_marks' => $row->max_marks ?? null,
            ])
            ->values();

        return response()->json(['items' => $items]);
    }

    public function update(Request $request): JsonResponse
    {
        if (! Schema::hasTable('marks')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Marks not available.'], 501);
        }

        $data = $request->validate([
            'student_id' => ['required', 'string'],
            'subject_name' => ['required', 'string'],
            'marks' => ['required'],
            'term' => ['nullable', 'integer'],
            'exam_type' => ['nullable', 'string'],
            'grade' => ['nullable', 'string'],
            'max_marks' => ['nullable'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $student = DB::table('student_info')
            ->where('id', $data['student_id'])
            ->first(['standard', 'section']);

        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        if (! $this->allocations->isAllocatedToSubject(
            $teacherId,
            (int) $student->standard,
            (string) $student->section,
            $data['subject_name'],
        )) {
            return response()->json(['message' => 'Not allocated to this student/subject.'], 403);
        }

        $match = [
            'student_id' => $data['student_id'],
            'subject_name' => $data['subject_name'],
        ];

        if (isset($data['term']) && Schema::hasColumn('marks', 'term')) {
            $match['term'] = (int) $data['term'];
        }

        if (isset($data['exam_type']) && Schema::hasColumn('marks', 'exam_type')) {
            $match['exam_type'] = $data['exam_type'];
        }

        $payload = ['marks' => $data['marks']];
        foreach (['grade', 'max_marks', 'term', 'exam_type'] as $column) {
            if (array_key_exists($column, $data) && $data[$column] !== null && Schema::hasColumn('marks', $column)) {
                $payload[$column] = $data[$column];
            }
        }

        $existing = DB::table('marks')->where($match)->first();

        if ($existing) {
            DB::table('marks')->where('id', $existing->id)->update($payload);
            $id = (int) $existing->id;
        } else {
            $insert = array_merge($match, $payload);
            $id = (int) DB::table('marks')->insertGetId($insert);
        }

        $row = DB::table('marks')->where('id', $id)->first();

        return response()->json([
            'message' => 'Marks saved.',
            'id' => $id,
            'student_id' => (string) $row->student_id,
            'subject_name' => (string) $row->subject_name,
            'marks' => $row->marks,
            'term' => $row->term ?? null,
            'exam_type' => $row->exam_type ?? null,
            'grade' => $row->grade ?? null,
            'max_marks' => $row->max_marks ?? null,
        ]);
    }
}
