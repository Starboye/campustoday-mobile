<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AttendanceController extends Controller
{
    private const SESSIONS = ['morning', 'afternoon', 'evening'];

    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('attendance')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Attendance not available.'], 501);
        }

        $data = $request->validate([
            'class' => ['required', 'integer'],
            'section' => ['required', 'string'],
            'date' => ['required', 'date_format:Y-m-d'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];
        $standard = (int) $data['class'];
        $section = (string) $data['section'];
        $date = (string) $data['date'];

        if (! $this->allocations->isAllocatedToClass($teacherId, $standard, $section)) {
            return response()->json(['message' => 'Not allocated to this class.'], 403);
        }

        $students = DB::table('student_info')
            ->where('standard', $standard)
            ->where('section', $section)
            ->orderBy('name')
            ->get(['id', 'name', 'standard', 'section']);

        $attendanceMap = DB::table('attendance')
            ->where('date', $date)
            ->whereIn('student_id', $students->pluck('id'))
            ->get(['student_id', 'morning', 'afternoon', 'evening'])
            ->keyBy('student_id');

        $items = $students->map(function ($student) use ($attendanceMap) {
            $record = $attendanceMap->get($student->id);

            return [
                'student_id' => (string) $student->id,
                'name' => (string) ($student->name ?? ''),
                'standard' => (int) $student->standard,
                'section' => (string) $student->section,
                'morning' => $record->morning ?? null,
                'afternoon' => $record->afternoon ?? null,
                'evening' => $record->evening ?? null,
            ];
        })->values();

        return response()->json([
            'date' => $date,
            'standard' => $standard,
            'section' => $section,
            'items' => $items,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        if (! Schema::hasTable('attendance')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Attendance not available.'], 501);
        }

        $data = $request->validate([
            'student_id' => ['required', 'string'],
            'date' => ['required', 'date_format:Y-m-d'],
            'session' => ['required', 'in:morning,afternoon,evening'],
            'status' => ['required', 'string'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $student = DB::table('student_info')
            ->where('id', $data['student_id'])
            ->first(['standard', 'section']);

        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json(['message' => 'Student not found.'], 404);
        }

        if (! $this->allocations->canAccessStudent($teacherId, $data['student_id'])) {
            return response()->json(['message' => 'Not allocated to this student.'], 403);
        }

        if ($this->isDayLocked($data['date'], (int) $student->standard, (string) $student->section)) {
            return response()->json(['message' => 'Attendance day is locked.'], 403);
        }

        $session = $data['session'];
        $existing = DB::table('attendance')
            ->where('student_id', $data['student_id'])
            ->where('date', $data['date'])
            ->first();

        if ($existing) {
            DB::table('attendance')
                ->where('student_id', $data['student_id'])
                ->where('date', $data['date'])
                ->update([$session => $data['status']]);
        } else {
            $insert = [
                'student_id' => $data['student_id'],
                'date' => $data['date'],
                'morning' => null,
                'afternoon' => null,
                'evening' => null,
            ];
            $insert[$session] = $data['status'];
            DB::table('attendance')->insert($insert);
        }

        $updated = DB::table('attendance')
            ->where('student_id', $data['student_id'])
            ->where('date', $data['date'])
            ->first(['student_id', 'date', 'morning', 'afternoon', 'evening']);

        return response()->json([
            'message' => 'Attendance updated.',
            'student_id' => (string) $updated->student_id,
            'date' => (string) $updated->date,
            'morning' => $updated->morning,
            'afternoon' => $updated->afternoon,
            'evening' => $updated->evening,
        ]);
    }

    private function isDayLocked(string $date, int $standard, string $section): bool
    {
        if (! Schema::hasTable('attendance_day_lock')) {
            return false;
        }

        $query = DB::table('attendance_day_lock')->where('date', $date);

        if (Schema::hasColumn('attendance_day_lock', 'standard')
            && Schema::hasColumn('attendance_day_lock', 'section')) {
            $locked = (clone $query)
                ->where(function ($q) use ($standard, $section) {
                    $q->where(function ($inner) use ($standard, $section) {
                        $inner->where('standard', $standard)->where('section', $section);
                    })->orWhere(function ($inner) {
                        $inner->whereNull('standard')->whereNull('section');
                    });
                })
                ->get();

            foreach ($locked as $row) {
                if ($this->rowIsLocked($row)) {
                    return true;
                }
            }

            return false;
        }

        $row = $query->first();

        return $row !== null && $this->rowIsLocked($row);
    }

    private function rowIsLocked(object $row): bool
    {
        if (isset($row->locked)) {
            return (bool) $row->locked;
        }

        if (isset($row->is_locked)) {
            return (bool) $row->is_locked;
        }

        return true;
    }
}
