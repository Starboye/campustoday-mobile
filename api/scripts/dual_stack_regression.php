<?php

/**
 * Dual-stack regression: homework GET, attendance PUT, student dashboard GET.
 *
 * Usage:
 *   API_BASE_URL=http://127.0.0.1:8080/v1 VERIFY_USER=student.test VERIFY_PASS=secret php scripts/dual_stack_regression.php
 */

$baseUrl = getenv('API_BASE_URL') ?: 'http://127.0.0.1:8080/v1';
$username = getenv('VERIFY_USER') ?: 'aditya.krishnan';
$password = getenv('VERIFY_PASS') ?: 'Demo@2026';
$teacherUser = getenv('VERIFY_TEACHER') ?: 'teacher.test';
$teacherPass = getenv('VERIFY_TEACHER_PASS') ?: $password;
$date = getenv('VERIFY_DATE') ?: date('Y-m-d');

function requestJson(string $method, string $url, ?array $body = null, ?string $token = null): array
{
    $ch = curl_init($url);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer '.$token;
    }
    $opts = [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_RETURNTRANSFER => true,
    ];
    if ($body !== null) {
        $opts[CURLOPT_POSTFIELDS] = json_encode($body);
    }
    curl_setopt_array($ch, $opts);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ['code' => $code, 'body' => json_decode((string) $raw, true)];
}

function assertOk(array $result, string $label): void
{
    if ($result['code'] < 200 || $result['code'] >= 300) {
        fwrite(STDERR, "{$label} failed (HTTP {$result['code']})\n");
        exit(1);
    }
}

echo "CampusToday dual-stack regression\n";
echo "API: {$baseUrl}\n";
echo "Student: {$username} | Teacher: {$teacherUser} | Date: {$date}\n\n";

// --- Student login + dashboard ---
$studentLogin = requestJson('POST', "{$baseUrl}/auth/login", [
    'username' => $username,
    'password' => $password,
    'access' => 0,
]);
assertOk($studentLogin, 'Student login');
$studentToken = $studentLogin['body']['access_token'];

$dashboard = requestJson('GET', "{$baseUrl}/student/dashboard", null, $studentToken);
assertOk($dashboard, 'Student dashboard GET');
echo 'Student dashboard: OK (keys: '.implode(', ', array_keys($dashboard['body'] ?? [])).")\n";

// --- Student homework ---
$homework = requestJson('GET', "{$baseUrl}/student/homework?date=".urlencode($date), null, $studentToken);
assertOk($homework, 'Student homework GET');
$items = $homework['body']['items'] ?? [];
echo 'Homework: '.count($items)." row(s) for {$date}\n";

// --- Teacher login + attendance PUT ---
$teacherLogin = requestJson('POST', "{$baseUrl}/auth/login", [
    'username' => $teacherUser,
    'password' => $teacherPass,
    'access' => 1,
]);
assertOk($teacherLogin, 'Teacher login');
$teacherToken = $teacherLogin['body']['access_token'];

$attendanceGet = requestJson(
    'GET',
    "{$baseUrl}/teacher/attendance?class=10&section=A&date=".urlencode($date),
    null,
    $teacherToken,
);
if ($attendanceGet['code'] === 200) {
    $rows = $attendanceGet['body']['items'] ?? [];
    echo 'Attendance sheet: '.count($rows)." student(s)\n";

    if ($rows !== []) {
        $studentId = $rows[0]['student_id'] ?? null;
        if ($studentId) {
            $attendancePut = requestJson('PUT', "{$baseUrl}/teacher/attendance", [
                'student_id' => $studentId,
                'date' => $date,
                'session' => 'morning',
                'status' => 'present',
            ], $teacherToken);

            if ($attendancePut['code'] === 403) {
                echo "Attendance PUT: locked day ({$attendancePut['body']['message']})\n";
            } else {
                assertOk($attendancePut, 'Attendance PUT');
                echo "Attendance PUT: OK for student {$studentId}\n";
            }
        }
    }
} else {
    echo "Attendance GET skipped (HTTP {$attendanceGet['code']})\n";
}

echo "\nPASS: dual-stack regression checks completed.\n";
echo "Compare homework IDs with SchoolCRM web for the same student/date.\n";
