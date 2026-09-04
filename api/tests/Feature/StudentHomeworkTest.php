<?php

namespace Tests\Feature;

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
        $response = $this->withHeader('Authorization', 'Bearer '.$this->studentToken())
            ->getJson('/v1/student/homework');

        $response->assertOk()
            ->assertJsonStructure(['date', 'items']);
    }

    public function test_homework_rejects_teacher_token(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->teacherToken())
            ->getJson('/v1/student/homework');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_homework_rejects_invalid_date_format(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->studentToken())
            ->getJson('/v1/student/homework?date=not-a-date');

        $response->assertStatus(422)
            ->assertJson(['message' => 'Invalid date format. Use YYYY-MM-DD.']);
    }

    public function test_homework_returns_items_for_student(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->studentToken())
            ->getJson('/v1/student/homework?date=2026-09-04');

        $response->assertOk()
            ->assertJsonStructure(['date', 'items'])
            ->assertJson(['date' => '2026-09-04']);

        $this->assertNotEmpty($response->json('items'));
    }
}
