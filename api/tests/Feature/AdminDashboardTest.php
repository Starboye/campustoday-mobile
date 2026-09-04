<?php

namespace Tests\Feature;

use App\Models\UserLogin;
use App\Services\JwtService;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    public function test_dashboard_requires_authentication(): void
    {
        $response = $this->getJson('/v1/admin/dashboard');

        $response->assertStatus(401)
            ->assertJson(['message' => 'Unauthenticated.']);
    }

    public function test_dashboard_rejects_teacher_token(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 1),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/dashboard');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_dashboard_rejects_student_token(): void
    {
        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/dashboard');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_dashboard_returns_kpis_for_admin(): void
    {
        if (! $this->hasLegacyTables()) {
            $this->markTestSkipped('MariaDB admin tables not available in test DB.');
        }

        $token = app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 2),
            [],
        );

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/dashboard');

        $response->assertOk()
            ->assertJsonStructure(['kpis', 'pending_approvals']);
    }

    private function fakeUser(int $access): UserLogin
    {
        $user = new UserLogin;
        $user->id = 'test-admin-1';
        $user->name = 'Test Admin';
        $user->access = $access;

        return $user;
    }

    private function hasLegacyTables(): bool
    {
        if (! $this->hasTestDatabase()) {
            return false;
        }

        try {
            return \Illuminate\Support\Facades\Schema::hasTable('user_login');
        } catch (\Throwable) {
            return false;
        }
    }

    private function hasTestDatabase(): bool
    {
        return in_array('sqlite', \PDO::getAvailableDrivers(), true);
    }
}
