<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TimetableController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json(['status' => 'unavailable', 'items' => []]);
        }

        if (! Schema::hasTable('class_timetables')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $timetable = DB::table('class_timetables')
            ->where('standard', $student->standard)
            ->where('section', $student->section)
            ->orderByDesc('id')
            ->first();

        if (! $timetable || ($timetable->status ?? '') !== 'approved') {
            return response()->json([
                'status' => $timetable->status ?? 'pending',
                'items' => [],
                'message' => 'Timetable is not yet approved.',
            ]);
        }

        $items = [];
        if (Schema::hasTable('assignments') && Schema::hasTable('slots')) {
            $items = DB::table('assignments as a')
                ->join('slots as s', 's.id', '=', 'a.slot_id')
                ->where('a.timetable_id', $timetable->id)
                ->orderBy('s.day')
                ->orderBy('s.period')
                ->get([
                    's.day', 's.period', 's.start_time', 's.end_time',
                    'a.subject_name', 'a.teacher_id',
                ])
                ->map(fn ($row) => [
                    'day' => $row->day,
                    'period' => (int) $row->period,
                    'start_time' => $row->start_time,
                    'end_time' => $row->end_time,
                    'subject_name' => $row->subject_name,
                    'teacher_id' => (string) $row->teacher_id,
                ])
                ->values()
                ->all();
        }

        return response()->json([
            'status' => 'approved',
            'timetable_id' => (int) $timetable->id,
            'items' => $items,
        ]);
    }
}
