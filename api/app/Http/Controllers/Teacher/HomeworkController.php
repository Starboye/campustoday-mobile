<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HomeworkController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('homeworks')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];
        $date = $request->query('date');

        $query = DB::table('homeworks')->where('teacher_id', $teacherId);

        if ($date !== null) {
            if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $date)) {
                return response()->json(['message' => 'Invalid date format. Use YYYY-MM-DD.'], 422);
            }
            $query->where('date', $date);
        }

        if ($request->filled('class')) {
            $query->where('standard', (int) $request->query('class'));
        }

        if ($request->filled('section')) {
            $query->where('section', (string) $request->query('section'));
        }

        $items = $query
            ->orderByDesc('date')
            ->orderBy('subject_name')
            ->orderBy('id')
            ->get()
            ->map(fn ($row) => $this->formatHomework($row))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function store(Request $request): JsonResponse
    {
        if (! Schema::hasTable('homeworks')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $data = $request->validate([
            'standard' => ['required', 'integer'],
            'section' => ['required', 'string'],
            'subject_name' => ['required', 'string'],
            'date' => ['required', 'date_format:Y-m-d'],
            'title' => ['required', 'string'],
            'description' => ['nullable', 'string'],
            'target_type' => ['nullable', 'in:class,student'],
            'student_id' => ['nullable', 'string'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        if (! $this->allocations->isAllocatedToSubject(
            $teacherId,
            (int) $data['standard'],
            (string) $data['section'],
            $data['subject_name'],
        )) {
            return response()->json(['message' => 'Not allocated to this class/subject.'], 403);
        }

        $targetType = $data['target_type'] ?? 'class';
        $studentId = $data['student_id'] ?? null;

        if ($targetType === 'student') {
            if ($studentId === null) {
                return response()->json(['message' => 'student_id is required for student target.'], 422);
            }
            if (! $this->allocations->canAccessStudent($teacherId, $studentId)) {
                return response()->json(['message' => 'Not allocated to this student.'], 403);
            }
        } else {
            $studentId = null;
        }

        $id = DB::table('homeworks')->insertGetId([
            'teacher_id' => $teacherId,
            'standard' => (int) $data['standard'],
            'section' => (string) $data['section'],
            'subject_name' => $data['subject_name'],
            'date' => $data['date'],
            'title' => $data['title'],
            'description' => $data['description'] ?? '',
            'target_type' => $targetType,
            'student_id' => $studentId,
        ]);

        $row = DB::table('homeworks')->where('id', $id)->first();

        return response()->json($this->formatHomework($row), 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        if (! Schema::hasTable('homeworks')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $existing = DB::table('homeworks')->where('id', $id)->first();
        if (! $existing) {
            return response()->json(['message' => 'Homework not found.'], 404);
        }

        if ((string) $existing->teacher_id !== $teacherId) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $data = $request->validate([
            'standard' => ['sometimes', 'integer'],
            'section' => ['sometimes', 'string'],
            'subject_name' => ['sometimes', 'string'],
            'date' => ['sometimes', 'date_format:Y-m-d'],
            'title' => ['sometimes', 'string'],
            'description' => ['nullable', 'string'],
            'target_type' => ['nullable', 'in:class,student'],
            'student_id' => ['nullable', 'string'],
        ]);

        $standard = (int) ($data['standard'] ?? $existing->standard);
        $section = (string) ($data['section'] ?? $existing->section);
        $subjectName = (string) ($data['subject_name'] ?? $existing->subject_name);

        if (! $this->allocations->isAllocatedToSubject($teacherId, $standard, $section, $subjectName)) {
            return response()->json(['message' => 'Not allocated to this class/subject.'], 403);
        }

        $update = array_filter([
            'standard' => $data['standard'] ?? null,
            'section' => $data['section'] ?? null,
            'subject_name' => $data['subject_name'] ?? null,
            'date' => $data['date'] ?? null,
            'title' => $data['title'] ?? null,
            'description' => array_key_exists('description', $data) ? ($data['description'] ?? '') : null,
            'target_type' => $data['target_type'] ?? null,
            'student_id' => array_key_exists('student_id', $data) ? $data['student_id'] : null,
        ], fn ($value) => $value !== null);

        if ($update !== []) {
            DB::table('homeworks')->where('id', $id)->update($update);
        }

        $row = DB::table('homeworks')->where('id', $id)->first();

        return response()->json($this->formatHomework($row));
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        if (! Schema::hasTable('homeworks')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $existing = DB::table('homeworks')->where('id', $id)->first();
        if (! $existing) {
            return response()->json(['message' => 'Homework not found.'], 404);
        }

        if ((string) $existing->teacher_id !== $teacherId) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        DB::table('homeworks')->where('id', $id)->delete();

        return response()->json(['message' => 'Homework deleted.', 'id' => $id]);
    }

    private function formatHomework(object $row): array
    {
        return [
            'id' => (int) $row->id,
            'teacher_id' => (string) $row->teacher_id,
            'standard' => (int) $row->standard,
            'section' => (string) $row->section,
            'subject_name' => (string) $row->subject_name,
            'date' => (string) $row->date,
            'title' => (string) $row->title,
            'description' => (string) ($row->description ?? ''),
            'target_type' => $row->target_type ?? 'class',
            'student_id' => $row->student_id,
        ];
    }
}
