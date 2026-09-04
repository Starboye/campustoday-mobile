<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExamsController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['exam_windows'])) {
            return $response;
        }

        $query = DB::table('exam_windows');
        if ($term = $request->query('term')) {
            $query->where('term', (int) $term);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'name' => $row->name ?? $row->exam_type ?? '',
                'term' => $row->term !== null ? (int) $row->term : null,
                'start_date' => $row->start_date ?? null,
                'end_date' => $row->end_date ?? null,
                'is_open' => (bool) ($row->is_open ?? $row->open ?? false),
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['exam_windows'])) {
            return $response;
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'term' => ['required', 'integer', 'min:1', 'max:3'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'is_open' => ['nullable', 'boolean'],
        ]);

        $id = DB::table('exam_windows')->insertGetId([
            'name' => $data['name'],
            'term' => $data['term'],
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'is_open' => $data['is_open'] ?? false,
        ]);

        return response()->json(['id' => $id, ...$data], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['exam_windows'])) {
            return $response;
        }

        if (! DB::table('exam_windows')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'term' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'start_date' => ['sometimes', 'date'],
            'end_date' => ['sometimes', 'date'],
            'is_open' => ['sometimes', 'boolean'],
        ]);

        if ($data !== []) {
            DB::table('exam_windows')->where('id', $id)->update($data);
        }

        $row = DB::table('exam_windows')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'name' => $row->name ?? $row->exam_type ?? '',
            'term' => $row->term !== null ? (int) $row->term : null,
            'start_date' => $row->start_date,
            'end_date' => $row->end_date,
            'is_open' => (bool) ($row->is_open ?? $row->open ?? false),
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['exam_windows'])) {
            return $response;
        }

        $deleted = DB::table('exam_windows')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }
}
