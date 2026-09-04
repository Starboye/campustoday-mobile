<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Student\Concerns\InteractsWithStudentSchema;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TimetableController extends Controller
{
    use InteractsWithStudentSchema;

    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json(['status' => 'pending', 'items' => []]);
        }

        if (! Schema::hasTable('class_timetables')) {
            return $this->schemaMissingResponse();
        }

        $academicYear = $this->currentAcademicYear();

        $timetable = DB::table('class_timetables')
            ->where('standard', $student->standard)
            ->where('section', $student->section)
            ->where('academic_year', $academicYear)
            ->first();

        if (! $timetable || ($timetable->status ?? '') !== 'approved') {
            return response()->json([
                'status' => $timetable->status ?? 'pending',
                'items' => [],
            ]);
        }

        $items = [];
        if (Schema::hasTable('timetable_slots')) {
            $items = DB::table('timetable_slots')
                ->where('standard', $student->standard)
                ->where('section', $student->section)
                ->orderBy('period_no')
                ->orderBy('day_of_week')
                ->get(['day_of_week', 'period_no', 'subject_name', 'teacher_id'])
                ->map(fn ($row) => [
                    'day_of_week' => (int) $row->day_of_week,
                    'day' => $this->dayLabel((int) $row->day_of_week),
                    'period_no' => (int) $row->period_no,
                    'subject_name' => (string) $row->subject_name,
                    'teacher_id' => (string) ($row->teacher_id ?? ''),
                ])
                ->values()
                ->all();
        }

        return response()->json([
            'status' => 'approved',
            'academic_year' => $academicYear,
            'items' => $items,
        ]);
    }

    private function dayLabel(int $dayOfWeek): string
    {
        return match ($dayOfWeek) {
            1 => 'Monday',
            2 => 'Tuesday',
            3 => 'Wednesday',
            4 => 'Thursday',
            5 => 'Friday',
            default => 'Day '.$dayOfWeek,
        };
    }
}
