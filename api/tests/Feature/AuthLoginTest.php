<?php

namespace Tests\Feature;

use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    public function test_health_endpoint_returns_ok(): void
    {
        $response = $this->getJson('/v1/health');

        $response->assertJsonStructure(['status', 'service', 'database', 'timestamp'])
            ->assertJson(['service' => 'CampusToday API']);

        $this->assertContains($response->status(), [200, 503]);
    }

    public function test_login_rejects_invalid_access_value(): void
    {
        $response = $this->postJson('/v1/auth/login', [
            'username' => 'student',
            'password' => 'secret',
            'access' => 99,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['access']);
    }

    public function test_login_requires_credentials(): void
    {
        $response = $this->postJson('/v1/auth/login', []);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['username', 'password', 'access']);
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        $response = $this->postJson('/v1/auth/login', [
            'username' => 'nonexistent.user',
            'password' => 'wrong-password',
            'access' => 0,
        ]);

        $response->assertStatus(401)
            ->assertJson(['message' => 'Invalid credentials.']);
    }

    public function test_login_succeeds_with_valid_credentials(): void
    {
        $response = $this->postJson('/v1/auth/login', [
            'username' => 'student.test',
            'password' => 'secret',
            'access' => 0,
        ]);

        $response->assertOk()
            ->assertJsonStructure(['access_token', 'refresh_token', 'user']);
    }

    public function test_refresh_requires_refresh_token(): void
    {
        $response = $this->postJson('/v1/auth/refresh', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['refresh_token']);
    }
}
