<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];
        $today = now()->toDateString();

        $allocationRows = $this->allocations->allocations($teacherId);
        $formattedAllocations = $allocationRows
            ->map(fn ($row) => $this->allocations->formatAllocation($row))
            ->values()
            ->all();

        $classSections = $this->allocations->distinctClassSections($teacherId);
        $totalSections = count($classSections);
        $completedSections = 0;

        if ($totalSections > 0 && Schema::hasTable('attendance')) {
            foreach ($classSections as $classSection) {
                if ($this->isSectionAttendanceComplete($classSection['standard'], $classSection['section'], $today)) {
                    $completedSections++;
                }
            }
        } else {
            $completedSections = $totalSections;
        }

        $homeworkCount = 0;
        if (Schema::hasTable('homeworks')) {
            $homeworkCount = DB::table('homeworks')
                ->where('teacher_id', $teacherId)
                ->where('date', $today)
                ->count();
        }

        $percent = $totalSections > 0
            ? round(($completedSections / $totalSections) * 100, 1)
            : 100.0;

        return response()->json([
            'allocations' => $formattedAllocations,
            'attendance_completeness' => [
                'date' => $today,
                'total_sections' => $totalSections,
                'completed_sections' => $completedSections,
                'percent' => $percent,
            ],
            'homework_count' => $homeworkCount,
        ]);
    }

    private function isSectionAttendanceComplete(int $standard, string $section, string $date): bool
    {
        $studentIds = DB::table('student_info')
            ->where('standard', $standard)
            ->where('section', $section)
            ->pluck('id');

        if ($studentIds->isEmpty()) {
            return true;
        }

        $records = DB::table('attendance')
            ->where('date', $date)
            ->whereIn('student_id', $studentIds)
            ->get(['student_id', 'morning', 'afternoon', 'evening']);

        $byStudent = $records->keyBy('student_id');

        foreach ($studentIds as $studentId) {
            $record = $byStudent->get($studentId);
            if (! $record) {
                return false;
            }

            foreach (['morning', 'afternoon', 'evening'] as $session) {
                $status = $record->{$session} ?? null;
                if ($status === null || $status === '') {
                    return false;
                }
            }
        }

        return true;
    }
}
