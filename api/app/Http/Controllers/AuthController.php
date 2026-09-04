<?php

namespace App\Http\Controllers;

use App\Models\UserLogin;
use App\Services\JwtService;
use App\Services\LoginAuditService;
use App\Services\PasswordService;
use App\Services\PermissionService;
use App\Services\RefreshTokenService;
use App\Services\UserSecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;

class AuthController extends Controller
{
    public function __construct(
        private readonly PasswordService $passwords,
        private readonly LoginAuditService $loginAudit,
        private readonly PermissionService $permissions,
        private readonly JwtService $jwt,
        private readonly RefreshTokenService $refreshTokens,
        private readonly UserSecurityService $userSecurity,
    ) {}

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'username' => ['required', 'string'],
            'password' => ['required', 'string'],
            'access' => ['required', 'integer', 'in:0,1,2'],
        ]);

        $throttleKey = 'login:'.$request->ip().':'.strtolower($data['username']);

        if (RateLimiter::tooManyAttempts($throttleKey, (int) config('campustoday.login_rate_limit', 10))) {
            return response()->json(['message' => 'Too many login attempts.'], 429);
        }

        RateLimiter::hit($throttleKey, 60);

        $user = UserLogin::query()->where('name', $data['username'])->first();
        $ip = (string) $request->ip();
        $ua = (string) $request->userAgent();

        if (! $user || ! $this->passwords->verify($data['password'], (string) $user->password)) {
            $this->loginAudit->write(null, $data['username'], 'failed', $ip, $ua);

            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        if ((int) $user->access !== (int) $data['access']) {
            $this->loginAudit->write((string) $user->id, $data['username'], 'failed', $ip, $ua);

            return response()->json(['message' => 'Role mismatch.'], 401);
        }

        if ($this->userSecurity->isLocked((string) $user->id)) {
            $this->loginAudit->write((string) $user->id, $data['username'], 'failed', $ip, $ua);

            return response()->json(['message' => 'Account locked.'], 403);
        }

        $newHash = $this->passwords->rehashIfNeeded($data['password'], (string) $user->password);
        if ($newHash !== null) {
            DB::table('user_login')->where('id', $user->id)->update(['password' => $newHash]);
            $user->password = $newHash;
        }

        $this->loginAudit->write((string) $user->id, $data['username'], 'success', $ip, $ua);
        RateLimiter::clear($throttleKey);

        $permissionKeys = $this->permissions->forUser((string) $user->id, (int) $user->access);
        $refresh = $this->refreshTokens->create((string) $user->id);

        return response()->json([
            'access_token' => $this->jwt->issueAccessToken($user, $permissionKeys),
            'refresh_token' => $refresh['token'],
            'expires_in' => $this->jwt->accessTtl(),
            'user' => [
                'id' => (string) $user->id,
                'name' => (string) $user->name,
                'access' => (int) $user->access,
                'permissions' => $permissionKeys,
                'force_password_reset' => $this->userSecurity->requiresPasswordReset((string) $user->id),
            ],
        ]);
    }

    public function refresh(Request $request): JsonResponse
    {
        $data = $request->validate([
            'refresh_token' => ['required', 'string'],
        ]);

        $rotated = $this->refreshTokens->rotate($data['refresh_token']);

        if (! $rotated) {
            return response()->json(['message' => 'Invalid refresh token.'], 401);
        }

        $user = UserLogin::query()->find($rotated['user_id']);
        if (! $user) {
            return response()->json(['message' => 'User not found.'], 401);
        }

        $permissionKeys = $this->permissions->forUser((string) $user->id, (int) $user->access);

        return response()->json([
            'access_token' => $this->jwt->issueAccessToken($user, $permissionKeys),
            'refresh_token' => $rotated['token'],
            'expires_in' => $this->jwt->accessTtl(),
            'user' => [
                'id' => (string) $user->id,
                'name' => (string) $user->name,
                'access' => (int) $user->access,
                'permissions' => $permissionKeys,
                'force_password_reset' => $this->userSecurity->requiresPasswordReset((string) $user->id),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $data = $request->validate([
            'refresh_token' => ['required', 'string'],
        ]);

        $this->refreshTokens->revoke($data['refresh_token']);

        return response()->json(['message' => 'Logged out.']);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:6'],
        ]);

        $user = UserLogin::query()->find($auth['id']);
        if (! $user || ! $this->passwords->verify($data['current_password'], (string) $user->password)) {
            return response()->json(['message' => 'Current password is incorrect.'], 422);
        }

        DB::table('user_login')
            ->where('id', $user->id)
            ->update(['password' => $this->passwords->hash($data['new_password'])]);

        $this->refreshTokens->revokeAllForUser((string) $user->id);

        return response()->json(['message' => 'Password updated.']);
    }
}
