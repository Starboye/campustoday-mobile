<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceLockController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['attendance_day_lock'])) {
            return $response;
        }

        $query = DB::table('attendance_day_lock');

        if ($date = $request->query('date')) {
            $query->where('date', $date);
        }
        if ($standard = $request->query('standard')) {
            $query->where('standard', (int) $standard);
        }
        if ($section = $request->query('section')) {
            $query->where('section', $section);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'date' => (string) $row->date,
                'standard' => isset($row->standard) ? (int) $row->standard : null,
                'section' => $row->section ?? null,
                'locked_by' => $row->locked_by ?? null,
                'locked_at' => $row->locked_at ?? $row->created_at ?? null,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['attendance_day_lock'])) {
            return $response;
        }

        $auth = $request->attributes->get('auth_user');
        $data = $request->validate([
            'date' => ['required', 'date'],
            'standard' => ['required', 'integer', 'min:1'],
            'section' => ['required', 'string', 'max:10'],
        ]);

        $exists = DB::table('attendance_day_lock')
            ->where('date', $data['date'])
            ->where('standard', $data['standard'])
            ->where('section', $data['section'])
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'Lock already exists for this class and date.'], 422);
        }

        $id = DB::table('attendance_day_lock')->insertGetId([
            'date' => $data['date'],
            'standard' => $data['standard'],
            'section' => $data['section'],
            'locked_by' => $auth['id'],
            'locked_at' => now(),
        ]);

        return response()->json([
            'id' => $id,
            'date' => $data['date'],
            'standard' => $data['standard'],
            'section' => $data['section'],
            'locked_by' => $auth['id'],
        ], 201);
    }

    public function destroy(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['attendance_day_lock'])) {
            return $response;
        }

        $deleted = DB::table('attendance_day_lock')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Lock removed.', 'id' => $id]);
    }
}
