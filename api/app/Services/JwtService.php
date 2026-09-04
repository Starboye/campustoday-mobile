<?php

namespace App\Services;

use App\Models\UserLogin;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Str;

class JwtService
{
    public function issueAccessToken(UserLogin $user, array $permissions): string
    {
        $now = time();
        $ttl = config('campustoday.access_ttl', 1800);

        $payload = [
            'iss' => config('app.url'),
            'sub' => (string) $user->id,
            'name' => (string) $user->name,
            'access' => (int) $user->access,
            'permissions' => $permissions,
            'iat' => $now,
            'exp' => $now + $ttl,
            'jti' => (string) Str::uuid(),
        ];

        return JWT::encode($payload, $this->secret(), 'HS256');
    }

    public function decode(string $token): object
    {
        return JWT::decode($token, new Key($this->secret(), 'HS256'));
    }

    public function accessTtl(): int
    {
        return (int) config('campustoday.access_ttl', 1800);
    }

    private function secret(): string
    {
        $secret = (string) config('campustoday.jwt_secret');

        if ($secret === '') {
            $secret = (string) config('app.key');
        }

        if (str_starts_with($secret, 'base64:')) {
            return base64_decode(substr($secret, 7)) ?: $secret;
        }

        return $secret;
    }
}
