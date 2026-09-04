<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class UserSecurityService
{
    public function isLocked(string $userId): bool
    {
        if (! Schema::hasTable('user_security')) {
            return false;
        }

        $row = DB::table('user_security')->where('user_id', $userId)->first();

        if (! $row || empty($row->locked_until)) {
            return false;
        }

        return strtotime((string) $row->locked_until) > time();
    }

    public function requiresPasswordReset(string $userId): bool
    {
        if (! Schema::hasTable('user_security')) {
            return false;
        }

        $row = DB::table('user_security')->where('user_id', $userId)->first();

        return $row && (int) ($row->force_password_reset ?? 0) === 1;
    }
}
