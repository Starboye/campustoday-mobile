<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RequirePermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $auth = $request->attributes->get('auth_user', []);
        $access = (int) ($auth['access'] ?? -1);

        if ($access !== 2) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $permissions = array_values((array) ($auth['permissions'] ?? []));

        // Empty permissions = full admin fallback (matches web bootstrap.php).
        if ($permissions !== [] && ! in_array($permission, $permissions, true)) {
            return response()->json(['message' => 'Permission denied.', 'code' => 'permission_denied'], 403);
        }

        return $next($request);
    }
}
