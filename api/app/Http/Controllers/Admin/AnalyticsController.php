<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AnalyticsController extends AdminController
{
    public function show(Request $request): JsonResponse
    {
        $metrics = [
            'students' => Schema::hasTable('student_info')
                ? (int) DB::table('student_info')->count()
                : null,
            'teachers' => Schema::hasTable('user_login')
                ? (int) DB::table('user_login')->where('access', 1)->count()
                : null,
        ];

        if (Schema::hasTable('attendance')) {
            $monthStart = now()->startOfMonth()->toDateString();
            $monthEnd = now()->endOfMonth()->toDateString();
            $metrics['attendance_records_this_month'] = (int) DB::table('attendance')
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->count();
        }

        if (Schema::hasTable('marks_new')) {
            $metrics['marks_entries'] = (int) DB::table('marks_new')->count();
            $metrics['avg_marks'] = round((float) DB::table('marks_new')->avg('marks'), 2);
        }

        if (Schema::hasTable('student_fee_status')) {
            $metrics['fee_records'] = (int) DB::table('student_fee_status')->count();
            $paidCol = Schema::hasColumn('student_fee_status', 'status') ? 'status' : 'payment_status';
            $metrics['fees_paid_count'] = (int) DB::table('student_fee_status')
                ->where($paidCol, 'paid')
                ->count();
        }

        if (Schema::hasTable('homeworks')) {
            $metrics['homework_count'] = (int) DB::table('homeworks')->count();
        }

        $byStandard = [];
        if (Schema::hasTable('student_info')) {
            $byStandard = DB::table('student_info')
                ->select('standard', DB::raw('COUNT(*) as count'))
                ->whereNotNull('standard')
                ->groupBy('standard')
                ->orderBy('standard')
                ->get()
                ->map(fn ($row) => [
                    'standard' => (int) $row->standard,
                    'count' => (int) $row->count,
                ])
                ->values()
                ->all();
        }

        return response()->json([
            'metrics' => $metrics,
            'students_by_standard' => $byStandard,
        ]);
    }
}
