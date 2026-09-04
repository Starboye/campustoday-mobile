<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DataQualityController extends AdminController
{
    public function index(Request $request): JsonResponse
    {
        $table = $this->resolveTable();
        if ($table === null) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $query = DB::table($table);

        if ($status = $request->query('status')) {
            $statusCol = Schema::hasColumn($table, 'status') ? 'status' : 'issue_status';
            $query->where($statusCol, $status);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'entity_type' => $row->entity_type ?? $row->table_name ?? null,
                'entity_id' => $row->entity_id ?? null,
                'issue' => $row->issue ?? $row->description ?? $row->message ?? '',
                'status' => $row->status ?? $row->issue_status ?? 'open',
                'created_at' => $row->created_at ?? null,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $table = $this->resolveTable();
        if ($table === null) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        if (! DB::table($table)->where('id', $id)->exists()) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'status' => ['required', 'string', 'in:open,resolved,ignored'],
        ]);

        $statusCol = Schema::hasColumn($table, 'status') ? 'status' : 'issue_status';
        DB::table($table)->where('id', $id)->update([$statusCol => $data['status']]);

        return response()->json(['id' => $id, 'status' => $data['status']]);
    }

    private function resolveTable(): ?string
    {
        if (Schema::hasTable('data_quality_issues')) {
            return 'data_quality_issues';
        }
        if (Schema::hasTable('data_quality')) {
            return 'data_quality';
        }

        return null;
    }
}
