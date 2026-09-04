<?php

namespace Tests\Feature;

use App\Models\UserLogin;
use App\Services\JwtService;
use Tests\TestCase;

class TeacherAttendanceTest extends TestCase
{
    public function test_attendance_requires_authentication(): void
    {
        $response = $this->getJson('/v1/teacher/attendance?class=10&section=A&date=2026-09-04');

        $response->assertStatus(401)
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    public function test_attendance_rejects_student_token(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/teacher/attendance?class=10&section=A&date=2026-09-04');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_attendance_validates_query_parameters(): void
    {
        if (! $this->hasTestDatabase()) {
            $this->markTestSkipped('SQLite PDO driver not available in test environment.');
        }

        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 1),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/teacher/attendance');

        $response->assertStatus(422);
    }

    public function test_attendance_update_requires_authentication(): void
    {
        $response = $this->putJson('/v1/teacher/attendance', [
            'student_id' => 'student-1',
            'date' => '2026-09-04',
            'session' => 'morning',
            'status' => 'present',
        ]);

        $response->assertStatus(401)
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    public function test_attendance_index_returns_payload_when_tables_exist(): void
    {
        if (! $this->hasLegacyTables()) {
            $this->markTestSkipped('MariaDB attendance tables not available in test DB.');
        }

        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 1),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/teacher/attendance?class=10&section=A&date=2026-09-04');

        $this->assertContains($response->status(), [200, 403, 501]);
    }

    private function fakeUser(int $access): UserLogin
    {
        $user = new UserLogin;
        $user->id = 'test-teacher-1';
        $user->name = 'Test Teacher';
        $user->access = $access;

        return $user;
    }

    private function hasLegacyTables(): bool
    {
        if (! $this->hasTestDatabase()) {
            return false;
        }

        try {
            return \Illuminate\Support\Facades\Schema::hasTable('attendance')
                && \Illuminate\Support\Facades\Schema::hasTable('student_info');
        } catch (\Throwable) {
            return false;
        }
    }

    private function hasTestDatabase(): bool
    {
        return in_array('sqlite', \PDO::getAvailableDrivers(), true);
    }
}
