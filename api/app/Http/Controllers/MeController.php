<?php

namespace App\Http\Controllers;

use App\Models\StudentInfo;
use App\Models\UserLogin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $user = UserLogin::query()->find($auth['id']);

        if (! $user) {
            return response()->json(['message' => 'User not found.'], 404);
        }

        $profile = null;
        if ((int) $user->access === 0) {
            $student = StudentInfo::query()->find($user->id);
            if ($student) {
                $profile = [
                    'standard' => $student->standard,
                    'section' => $student->section,
                    'name' => $student->name ?? $user->name,
                ];
            }
        }

        return response()->json([
            'id' => (string) $user->id,
            'name' => (string) $user->name,
            'access' => (int) $user->access,
            'permissions' => $auth['permissions'] ?? [],
            'profile' => $profile,
        ]);
    }

    public function updateDevice(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $data = $request->validate([
            'platform' => ['required', 'in:ios,android'],
            'fcm_token' => ['nullable', 'string', 'max:512'],
        ]);

        \Illuminate\Support\Facades\DB::table('api_devices')->updateOrInsert(
            [
                'user_id' => $auth['id'],
                'platform' => $data['platform'],
            ],
            [
                'fcm_token' => $data['fcm_token'] ?? null,
                'updated_at' => now(),
            ]
        );

        return response()->json(['message' => 'Device updated.']);
    }
}
