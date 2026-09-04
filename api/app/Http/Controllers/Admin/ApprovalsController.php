<?php

namespace App\Http\Controllers\Admin;

use App\Services\Admin\ApprovalService;
use App\Services\Admin\CursorPaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApprovalsController extends AdminController
{
    public function __construct(
        CursorPaginator $cursor,
        private readonly ApprovalService $approvals,
    ) {
        parent::__construct($cursor);
    }

    public function index(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['approval_requests'])) {
            return $response;
        }

        $query = DB::table('approval_requests');

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }
        if ($type = $request->query('type')) {
            $query->where('request_type', $type);
        }

        $page = $this->cursor->paginate($query, $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'request_type' => $row->request_type ?? $row->type ?? null,
                'entity_id' => $row->entity_id ?? null,
                'status' => $row->status,
                'requested_by' => $row->requested_by ?? null,
                'notes' => $row->notes ?? null,
                'created_at' => $row->created_at ?? null,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function approve(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['approval_requests'])) {
            return $response;
        }

        $auth = $request->attributes->get('auth_user');
        $result = $this->approvals->approve($id, (string) $auth['id']);

        if ($result === null) {
            return response()->json(['message' => 'Not found or already processed.'], 404);
        }

        return response()->json($result);
    }

    public function reject(Request $request, int $id): JsonResponse
    {
        if ($response = $this->requireTables(['approval_requests'])) {
            return $response;
        }

        $data = $request->validate([
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $result = $this->approvals->reject($id, (string) $auth['id'], $data['notes'] ?? null);

        if ($result === null) {
            return response()->json(['message' => 'Not found or already processed.'], 404);
        }

        return response()->json($result);
    }
}
