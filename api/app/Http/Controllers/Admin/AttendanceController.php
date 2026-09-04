<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['attendance'])) {
            return $response;
        }

        $query = DB::table('attendance as a')
            ->leftJoin('student_info as s', 's.id', '=', 'a.student_id')
            ->select([
                'a.id', 'a.student_id', 'a.date',
                'a.morning', 'a.afternoon', 'a.evening',
                's.name as student_name', 's.standard', 's.section',
            ]);

        if ($date = $request->query('date')) {
            $query->where('a.date', $date);
        }
        if ($studentId = $request->query('student_id')) {
            $query->where('a.student_id', $studentId);
        }
        if ($standard = $request->query('standard')) {
            $query->where('s.standard', (int) $standard);
        }
        if ($section = $request->query('section')) {
            $query->where('s.section', $section);
        }

        $page = $this->cursor->paginate($query, $request, 'a.id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'student_id' => (string) $row->student_id,
                'student_name' => $row->student_name,
                'standard' => $row->standard !== null ? (int) $row->standard : null,
                'section' => $row->section,
                'date' => (string) $row->date,
                'morning' => $row->morning,
                'afternoon' => $row->afternoon,
                'evening' => $row->evening,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['attendance'])) {
            return $response;
        }

        $deleted = DB::table('attendance')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }
}
