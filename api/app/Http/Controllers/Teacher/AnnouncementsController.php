<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AnnouncementsController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function store(Request $request): JsonResponse
    {
        if (! Schema::hasTable('notification')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Notifications not available.'], 501);
        }

        $data = $request->validate([
            'title' => ['required', 'string'],
            'message' => ['required', 'string'],
            'target_type' => ['required', 'in:student,class,all'],
            'student_id' => ['nullable', 'string'],
            'standard' => ['nullable', 'integer'],
            'section' => ['nullable', 'string'],
        ]);

        $auth = $request->attributes->get('auth_user');
        $teacherId = (string) $auth['id'];

        $targetId = match ($data['target_type']) {
            'all' => 'ALL',
            'student' => $this->resolveStudentTarget($teacherId, $data['student_id'] ?? null),
            'class' => $this->resolveClassTarget($teacherId, $data['standard'] ?? null, $data['section'] ?? null),
        };

        $insert = [
            'title' => $data['title'],
            'message' => $data['message'],
        ];

        if (Schema::hasColumn('notification', 'target_id')) {
            $insert['target_id'] = $targetId;
        } elseif (Schema::hasColumn('notification', 'recipient_id')) {
            $insert['recipient_id'] = $targetId;
        } else {
            $insert['id'] = $targetId;
        }

        if (Schema::hasColumn('notification', 'created_at')) {
            $insert['created_at'] = now();
        }

        if (Schema::hasColumn('notification', 'date')) {
            $insert['date'] = now()->toDateString();
        }

        if (Schema::hasColumn('notification', 'is_read')) {
            $insert['is_read'] = 0;
        }

        if (Schema::hasColumn('notification', 'created_by')) {
            $insert['created_by'] = $teacherId;
        }

        if (Schema::hasColumn('notification', 'sender_id')) {
            $insert['sender_id'] = $teacherId;
        }

        $notificationId = DB::table('notification')->insertGetId($insert);

        return response()->json([
            'message' => 'Announcement created.',
            'id' => is_numeric($notificationId) ? (int) $notificationId : $notificationId,
            'target_type' => $data['target_type'],
            'target_id' => $targetId,
            'title' => $data['title'],
            'message' => $data['message'],
        ], 201);
    }

    private function resolveStudentTarget(string $teacherId, ?string $studentId): string
    {
        if ($studentId === null) {
            abort(response()->json(['message' => 'student_id is required for student target.'], 422));
        }

        if (! $this->allocations->canAccessStudent($teacherId, $studentId)) {
            abort(response()->json(['message' => 'Not allocated to this student.'], 403));
        }

        return $studentId;
    }

    private function resolveClassTarget(string $teacherId, ?int $standard, ?string $section): string
    {
        if ($standard === null || $section === null) {
            abort(response()->json(['message' => 'standard and section are required for class target.'], 422));
        }

        if (! $this->allocations->isAllocatedToClass($teacherId, $standard, $section)) {
            abort(response()->json(['message' => 'Not allocated to this class.'], 403));
        }

        return 'CLASS_'.$standard.'_'.$section;
    }
}
