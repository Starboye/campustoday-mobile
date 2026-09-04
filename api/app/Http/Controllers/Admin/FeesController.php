<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeesController extends AdminController
{
    public function listStructures(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['fee_structures'])) {
            return $response;
        }

        $page = $this->cursor->paginate(DB::table('fee_structures'), $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => $this->formatStructure($row))->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeStructure(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['fee_structures'])) {
            return $response;
        }

        $data = $request->validate([
            'term' => ['required', 'string', 'max:50'],
            'amount' => ['required', 'numeric', 'min:0'],
            'description' => ['nullable', 'string', 'max:255'],
        ]);

        $insert = ['term' => $data['term']];
        if (Schema::hasColumn('fee_structures', 'amount')) {
            $insert['amount'] = $data['amount'];
        } else {
            $insert['total_amount'] = $data['amount'];
        }
        if (isset($data['description'])) {
            $col = Schema::hasColumn('fee_structures', 'description') ? 'description' : 'name';
            $insert[$col] = $data['description'];
        }

        $id = DB::table('fee_structures')->insertGetId($insert);
        $row = DB::table('fee_structures')->where('id', $id)->first();

        return response()->json($this->formatStructure($row), 201);
    }

    public function updateStructure(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['fee_structures'])) {
            return $response;
        }

        $row = DB::table('fee_structures')->where('id', $id)->first();
        if (! $row) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'term' => ['sometimes', 'string', 'max:50'],
            'amount' => ['sometimes', 'numeric', 'min:0'],
            'description' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $update = [];
        if (isset($data['term'])) {
            $update['term'] = $data['term'];
        }
        if (isset($data['amount'])) {
            $col = Schema::hasColumn('fee_structures', 'amount') ? 'amount' : 'total_amount';
            $update[$col] = $data['amount'];
        }
        if (array_key_exists('description', $data)) {
            $col = Schema::hasColumn('fee_structures', 'description') ? 'description' : 'name';
            $update[$col] = $data['description'];
        }

        if ($update !== []) {
            DB::table('fee_structures')->where('id', $id)->update($update);
        }

        return response()->json($this->formatStructure(DB::table('fee_structures')->where('id', $id)->first()));
    }

    public function destroyStructure(int $id): JsonResponse
    {
        if ($response = $this->requireTables(['fee_structures'])) {
            return $response;
        }

        $deleted = DB::table('fee_structures')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        return response()->json(['message' => 'Deleted.', 'id' => $id]);
    }

    public function listStatus(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['student_fee_status'])) {
            return $response;
        }

        $query = DB::table('student_fee_status as fs')
            ->leftJoin('student_info as s', 's.id', '=', 'fs.student_id')
            ->select(['fs.*', 's.name as student_name', 's.standard', 's.section']);

        if ($studentId = $request->query('student_id')) {
            $query->where('fs.student_id', $studentId);
        }
        if ($term = $request->query('term')) {
            $query->where('fs.term', $term);
        }

        $page = $this->cursor->paginate($query, $request, 'fs.id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'student_id' => (string) $row->student_id,
                'student_name' => $row->student_name,
                'standard' => $row->standard !== null ? (int) $row->standard : null,
                'section' => $row->section,
                'term' => $row->term ?? null,
                'fee_structure_id' => $row->fee_structure_id ?? null,
                'status' => $row->status ?? $row->payment_status ?? 'unpaid',
                'amount_paid' => $row->amount_paid ?? $row->paid_amount ?? 0,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function updateStatus(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['student_fee_status'])) {
            return $response;
        }

        $exists = DB::table('student_fee_status')->where('id', $id)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'status' => ['sometimes', 'string', 'max:50'],
            'amount_paid' => ['sometimes', 'numeric', 'min:0'],
        ]);

        $update = [];
        if (isset($data['status'])) {
            $col = Schema::hasColumn('student_fee_status', 'status') ? 'status' : 'payment_status';
            $update[$col] = $data['status'];
        }
        if (isset($data['amount_paid'])) {
            $col = Schema::hasColumn('student_fee_status', 'amount_paid') ? 'amount_paid' : 'paid_amount';
            $update[$col] = $data['amount_paid'];
        }

        if ($update !== []) {
            DB::table('student_fee_status')->where('id', $id)->update($update);
        }

        $row = DB::table('student_fee_status')->where('id', $id)->first();

        return response()->json([
            'id' => (int) $row->id,
            'student_id' => (string) $row->student_id,
            'status' => $row->status ?? $row->payment_status ?? 'unpaid',
            'amount_paid' => $row->amount_paid ?? $row->paid_amount ?? 0,
        ]);
    }

    private function formatStructure(object $row): array
    {
        return [
            'id' => (int) $row->id,
            'term' => $row->term ?? null,
            'amount' => $row->amount ?? $row->total_amount ?? 0,
            'description' => $row->description ?? $row->name ?? null,
        ];
    }
}
