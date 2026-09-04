<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlannerController extends AdminController
{
    public function listAssignments(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['assignments'])) {
            return $response;
        }

        $query = DB::table('assignments');
        if ($timetableId = $request->query('timetable_id')) {
            $query->where('timetable_id', (int) $timetableId);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'timetable_id' => (int) $row->timetable_id,
                'slot_id' => (int) $row->slot_id,
                'subject_name' => $row->subject_name,
                'teacher_id' => (string) $row->teacher_id,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeAssignment(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['assignments'])) {
            return $response;
        }

        $data = $request->validate([
            'timetable_id' => ['required', 'integer'],
            'slot_id' => ['required', 'integer'],
            'subject_name' => ['required', 'string', 'max:100'],
            'teacher_id' => ['required', 'string', 'max:20'],
        ]);

        $id = DB::table('assignments')->insertGetId($data);

        return response()->json(['id' => $id, ...$data], 201);
    }

    public function updateAssignment(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['assignments'])) {
            return $response;
        }

        if (! DB::table('assignments')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'subject_name' => ['sometimes', 'string', 'max:100'],
            'teacher_id' => ['sometimes', 'string', 'max:20'],
            'slot_id' => ['sometimes', 'integer'],
        ]);

        if ($data !== []) {
            DB::table('assignments')->where('id', $id)->update($data);
        }

        $row = DB::table('assignments')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'timetable_id' => (int) $row->timetable_id,
            'slot_id' => (int) $row->slot_id,
            'subject_name' => $row->subject_name,
            'teacher_id' => (string) $row->teacher_id,
        ]);
    }

    public function destroyAssignment(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['assignments'])) {
            return $response;
        }

        $deleted = DB::table('assignments')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }

    public function listSlots(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['slots'])) {
            return $response;
        }

        $page = $this->cursor->paginate(DB::table('slots'), $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'day' => $row->day,
                'period' => (int) $row->period,
                'start_time' => $row->start_time,
                'end_time' => $row->end_time,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeSlot(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['slots'])) {
            return $response;
        }

        $data = $request->validate([
            'day' => ['required', 'string', 'max:20'],
            'period' => ['required', 'integer', 'min:1'],
            'start_time' => ['required', 'string', 'max:10'],
            'end_time' => ['required', 'string', 'max:10'],
        ]);

        $id = DB::table('slots')->insertGetId($data);

        return response()->json(['id' => $id, ...$data], 201);
    }

    public function updateSlot(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['slots'])) {
            return $response;
        }

        if (! DB::table('slots')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'day' => ['sometimes', 'string', 'max:20'],
            'period' => ['sometimes', 'integer', 'min:1'],
            'start_time' => ['sometimes', 'string', 'max:10'],
            'end_time' => ['sometimes', 'string', 'max:10'],
        ]);

        if ($data !== []) {
            DB::table('slots')->where('id', $id)->update($data);
        }

        $row = DB::table('slots')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'day' => $row->day,
            'period' => (int) $row->period,
            'start_time' => $row->start_time,
            'end_time' => $row->end_time,
        ]);
    }

    public function destroySlot(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['slots'])) {
            return $response;
        }

        $deleted = DB::table('slots')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }

    public function listTimetables(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['class_timetables'])) {
            return $response;
        }

        $query = DB::table('class_timetables');
        if ($standard = $request->query('standard')) {
            $query->where('standard', (int) $standard);
        }
        if ($section = $request->query('section')) {
            $query->where('section', $section);
        }
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'standard' => (int) $row->standard,
                'section' => (string) $row->section,
                'status' => $row->status ?? 'pending',
                'created_at' => $row->created_at ?? null,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeTimetable(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['class_timetables'])) {
            return $response;
        }

        $data = $request->validate([
            'standard' => ['required', 'integer', 'min:1'],
            'section' => ['required', 'string', 'max:10'],
        ]);

        $id = DB::table('class_timetables')->insertGetId([
            'standard' => $data['standard'],
            'section' => $data['section'],
            'status' => 'pending',
            'created_at' => now(),
        ]);

        return response()->json([
            'id' => $id,
            'standard' => $data['standard'],
            'section' => $data['section'],
            'status' => 'pending',
        ], 201);
    }

    public function approveTimetable(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['class_timetables'])) {
            return $response;
        }

        $updated = DB::table('class_timetables')
            ->where('id', $id)
            ->update(['status' => 'approved']);

        if ($updated === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['id' => $id, 'status' => 'approved']);
    }
}
