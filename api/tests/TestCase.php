<?php

namespace Tests;

use App\Models\UserLogin;
use App\Services\JwtService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    protected function migrateFreshUsing()
    {
        return [
            '--drop-views' => $this->shouldDropViews(),
            '--drop-types' => $this->shouldDropTypes(),
            '--path' => 'database/migrations/testing',
            '--seeder' => \Database\Seeders\TestingSeeder::class,
        ];
    }

    protected function fakeUser(int $access, string $id = 'test-user-1', string $name = 'Test User'): UserLogin
    {
        $user = new UserLogin;
        $user->id = $id;
        $user->name = $name;
        $user->access = $access;

        return $user;
    }

    protected function adminToken(array $permissions = [], string $id = 'admin-1'): string
    {
        return app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 2, id: $id, name: 'Test Admin'),
            $permissions,
        );
    }

    protected function teacherToken(string $id = 'teacher-1'): string
    {
        return app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 1, id: $id, name: 'Test Teacher'),
            [],
        );
    }

    protected function studentToken(string $id = 'student-1'): string
    {
        return app(JwtService::class)->issueAccessToken(
            $this->fakeUser(access: 0, id: $id, name: 'Test Student'),
            [],
        );
    }
}
