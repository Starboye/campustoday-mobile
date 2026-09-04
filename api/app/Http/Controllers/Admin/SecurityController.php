<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SecurityController extends AdminController
{
    public function loginAudit(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['login_audit'])) {
            return $response;
        }

        $query = DB::table('login_audit');

        if ($userId = $request->query('user_id')) {
            $query->where('user_id', $userId);
        }
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $orderCol = Schema::hasColumn('login_audit', 'id') ? 'id' : 'created_at';
        $page = $this->cursor->paginate($query, $request, $orderCol);

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => $row->id ?? null,
                'user_id' => $row->user_id,
                'username' => $row->username ?? null,
                'status' => $row->status,
                'ip_address' => $row->ip_address ?? null,
                'user_agent' => $row->user_agent ?? null,
                'created_at' => $row->created_at ?? null,
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function updateUser(Request $request, string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_security'])) {
            return $response;
        }

        $data = $request->validate([
            'locked_until' => ['sometimes', 'nullable', 'date'],
            'force_password_reset' => ['sometimes', 'boolean'],
        ]);

        $exists = DB::table('user_security')->where('user_id', $id)->exists();

        $update = [];
        if (array_key_exists('locked_until', $data)) {
            $update['locked_until'] = $data['locked_until'];
        }
        if (array_key_exists('force_password_reset', $data)) {
            $update['force_password_reset'] = $data['force_password_reset'] ? 1 : 0;
        }

        if ($exists) {
            if ($update !== []) {
                DB::table('user_security')->where('user_id', $id)->update($update);
            }
        } else {
            DB::table('user_security')->insert([
                'user_id' => $id,
                'locked_until' => $data['locked_until'] ?? null,
                'force_password_reset' => ($data['force_password_reset'] ?? false) ? 1 : 0,
            ]);
        }

        $row = DB::table('user_security')->where('user_id', $id)->first();

        return response()->json([
            'user_id' => (string) $id,
            'locked_until' => $row->locked_until ?? null,
            'force_password_reset' => (bool) ($row->force_password_reset ?? false),
        ]);
    }
}
