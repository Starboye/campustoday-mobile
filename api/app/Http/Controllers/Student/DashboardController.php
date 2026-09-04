<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        if (! $student) {
            return response()->json(['message' => 'Student profile not found.'], 404);
        }

        $standard = $student->standard;
        $section = $student->section;
        $monthStart = now()->startOfMonth()->toDateString();
        $monthEnd = now()->endOfMonth()->toDateString();

        $attendance = ['present' => 0, 'absent' => 0, 'total_days' => 0];
        if (Schema::hasTable('attendance')) {
            $rows = DB::table('attendance')
                ->where('student_id', $auth['id'])
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->get(['morning', 'afternoon', 'evening']);

            foreach ($rows as $row) {
                foreach (['morning', 'afternoon', 'evening'] as $session) {
                    $status = $row->{$session} ?? null;
                    if ($status === null || $status === '') {
                        continue;
                    }
                    $attendance['total_days']++;
                    if (in_array(strtolower((string) $status), ['present', 'p', '1'], true)) {
                        $attendance['present']++;
                    } elseif (in_array(strtolower((string) $status), ['absent', 'a', '0'], true)) {
                        $attendance['absent']++;
                    }
                }
            }
        }

        $unreadCount = 0;
        if (Schema::hasTable('notification')) {
            $query = DB::table('notification');
            $this->scopeNotifications($query, $auth['id'], $standard, $section);
            if (Schema::hasColumn('notification', 'is_read')) {
                $query->where('is_read', 0);
            }
            $unreadCount = $query->count();
        }

        $latestMarks = [];
        if (Schema::hasTable('marks_new')) {
            $latestMarks = DB::table('marks_new')
                ->where('student_id', $auth['id'])
                ->orderByDesc('id')
                ->limit(5)
                ->get(['subject_name', 'marks', 'term', 'exam_type'])
                ->map(fn ($row) => [
                    'subject_name' => $row->subject_name,
                    'marks' => $row->marks,
                    'term' => $row->term,
                    'exam_type' => $row->exam_type ?? null,
                ])
                ->values()
                ->all();
        }

        return response()->json([
            'profile' => [
                'id' => (string) $auth['id'],
                'name' => $student->name ?? $auth['name'],
                'standard' => $standard,
                'section' => $section,
            ],
            'attendance_summary' => $attendance,
            'unread_notifications' => $unreadCount,
            'latest_marks' => $latestMarks,
        ]);
    }

    private function scopeNotifications($query, string $studentId, $standard, $section): void
    {
        $classKey = ($standard !== null && $section !== null)
            ? 'CLASS_'.$standard.'_'.$section
            : null;

        $query->where(function ($q) use ($studentId, $classKey) {
            $q->where('id', $studentId)->orWhere('id', 'ALL');
            if ($classKey) {
                $q->orWhere('id', $classKey);
            }
        });
    }
}
