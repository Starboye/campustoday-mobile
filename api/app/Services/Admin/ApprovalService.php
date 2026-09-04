<?php

namespace App\Services\Admin;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ApprovalService
{
    /** @return array<string, mixed>|null */
    public function approve(int $id, string $adminId): ?array
    {
        $row = DB::table('approval_requests')->where('id', $id)->first();
        if (! $row || ($row->status ?? '') !== 'pending') {
            return null;
        }

        DB::transaction(function () use ($row, $id, $adminId) {
            DB::table('approval_requests')->where('id', $id)->update([
                'status' => 'approved',
                'reviewed_by' => $adminId,
                'reviewed_at' => now(),
            ]);

            $type = $row->request_type ?? $row->type ?? '';
            if ($type === 'timetable' && Schema::hasTable('class_timetables')) {
                $timetableId = $row->entity_id ?? null;
                if ($timetableId) {
                    DB::table('class_timetables')
                        ->where('id', $timetableId)
                        ->update(['status' => 'approved']);
                }
            }
        });

        return [
            'id' => $id,
            'status' => 'approved',
            'reviewed_by' => $adminId,
        ];
    }

    /** @return array<string, mixed>|null */
    public function reject(int $id, string $adminId, ?string $notes): ?array
    {
        $row = DB::table('approval_requests')->where('id', $id)->first();
        if (! $row || ($row->status ?? '') !== 'pending') {
            return null;
        }

        $update = [
            'status' => 'rejected',
            'reviewed_by' => $adminId,
            'reviewed_at' => now(),
        ];
        if ($notes !== null && Schema::hasColumn('approval_requests', 'notes')) {
            $update['notes'] = $notes;
        }

        DB::table('approval_requests')->where('id', $id)->update($update);

        return [
            'id' => $id,
            'status' => 'rejected',
            'reviewed_by' => $adminId,
            'notes' => $notes,
        ];
    }
}
