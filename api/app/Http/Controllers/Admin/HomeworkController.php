<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HomeworkController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['homeworks'])) {
            return $response;
        }

        $query = DB::table('homeworks as h')
            ->leftJoin('user_login as u', 'u.id', '=', 'h.teacher_id')
            ->select([
                'h.id', 'h.subject_name', 'h.teacher_id', 'h.standard', 'h.section',
                'h.date', 'h.title', 'h.description', 'h.target_type', 'h.student_id',
                'u.name as teacher_name',
            ]);

        if ($date = $request->query('date')) {
            $query->where('h.date', $date);
        }
        if ($standard = $request->query('standard')) {
            $query->where('h.standard', (int) $standard);
        }
        if ($section = $request->query('section')) {
            $query->where('h.section', $section);
        }

        $page = $this->cursor->paginate($query, $request, 'h.id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'subject_name' => $row->subject_name,
                'teacher_id' => (string) $row->teacher_id,
                'teacher_name' => $row->teacher_name,
                'standard' => (int) $row->standard,
                'section' => (string) $row->section,
                'date' => (string) $row->date,
                'title' => $row->title,
                'description' => $row->description,
                'target_type' => $row->target_type,
                'student_id' => $row->student_id,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['homeworks'])) {
            return $response;
        }

        $deleted = DB::table('homeworks')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }
}
