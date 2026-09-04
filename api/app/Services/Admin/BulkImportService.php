<?php

namespace App\Services\Admin;

use App\Services\PasswordService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class BulkImportService
{
    public function __construct(private readonly PasswordService $passwords) {}

    /** @return array<string, mixed> */
    public function import(string $type, string $filePath): array
    {
        return match ($type) {
            'students' => $this->importStudents($filePath),
            'marks' => $this->importMarks($filePath),
            'attendance' => $this->importAttendance($filePath),
            default => ['message' => 'Unsupported import type.'],
        };
    }

    /** @return array<string, mixed> */
    private function importStudents(string $filePath): array
    {
        if (! Schema::hasTable('student_info') || ! Schema::hasTable('user_login')) {
            return ['code' => 'schema_missing'];
        }

        $rows = $this->readCsv($filePath);
        $imported = 0;
        $errors = [];

        foreach ($rows as $i => $row) {
            $line = $i + 2;
            $username = trim($row['username'] ?? $row['name'] ?? '');
            $password = trim($row['password'] ?? 'Demo@2026');
            $name = trim($row['name'] ?? $username);
            $standard = (int) ($row['standard'] ?? 0);
            $section = trim($row['section'] ?? '');

            if ($username === '' || $standard < 1 || $section === '') {
                $errors[] = "Line {$line}: missing required fields.";

                continue;
            }

            if (DB::table('user_login')->where('name', $username)->exists()) {
                $errors[] = "Line {$line}: username exists.";

                continue;
            }

            $id = trim($row['id'] ?? '') ?: (string) (((int) DB::table('student_info')->max(DB::raw('CAST(id AS UNSIGNED)'))) + 1);

            DB::table('user_login')->insert([
                'id' => $id,
                'name' => $username,
                'password' => $this->passwords->hash($password),
                'access' => 0,
            ]);
            DB::table('student_info')->insert([
                'id' => $id,
                'name' => $name,
                'standard' => $standard,
                'section' => $section,
            ]);
            $imported++;
        }

        return ['imported' => $imported, 'errors' => $errors];
    }

    /** @return array<string, mixed> */
    private function importMarks(string $filePath): array
    {
        if (! Schema::hasTable('marks_new')) {
            return ['code' => 'schema_missing'];
        }

        $rows = $this->readCsv($filePath);
        $imported = 0;
        $errors = [];

        foreach ($rows as $i => $row) {
            $line = $i + 2;
            $studentId = trim($row['student_id'] ?? '');
            $subject = trim($row['subject_name'] ?? '');
            $marks = $row['marks'] ?? null;
            $term = (int) ($row['term'] ?? 1);

            if ($studentId === '' || $subject === '' || $marks === null) {
                $errors[] = "Line {$line}: missing required fields.";

                continue;
            }

            DB::table('marks_new')->insert([
                'student_id' => $studentId,
                'subject_name' => $subject,
                'marks' => $marks,
                'term' => $term,
                'grade' => $row['grade'] ?? null,
                'exam_type' => $row['exam_type'] ?? null,
            ]);
            $imported++;
        }

        return ['imported' => $imported, 'errors' => $errors];
    }

    /** @return array<string, mixed> */
    private function importAttendance(string $filePath): array
    {
        if (! Schema::hasTable('attendance')) {
            return ['code' => 'schema_missing'];
        }

        $rows = $this->readCsv($filePath);
        $imported = 0;
        $errors = [];

        foreach ($rows as $i => $row) {
            $line = $i + 2;
            $studentId = trim($row['student_id'] ?? '');
            $date = trim($row['date'] ?? '');

            if ($studentId === '' || $date === '') {
                $errors[] = "Line {$line}: missing student_id or date.";

                continue;
            }

            DB::table('attendance')->insert([
                'student_id' => $studentId,
                'date' => $date,
                'morning' => $row['morning'] ?? null,
                'afternoon' => $row['afternoon'] ?? null,
                'evening' => $row['evening'] ?? null,
            ]);
            $imported++;
        }

        return ['imported' => $imported, 'errors' => $errors];
    }

    /** @return list<array<string, string>> */
    private function readCsv(string $filePath): array
    {
        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            return [];
        }

        $header = fgetcsv($handle);
        if ($header === false) {
            fclose($handle);

            return [];
        }

        $header = array_map(fn ($h) => strtolower(trim((string) $h)), $header);
        $rows = [];

        while (($data = fgetcsv($handle)) !== false) {
            if (count($data) === 1 && ($data[0] === null || $data[0] === '')) {
                continue;
            }
            $row = [];
            foreach ($header as $idx => $col) {
                $row[$col] = $data[$idx] ?? '';
            }
            $rows[] = $row;
        }

        fclose($handle);

        return $rows;
    }
}
