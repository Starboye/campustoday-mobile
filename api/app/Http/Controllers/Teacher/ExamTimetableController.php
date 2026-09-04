<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ExamTimetableController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function show(Request $request): JsonResponse
    {
        if (! Schema::hasTable('timetable_slots')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Exam timetable not available.'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];
        $classSections = $this->allocations->distinctClassSections($teacherId);

        $columns = ['id'];
        foreach (['standard', 'section', 'subject_name', 'exam_name', 'exam_date', 'date', 'start_time', 'end_time', 'room', 'teacher_id'] as $column) {
            if (Schema::hasColumn('timetable_slots', $column)) {
                $columns[] = $column;
            }
        }

        $query = DB::table('timetable_slots');

        if (Schema::hasColumn('timetable_slots', 'teacher_id')) {
            $query->where(function ($q) use ($teacherId, $classSections) {
                $q->where('teacher_id', $teacherId);
                if ($classSections !== []) {
                    $q->orWhere(function ($inner) use ($classSections) {
                        foreach ($classSections as $classSection) {
                            if (Schema::hasColumn('timetable_slots', 'standard')
                                && Schema::hasColumn('timetable_slots', 'section')) {
                                $inner->orWhere(function ($classQuery) use ($classSection) {
                                    $classQuery->where('standard', $classSection['standard'])
                                        ->where('section', $classSection['section']);
                                });
                            }
                        }
                    });
                }
            });
        } elseif (Schema::hasColumn('timetable_slots', 'standard')
            && Schema::hasColumn('timetable_slots', 'section')) {
            $query->where(function ($q) use ($classSections) {
                foreach ($classSections as $classSection) {
                    $q->orWhere(function ($inner) use ($classSection) {
                        $inner->where('standard', $classSection['standard'])
                            ->where('section', $classSection['section']);
                    });
                }
            });
        }

        $dateColumn = Schema::hasColumn('timetable_slots', 'exam_date') ? 'exam_date' : 'date';
        if (Schema::hasColumn('timetable_slots', $dateColumn)) {
            $query->orderBy($dateColumn);
        }

        if (Schema::hasColumn('timetable_slots', 'start_time')) {
            $query->orderBy('start_time');
        }

        $items = $query->get($columns)
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'standard' => isset($row->standard) ? (int) $row->standard : null,
                'section' => $row->section ?? null,
                'subject_name' => $row->subject_name ?? null,
                'exam_name' => $row->exam_name ?? null,
                'date' => (string) ($row->exam_date ?? $row->date ?? ''),
                'start_time' => $row->start_time ?? null,
                'end_time' => $row->end_time ?? null,
                'room' => $row->room ?? null,
                'teacher_id' => isset($row->teacher_id) ? (string) $row->teacher_id : null,
            ])
            ->values();

        return response()->json(['items' => $items]);
    }
}
