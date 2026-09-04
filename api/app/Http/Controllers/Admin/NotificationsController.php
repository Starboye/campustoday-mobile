<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class NotificationsController extends AdminController
{
    public function listTemplates(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['notification_templates'])) {
            return $response;
        }

        $page = $this->cursor->paginate(DB::table('notification_templates'), $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'name' => $row->name ?? $row->title ?? '',
                'title' => $row->title ?? '',
                'message' => $row->message ?? $row->body ?? '',
                'channel' => $row->channel ?? 'push',
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeTemplate(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['notification_templates'])) {
            return $response;
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'title' => ['required', 'string', 'max:200'],
            'message' => ['required', 'string'],
            'channel' => ['nullable', 'string', 'max:50'],
        ]);

        $insert = [
            'name' => $data['name'],
            'title' => $data['title'],
        ];
        $msgCol = Schema::hasColumn('notification_templates', 'message') ? 'message' : 'body';
        $insert[$msgCol] = $data['message'];
        if (isset($data['channel'])) {
            $insert['channel'] = $data['channel'];
        }

        $id = DB::table('notification_templates')->insertGetId($insert);

        return response()->json(['id' => $id, ...$data], 201);
    }

    public function listSchedules(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['notification_schedules'])) {
            return $response;
        }

        $page = $this->cursor->paginate(DB::table('notification_schedules'), $request, 'id');

        return response()->json([
            'items' => $page['items']->map(fn ($row) => [
                'id' => (int) $row->id,
                'template_id' => $row->template_id ?? null,
                'target' => $row->target ?? $row->audience ?? 'ALL',
                'scheduled_at' => $row->scheduled_at ?? null,
                'status' => $row->status ?? 'pending',
            ])->values(),
            'next_cursor' => $page['next_cursor'],
        ]);
    }

    public function storeSchedule(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['notification_schedules'])) {
            return $response;
        }

        $data = $request->validate([
            'template_id' => ['required', 'integer'],
            'target' => ['required', 'string', 'max:50'],
            'scheduled_at' => ['required', 'date'],
        ]);

        $id = DB::table('notification_schedules')->insertGetId([
            'template_id' => $data['template_id'],
            'target' => $data['target'],
            'scheduled_at' => $data['scheduled_at'],
            'status' => 'pending',
        ]);

        return response()->json(['id' => $id, ...$data, 'status' => 'pending'], 201);
    }

    public function send(Request $request): JsonResponse
    {
        if ($response = $this->requireTables(['notification'])) {
            return $response;
        }

        $data = $request->validate([
            'target' => ['required', 'string', 'max:50'],
            'title' => ['required', 'string', 'max:200'],
            'message' => ['required', 'string'],
        ]);

        $insert = [
            'id' => $data['target'],
            'title' => $data['title'],
            'message' => $data['message'],
            'created_at' => now(),
        ];
        if (Schema::hasColumn('notification', 'is_read')) {
            $insert['is_read'] = 0;
        }
        if (Schema::hasColumn('notification', 'date')) {
            $insert['date'] = now()->toDateString();
        }

        $id = DB::table('notification')->insertGetId($insert);

        return response()->json([
            'message' => 'Notification sent.',
            'id' => $id,
            'target' => $data['target'],
        ], 201);
    }
}
