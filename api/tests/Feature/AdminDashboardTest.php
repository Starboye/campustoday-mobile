<?php

namespace Tests\Feature;

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
        $response = $this->withHeader('Authorization', 'Bearer '.$this->teacherToken())
            ->getJson('/v1/admin/dashboard');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_dashboard_rejects_student_token(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->studentToken())
            ->getJson('/v1/admin/dashboard');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_dashboard_returns_kpis_for_admin(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->adminToken())
            ->getJson('/v1/admin/dashboard');

        $response->assertOk()
            ->assertJsonStructure(['kpis', 'pending_approvals']);
    }
}
