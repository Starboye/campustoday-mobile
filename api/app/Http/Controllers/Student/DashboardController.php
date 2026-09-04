<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Student\Concerns\InteractsWithStudentSchema;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    use InteractsWithStudentSchema;

    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        if (! $student) {
            return response()->json(['message' => 'Student profile not found.'], 404);
        }

        $monthStart = now()->startOfMonth()->toDateString();
        $monthEnd = now()->endOfMonth()->toDateString();

        $attendance = ['present' => 0, 'absent' => 0];
        if (Schema::hasTable('attendance')) {
            $rows = DB::table('attendance')
                ->where('id', $auth['id'])
                ->whereBetween('date', [$monthStart, $monthEnd])
                ->get(['status']);

            foreach ($rows as $row) {
                if ($row->status === null) {
                    continue;
                }
                if ((int) $row->status === 0) {
                    $attendance['absent']++;
                } else {
                    $attendance['present']++;
                }
            }
        }

        $unreadCount = 0;
        if (Schema::hasTable('notification')) {
            $query = DB::table('notification');
            $this->scopeNotifications($query, $auth['id'], $student->standard, $student->section);
            $readIds = $this->notificationReadIdsForStudent($auth['id']);

            foreach ($query->get() as $row) {
                if (! $this->notificationIsRead($row, $auth['id'], $readIds)) {
                    $unreadCount++;
                }
            }
        }

        $latestMarks = [];
        if (Schema::hasTable('marks_new')) {
            $labels = $this->reportCardSubjectLabels();
            $rows = DB::table('marks_new')
                ->where('id', $auth['id'])
                ->orderByDesc('date')
                ->orderByDesc('testName')
                ->limit(3)
                ->get();

            foreach ($rows as $row) {
                foreach ($this->reportCardSubjects() as $subject) {
                    $latestMarks[] = [
                        'term' => (string) $row->testName,
                        'subject_name' => $labels[$subject],
                        'marks' => (int) ($row->{$subject} ?? 0),
                        'max_marks' => (int) ($row->totalMarks ?? 100),
                        'date' => (string) ($row->date ?? ''),
                    ];
                }
            }

            $latestMarks = array_slice($latestMarks, 0, 5);
        }

        return response()->json([
            'profile' => [
                'id' => (string) $auth['id'],
                'name' => (string) ($student->name ?? $auth['name']),
                'standard' => $student->standard,
                'section' => $student->section,
            ],
            'attendance_summary' => $attendance,
            'unread_notifications' => $unreadCount,
            'latest_marks' => $latestMarks,
        ]);
    }
}
