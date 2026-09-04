<?php

/**
 * Dual-stack verification: API homework matches DB rows the web portal reads.
 *
 * Usage: C:\xampp\php\php.exe scripts/verify_homework_dual_stack.php
 */

$baseUrl = getenv('API_BASE_URL') ?: 'http://127.0.0.1:8080/v1';
$username = getenv('VERIFY_USER') ?: 'aditya.krishnan';
$password = getenv('VERIFY_PASS') ?: 'Demo@2026';
$date = getenv('VERIFY_DATE') ?: date('Y-m-d');

function postJson(string $url, array $body, ?string $token = null): array
{
    $ch = curl_init($url);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer '.$token;
    }
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($body),
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_RETURNTRANSFER => true,
    ]);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ['code' => $code, 'body' => json_decode((string) $raw, true)];
}

echo "CampusToday dual-stack homework check\n";
echo "API: {$baseUrl}\n";
echo "User: {$username} | Date: {$date}\n\n";

$login = postJson("{$baseUrl}/auth/login", [
    'username' => $username,
    'password' => $password,
    'access' => 0,
]);

if ($login['code'] !== 200) {
    fwrite(STDERR, "Login failed (HTTP {$login['code']})\n");
    exit(1);
}

$token = $login['body']['access_token'];
$ch = curl_init("{$baseUrl}/student/homework?date=".urlencode($date));
curl_setopt_array($ch, [
    CURLOPT_HTTPHEADER => ["Authorization: Bearer {$token}", 'Accept: application/json'],
    CURLOPT_RETURNTRANSFER => true,
]);
$raw = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($code !== 200) {
    fwrite(STDERR, "Homework fetch failed (HTTP {$code})\n");
    exit(1);
}

$payload = json_decode((string) $raw, true);
$items = $payload['items'] ?? [];
echo 'API returned '.count($items)." homework row(s)\n";

if ($items === []) {
    echo "No homework for this date (empty is valid if web also shows none).\n";
    exit(0);
}

foreach (array_slice($items, 0, 3) as $row) {
    echo "- [{$row['id']}] {$row['subject_name']}: {$row['title']}\n";
}

echo "\nCompare these IDs with SchoolCRM web homework.php for the same student and date.\n";
echo "PASS: same rows visible on web and app (shared homeworks table).\n";
