<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MarksController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['marks_new'])) {
            return $response;
        }

        $query = DB::table('marks_new as m')
            ->leftJoin('student_info as s', 's.id', '=', 'm.student_id')
            ->select([
                'm.id', 'm.student_id', 'm.subject_name', 'm.marks', 'm.grade',
                'm.term', 'm.exam_type', 's.name as student_name',
                's.standard', 's.section',
            ]);

        if ($studentId = $request->query('student_id')) {
            $query->where('m.student_id', $studentId);
        }
        if ($term = $request->query('term')) {
            $query->where('m.term', (int) $term);
        }
        if ($standard = $request->query('standard')) {
            $query->where('s.standard', (int) $standard);
        }

        $page = $this->cursor->paginate($query, $request, 'm.id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'student_id' => (string) $row->student_id,
                'student_name' => $row->student_name,
                'standard' => $row->standard !== null ? (int) $row->standard : null,
                'section' => $row->section,
                'subject_name' => $row->subject_name,
                'marks' => $row->marks,
                'grade' => $row->grade,
                'term' => $row->term !== null ? (int) $row->term : null,
                'exam_type' => $row->exam_type,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['marks_new'])) {
            return $response;
        }

        $data = $request->validate([
            'student_id' => ['required', 'string', 'max:20'],
            'subject_name' => ['required', 'string', 'max:100'],
            'marks' => ['required', 'numeric'],
            'grade' => ['nullable', 'string', 'max:10'],
            'term' => ['required', 'integer', 'min:1', 'max:3'],
            'exam_type' => ['nullable', 'string', 'max:50'],
        ]);

        $id = DB::table('marks_new')->insertGetId([
            'student_id' => $data['student_id'],
            'subject_name' => $data['subject_name'],
            'marks' => $data['marks'],
            'grade' => $data['grade'] ?? null,
            'term' => $data['term'],
            'exam_type' => $data['exam_type'] ?? null,
        ]);

        $row = DB::table('marks_new')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'student_id' => (string) $row->student_id,
            'subject_name' => $row->subject_name,
            'marks' => $row->marks,
            'grade' => $row->grade,
            'term' => $row->term !== null ? (int) $row->term : null,
            'exam_type' => $row->exam_type,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['marks_new'])) {
            return $response;
        }

        $exists = DB::table('marks_new')->where('id', $id)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'marks' => ['sometimes', 'numeric'],
            'grade' => ['sometimes', 'nullable', 'string', 'max:10'],
            'subject_name' => ['sometimes', 'string', 'max:100'],
            'term' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'exam_type' => ['sometimes', 'nullable', 'string', 'max:50'],
        ]);

        $update = array_filter($data, fn ($v) => $v !== null);
        if ($update !== []) {
            DB::table('marks_new')->where('id', $id)->update($update);
        }

        $row = DB::table('marks_new')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'student_id' => (string) $row->student_id,
            'subject_name' => $row->subject_name,
            'marks' => $row->marks,
            'grade' => $row->grade,
            'term' => $row->term !== null ? (int) $row->term : null,
            'exam_type' => $row->exam_type,
        ]);
    }
}
