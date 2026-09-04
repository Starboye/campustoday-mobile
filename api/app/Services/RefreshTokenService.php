<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RefreshTokenService
{
    public function create(string $userId): array
    {
        $plain = Str::random(64);
        $hash = hash('sha256', $plain);
        $expiresAt = now()->addSeconds((int) config('campustoday.refresh_ttl', 604800));

        DB::table('api_refresh_tokens')->insert([
            'user_id' => $userId,
            'token_hash' => $hash,
            'expires_at' => $expiresAt,
            'revoked' => 0,
        ]);

        return [
            'token' => $plain,
            'expires_at' => $expiresAt,
        ];
    }

    public function rotate(string $plainToken): ?array
    {
        $hash = hash('sha256', $plainToken);

        $row = DB::table('api_refresh_tokens')
            ->where('token_hash', $hash)
            ->where('revoked', 0)
            ->where('expires_at', '>', now())
            ->first();

        if (! $row) {
            return null;
        }

        DB::table('api_refresh_tokens')
            ->where('id', $row->id)
            ->update(['revoked' => 1]);

        $created = $this->create((string) $row->user_id);
        $created['user_id'] = (string) $row->user_id;

        return $created;
    }

    public function revoke(string $plainToken): void
    {
        $hash = hash('sha256', $plainToken);

        DB::table('api_refresh_tokens')
            ->where('token_hash', $hash)
            ->update(['revoked' => 1]);
    }

    public function revokeAllForUser(string $userId): void
    {
        DB::table('api_refresh_tokens')
            ->where('user_id', $userId)
            ->update(['revoked' => 1]);
    }
}
