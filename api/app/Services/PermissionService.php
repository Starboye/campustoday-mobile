<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PermissionService
{
    /** @return list<string> */
    public function forUser(string $userId, int $access): array
    {
        if ($access !== 2) {
            return [];
        }

        if (! Schema::hasTable('user_roles') || ! Schema::hasTable('role_permissions')) {
            return $this->allPermissionKeys();
        }

        $perms = DB::table('user_roles as ur')
            ->join('role_permissions as rp', 'rp.role_id', '=', 'ur.role_id')
            ->where('ur.user_id', $userId)
            ->pluck('rp.permission_key')
            ->unique()
            ->values()
            ->all();

        if ($perms === []) {
            return $this->allPermissionKeys();
        }

        return $perms;
    }

    /** @return list<string> */
    private function allPermissionKeys(): array
    {
        if (! Schema::hasTable('permissions')) {
            return [];
        }

        return DB::table('permissions')
            ->pluck('permission_key')
            ->values()
            ->all();
    }
}
