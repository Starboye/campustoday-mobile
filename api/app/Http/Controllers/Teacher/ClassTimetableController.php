<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ClassTimetableController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $classTeacher = $this->allocations->classTeacherOf($teacherId);
        if ($classTeacher === null) {
            return response()->json(['message' => 'Class teacher access required.'], 403);
        }

        if (! Schema::hasTable('class_timetables')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $timetable = $this->findTimetable($classTeacher['standard'], $classTeacher['section']);
        if (! $timetable) {
            return response()->json([
                'status' => 'draft',
                'standard' => $classTeacher['standard'],
                'section' => $classTeacher['section'],
                'items' => [],
            ]);
        }

        return response()->json([
            'status' => (string) ($timetable->status ?? 'draft'),
            'timetable_id' => (int) $timetable->id,
            'standard' => (int) $timetable->standard,
            'section' => (string) $timetable->section,
            'items' => $this->fetchItems((int) $timetable->id),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $classTeacher = $this->allocations->classTeacherOf($teacherId);
        if ($classTeacher === null) {
            return response()->json(['message' => 'Class teacher access required.'], 403);
        }

        if (! Schema::hasTable('class_timetables')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $data = $request->validate([
            'items' => ['required', 'array'],
            'items.*.slot_id' => ['required', 'integer'],
            'items.*.subject_name' => ['required', 'string'],
            'items.*.teacher_id' => ['nullable', 'string'],
        ]);

        $timetable = $this->findTimetable($classTeacher['standard'], $classTeacher['section']);
        if (! $timetable) {
            $timetableId = DB::table('class_timetables')->insertGetId([
                'standard' => $classTeacher['standard'],
                'section' => $classTeacher['section'],
                'status' => 'draft',
            ]);
            $timetable = DB::table('class_timetables')->where('id', $timetableId)->first();
        }

        if (($timetable->status ?? '') === 'approved') {
            return response()->json(['message' => 'Timetable is approved and locked.'], 409);
        }

        if (! Schema::hasTable('assignments')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Assignments table not available.'], 501);
        }

        foreach ($data['items'] as $item) {
            $payload = [
                'subject_name' => $item['subject_name'],
                'teacher_id' => $item['teacher_id'] ?? $teacherId,
            ];

            $existing = DB::table('assignments')
                ->where('timetable_id', $timetable->id)
                ->where('slot_id', $item['slot_id'])
                ->first();

            if ($existing) {
                DB::table('assignments')
                    ->where('id', $existing->id)
                    ->update($payload);
            } else {
                DB::table('assignments')->insert(array_merge($payload, [
                    'timetable_id' => $timetable->id,
                    'slot_id' => $item['slot_id'],
                ]));
            }
        }

        if (($timetable->status ?? '') !== 'draft' && ($timetable->status ?? '') !== 'pending') {
            DB::table('class_timetables')->where('id', $timetable->id)->update(['status' => 'draft']);
        }

        return response()->json([
            'message' => 'Timetable updated.',
            'status' => 'draft',
            'timetable_id' => (int) $timetable->id,
            'items' => $this->fetchItems((int) $timetable->id),
        ]);
    }

    public function submit(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $classTeacher = $this->allocations->classTeacherOf($teacherId);
        if ($classTeacher === null) {
            return response()->json(['message' => 'Class teacher access required.'], 403);
        }

        if (! Schema::hasTable('class_timetables')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $timetable = $this->findTimetable($classTeacher['standard'], $classTeacher['section']);
        if (! $timetable) {
            return response()->json(['message' => 'No timetable to submit. Create a draft first.'], 422);
        }

        if (($timetable->status ?? '') === 'approved') {
            return response()->json(['message' => 'Timetable is already approved.'], 409);
        }

        DB::table('class_timetables')
            ->where('id', $timetable->id)
            ->update(['status' => 'pending']);

        return response()->json([
            'message' => 'Timetable submitted for approval.',
            'status' => 'pending',
            'timetable_id' => (int) $timetable->id,
        ]);
    }

    private function findTimetable(int $standard, string $section): ?object
    {
        return DB::table('class_timetables')
            ->where('standard', $standard)
            ->where('section', $section)
            ->orderByDesc('id')
            ->first();
    }

    private function fetchItems(int $timetableId): array
    {
        if (! Schema::hasTable('assignments') || ! Schema::hasTable('slots')) {
            return [];
        }

        return DB::table('assignments as a')
            ->join('slots as s', 's.id', '=', 'a.slot_id')
            ->where('a.timetable_id', $timetableId)
            ->orderBy('s.day')
            ->orderBy('s.period')
            ->get([
                'a.id as assignment_id',
                'a.slot_id',
                'a.subject_name',
                'a.teacher_id',
                's.day',
                's.period',
                's.start_time',
                's.end_time',
            ])
            ->map(fn ($row) => [
                'assignment_id' => (int) $row->assignment_id,
                'slot_id' => (int) $row->slot_id,
                'day' => $row->day,
                'period' => (int) $row->period,
                'start_time' => $row->start_time,
                'end_time' => $row->end_time,
                'subject_name' => $row->subject_name,
                'teacher_id' => (string) $row->teacher_id,
            ])
            ->values()
            ->all();
    }
}
