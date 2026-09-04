<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class RbacController extends AdminController
{
    public function listRoles(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['roles'])) {
            return $response;
        }

        $page = $this->cursor->paginate(DB::table('roles'), $request, 'id');

        $items = $page['items']->map(function ($role) {
            $permissions = [];
            if (Schema::hasTable('role_permissions')) {
                $permissions = DB::table('role_permissions')
                    ->where('role_id', $role->id)
                    ->pluck('permission_key')
                    ->values()
                    ->all();
            }

            return [
                'id' => (int) $role->id,
                'name' => $role->name ?? $role->role_name ?? '',
                'permissions' => $permissions,
            ];
        });

        return response()->json([
            'items' => $items->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function showUser(string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_roles', 'roles'])) {
            return $response;
        }

        $roleIds = DB::table('user_roles')
            ->where('user_id', $id)
            ->pluck('role_id')
            ->values()
            ->all();

        return response()->json([
            'user_id' => $id,
            'role_ids' => array_map('intval', $roleIds),
        ]);
    }

    public function updateUserRoles(Request $request, string $id): JsonResponse
    {
        if ($response = $this->requireTables(['user_roles', 'roles'])) {
            return $response;
        }

        $data = $request->validate([
            'role_ids' => ['required', 'array'],
            'role_ids.*' => ['integer'],
        ]);

        DB::transaction(function () use ($id, $data) {
            DB::table('user_roles')->where('user_id', $id)->delete();
            foreach ($data['role_ids'] as $roleId) {
                DB::table('user_roles')->insert([
                    'user_id' => $id,
                    'role_id' => $roleId,
                ]);
            }
        });

        $roleIds = DB::table('user_roles')
            ->where('user_id', $id)
            ->pluck('role_id')
            ->values()
            ->all();

        return response()->json([
            'user_id' => $id,
            'role_ids' => array_map('intval', $roleIds),
        ]);
    }
}
