<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HomeworkController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $date = $request->query('date', now()->toDateString());

        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return response()->json(['message' => 'Invalid date format. Use YYYY-MM-DD.'], 422);
        }

        $student = StudentInfo::query()->find($auth['id']);
        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json([
                'date' => $date,
                'items' => [],
            ]);
        }

        $items = DB::table('homeworks as h')
            ->leftJoin('user_login as u', 'u.id', '=', 'h.teacher_id')
            ->where('h.standard', $student->standard)
            ->where('h.section', $student->section)
            ->where('h.date', $date)
            ->orderBy('h.subject_name')
            ->orderBy('h.id')
            ->get([
                'h.id',
                'h.subject_name',
                'h.teacher_id',
                'h.standard',
                'h.section',
                'h.date',
                'h.title',
                'h.description',
                'h.target_type',
                'h.student_id',
                'u.name as teacher_name',
            ])
            ->map(fn ($row) => [
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
            ])
            ->values();

        return response()->json([
            'date' => $date,
            'items' => $items,
        ]);
    }
}
