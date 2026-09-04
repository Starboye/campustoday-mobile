<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AnnouncementsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('notification')) {
            return response()->json(['code' => 'schema_missing', 'message' => 'Notifications not available.'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);
        $standard = $student?->standard;
        $section = $student?->section;

        $query = DB::table('notification');
        $this->scopeNotifications($query, $auth['id'], $standard, $section);

        $columns = ['id', 'title', 'message', 'created_at'];
        if (Schema::hasColumn('notification', 'is_read')) {
            $columns[] = 'is_read';
        }
        if (Schema::hasColumn('notification', 'date')) {
            $columns[] = 'date';
        }

        $items = $query->orderByDesc('created_at')->orderByDesc('id')
            ->get($columns)
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'title' => $row->title ?? '',
                'message' => $row->message ?? $row->title ?? '',
                'created_at' => (string) ($row->created_at ?? $row->date ?? ''),
                'is_read' => (bool) ($row->is_read ?? false),
            ])
            ->values();

        return response()->json(['items' => $items]);
    }

    public function markRead(Request $request, int $id): JsonResponse
    {
        if (! Schema::hasTable('notification')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        if (! Schema::hasColumn('notification', 'is_read')) {
            return response()->json(['message' => 'Read status not supported.'], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        $exists = DB::table('notification')->where('id', $id)->exists();
        if (! $exists) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        DB::table('notification')->where('id', $id)->update(['is_read' => 1]);

        return response()->json(['message' => 'Marked read.', 'id' => $id]);
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
