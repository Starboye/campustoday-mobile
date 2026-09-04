<?php

namespace Tests\Feature;

use App\Models\UserLogin;
use App\Services\JwtService;
use Tests\TestCase;

class StudentHomeworkTest extends TestCase
{
    public function test_homework_requires_authentication(): void
    {
        $response = $this->getJson('/v1/student/homework');

        $response->assertStatus(401)
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    public function test_homework_accepts_default_date_query(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0),
            [],
        );

        if (! $this->hasLegacyStudentTable()) {
            $this->markTestSkipped('MariaDB `student_info` table not available in test DB.');
        }

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/student/homework');

        $response->assertOk()
            ->assertJsonStructure(['date', 'items']);
    }

    public function test_homework_rejects_teacher_token(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 1),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/student/homework');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_homework_rejects_invalid_date_format(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/student/homework?date=not-a-date');

        $response->assertStatus(422)
            ->assertJson(['message' => 'Invalid date format. Use YYYY-MM-DD.']);
    }

    public function test_homework_returns_payload_for_student_without_profile(): void
    {
        if (! $this->hasLegacyStudentTable()) {
            $this->markTestSkipped('MariaDB `student_info` table not available in test DB.');
        }

        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/student/homework?date=2026-09-04');

        $response->assertOk()
            ->assertJsonStructure(['date', 'items'])
            ->assertJson(['date' => '2026-09-04']);
    }

    private function fakeUser(int $access): UserLogin
    {
        $user = new UserLogin;
        $user->id = 'test-user-1';
        $user->name = 'Test User';
        $user->access = $access;

        return $user;
    }

    private function hasLegacyStudentTable(): bool
    {
        try {
            return \Illuminate\Support\Facades\Schema::hasTable('student_info');
        } catch (\Throwable) {
            return false;
        }
    }
}
