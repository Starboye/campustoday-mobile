<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LoginAuditService
{
    public function write(?string $userId, string $username, string $status, string $ip, string $userAgent): void
    {
        if (! Schema::hasTable('login_audit')) {
            return;
        }

        DB::table('login_audit')->insert([
            'user_id' => $userId,
            'username' => $username,
            'status' => $status,
            'ip_address' => $ip,
            'user_agent' => substr($userAgent, 0, 250),
        ]);
    }
}
