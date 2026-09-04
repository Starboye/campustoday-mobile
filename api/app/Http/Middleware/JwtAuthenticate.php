<?php

namespace App\Http\Middleware;

use App\Services\JwtService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class JwtAuthenticate
{
    public function __construct(private readonly JwtService $jwt) {}

    public function handle(Request $request, Closure $next, ?string $requiredAccess = null): Response
    {
        $header = (string) $request->header('Authorization', '');

        if (! str_starts_with($header, 'Bearer ')) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        try {
            $payload = $this->jwt->decode(substr($header, 7));
        } catch (\Throwable) {
            return response()->json(['message' => 'Invalid or expired token.'], 401);
        }

        $request->attributes->set('auth_user', [
            'id' => (string) $payload->sub,
            'name' => (string) ($payload->name ?? ''),
            'access' => (int) ($payload->access ?? -1),
            'permissions' => array_values((array) ($payload->permissions ?? [])),
        ]);

        if ($requiredAccess !== null && (int) $request->attributes->get('auth_user')['access'] !== (int) $requiredAccess) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        return $next($request);
    }
}
