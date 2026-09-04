<?php

namespace App\Http\Controllers\Student\Concerns;

use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

trait InteractsWithStudentSchema
{
    protected function schemaMissingResponse(): JsonResponse
    {
        return response()->json(['code' => 'schema_missing'], 501);
    }

    protected function currentAcademicYear(): string
    {
        $year = (int) now()->format('Y');
        $month = (int) now()->format('n');

        if ($month >= 6) {
            return $year.'-'.substr((string) ($year + 1), -2);
        }

        return ($year - 1).'-'.substr((string) $year, -2);
    }

    protected function classNotificationKeys(?int $standard, ?string $section): array
    {
        if ($standard === null || $section === null || $section === '') {
            return [];
        }

        $section = strtoupper($section);

        return [
            'CLASS_'.$standard.'_'.$section,
            strtoupper('CLASS_'.$standard.'_'.$section),
        ];
    }

    protected function scopeNotifications($query, string $studentId, ?int $standard, ?string $section): void
    {
        $classKeys = $this->classNotificationKeys($standard, $section);

        $query->where(function ($q) use ($studentId, $classKeys) {
            $q->where('id', $studentId)->orWhere('id', 'ALL');
            foreach ($classKeys as $key) {
                $q->orWhere('id', $key);
            }
        });
    }

    protected function notificationRowId(object $row): string
    {
        foreach (['nid', 'notification_id', 'pk'] as $column) {
            if (isset($row->{$column}) && $row->{$column} !== '') {
                return (string) $row->{$column};
            }
        }

        $fingerprint = implode('|', [
            (string) ($row->id ?? ''),
            (string) ($row->notification ?? $row->message ?? ''),
            (string) ($row->sentBy ?? $row->sent_by ?? ''),
            (string) ($row->date ?? ''),
            (string) ($row->time ?? ''),
        ]);

        return (string) sprintf('%u', crc32($fingerprint));
    }

    protected function notificationCreatedAt(object $row): string
    {
        if (! empty($row->created_at)) {
            return (string) $row->created_at;
        }

        $date = trim((string) ($row->date ?? ''));
        $time = trim((string) ($row->time ?? ''));

        if ($date === '') {
            return '';
        }

        return $time !== '' ? $date.' '.$time : $date;
    }

    protected function notificationIsRead(object $row, string $studentId, array $readIds): bool
    {
        if (Schema::hasColumn('notification', 'is_read')) {
            return (bool) ($row->is_read ?? false);
        }

        $rowId = $this->notificationRowId($row);
        if ($readIds !== [] && in_array($rowId, $readIds, true)) {
            return true;
        }

        if (Schema::hasColumn('notification', 'status') && (string) ($row->id ?? '') === $studentId) {
            return ! in_array((string) ($row->status ?? '0'), ['0', ''], true);
        }

        return false;
    }

    /** @return list<string> */
    protected function notificationReadIdsForStudent(string $studentId): array
    {
        if (! Schema::hasTable('notification_reads')) {
            return [];
        }

        return DB::table('notification_reads')
            ->where('user_id', $studentId)
            ->pluck('notification_id')
            ->map(fn ($id) => (string) $id)
            ->all();
    }

    protected function markNotificationRead(object $row, string $studentId): void
    {
        $rowId = $this->notificationRowId($row);

        if (Schema::hasTable('notification_reads')) {
            DB::table('notification_reads')->updateOrInsert(
                [
                    'notification_id' => $rowId,
                    'user_id' => $studentId,
                ],
                ['read_at' => now()]
            );

            return;
        }

        if (Schema::hasColumn('notification', 'is_read')) {
            DB::table('notification')
                ->where('id', $row->id)
                ->where('notification', $row->notification ?? null)
                ->where('date', $row->date ?? null)
                ->where('time', $row->time ?? null)
                ->update(['is_read' => 1]);

            return;
        }

        if (Schema::hasColumn('notification', 'status') && (string) ($row->id ?? '') === $studentId) {
            DB::table('notification')
                ->where('id', $row->id)
                ->where('notification', $row->notification ?? null)
                ->where('date', $row->date ?? null)
                ->where('time', $row->time ?? null)
                ->update(['status' => 1]);
        }
    }

    protected function findNotificationForStudent(string $studentId, ?StudentInfo $student, string $apiId): ?object
    {
        $query = DB::table('notification');
        $this->scopeNotifications($query, $studentId, $student?->standard, $student?->section);

        foreach ($query->get() as $row) {
            if ($this->notificationRowId($row) === $apiId) {
                return $row;
            }
        }

        return null;
    }

    protected function formatAnnouncement(object $row, string $studentId, array $readIds): array
    {
        $payload = [
            'id' => $this->notificationRowId($row),
            'title' => (string) ($row->title ?? $row->sentBy ?? $row->sent_by ?? 'Announcement'),
            'message' => (string) ($row->message ?? $row->notification ?? ''),
            'created_at' => $this->notificationCreatedAt($row),
            'sent_by' => (string) ($row->sentBy ?? $row->sent_by ?? ''),
        ];

        if (
            Schema::hasColumn('notification', 'is_read')
            || Schema::hasColumn('notification', 'status')
            || Schema::hasTable('notification_reads')
        ) {
            $payload['is_read'] = $this->notificationIsRead($row, $studentId, $readIds);
        }

        return $payload;
    }

    /** @return list<string> */
    protected function reportCardSubjects(): array
    {
        return ['english', 'tamil', 'maths', 'science', 'social'];
    }

    /** @return array<string, string> */
    protected function reportCardSubjectLabels(): array
    {
        return [
            'english' => 'English',
            'tamil' => 'Tamil',
            'maths' => 'Maths',
            'science' => 'Science',
            'social' => 'Social',
        ];
    }

    /** @return list<string> */
    protected function reportCardTerms(): array
    {
        return ['Term 1', 'Term 2', 'Term 3'];
    }
}
