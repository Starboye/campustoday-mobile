<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Student\Concerns\InteractsWithStudentSchema;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AnnouncementsController extends Controller
{
    use InteractsWithStudentSchema;

    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('notification')) {
            return $this->schemaMissingResponse();
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        $query = DB::table('notification');
        $this->scopeNotifications($query, $auth['id'], $student?->standard, $student?->section);

        $readIds = $this->notificationReadIdsForStudent($auth['id']);

        $items = $query
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->get()
            ->map(fn ($row) => $this->formatAnnouncement($row, $auth['id'], $readIds))
            ->values();

        return response()->json(['items' => $items]);
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        if (! Schema::hasTable('notification')) {
            return $this->schemaMissingResponse();
        }

        if (
            ! Schema::hasTable('notification_reads')
            && ! Schema::hasColumn('notification', 'is_read')
            && ! Schema::hasColumn('notification', 'status')
        ) {
            return response()->json(['message' => 'Read status not supported.'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);
        $row = $this->findNotificationForStudent($auth['id'], $student, $id);

        if (! $row) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $this->markNotificationRead($row, $auth['id']);

        return response()->json([
            'message' => 'Marked read.',
            'id' => $id,
        ]);
    }
}
