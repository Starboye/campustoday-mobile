<?php

namespace Tests\Feature;

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
        $response = $this->withHeader('Authorization', 'Bearer '.$this->studentToken())
            ->getJson('/v1/teacher/attendance?class=10&section=A&date=2026-09-04');

        $response->assertStatus(403)
            ->assertJson(['message' => 'Forbidden.']);
    }

    public function test_attendance_validates_query_parameters(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->teacherToken())
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

    public function test_attendance_index_returns_payload_for_allocated_class(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->teacherToken())
            ->getJson('/v1/teacher/attendance?class=10&section=A&date=2026-09-04');

        $response->assertOk()
            ->assertJsonStructure(['date', 'standard', 'section', 'items']);
    }

    public function test_attendance_update_saves_record(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer '.$this->teacherToken())
            ->putJson('/v1/teacher/attendance', [
                'student_id' => 'student-1',
                'date' => '2026-09-04',
                'session' => 'morning',
                'status' => 'present',
            ]);

        $response->assertOk()
            ->assertJson(['message' => 'Attendance updated.']);
    }
}
