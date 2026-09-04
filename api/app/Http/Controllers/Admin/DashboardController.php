<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends AdminController
{
    public function show(Request $request): JsonResponse
    {
        $kpis = [
            'students' => Schema::hasTable('student_info')
                ? (int) DB::table('student_info')->count()
                : null,
            'teachers' => Schema::hasTable('user_login')
                ? (int) DB::table('user_login')->where('access', 1)->count()
                : null,
            'admins' => Schema::hasTable('user_login')
                ? (int) DB::table('user_login')->where('access', 2)->count()
                : null,
        ];

        $pendingApprovals = 0;
        if (Schema::hasTable('approval_requests')) {
            $pendingApprovals = (int) DB::table('approval_requests')
                ->where('status', 'pending')
                ->count();
        }

        return response()->json([
            'kpis' => $kpis,
            'pending_approvals' => $pendingApprovals,
        ]);
    }
}
