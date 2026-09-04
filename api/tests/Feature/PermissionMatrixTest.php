<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PermissionMatrixTest extends TestCase
{
    /**
     * @return array<string, array{method: string, path: string, permission: string, body?: array}>
     */
    public static function protectedAdminRoutes(): array
    {
        return [
            'students list' => ['method' => 'GET', 'path' => '/v1/admin/students', 'permission' => 'can_manage_users'],
            'teachers list' => ['method' => 'GET', 'path' => '/v1/admin/teachers', 'permission' => 'can_manage_users'],
            'approvals list' => ['method' => 'GET', 'path' => '/v1/admin/approvals', 'permission' => 'can_manage_users'],
            'attendance list' => ['method' => 'GET', 'path' => '/v1/admin/attendance', 'permission' => 'can_delete_attendance'],
            'attendance locks alias' => ['method' => 'GET', 'path' => '/v1/admin/attendance-locks', 'permission' => 'can_delete_attendance'],
            'marks alias' => ['method' => 'GET', 'path' => '/v1/admin/marks', 'permission' => 'can_edit_marks'],
            'fees structures' => ['method' => 'GET', 'path' => '/v1/admin/fees/structures', 'permission' => 'can_manage_fees'],
            'fees payments alias' => ['method' => 'GET', 'path' => '/v1/admin/fees/payments', 'permission' => 'can_manage_fees'],
            'planner slots' => ['method' => 'GET', 'path' => '/v1/admin/planner/slots', 'permission' => 'can_manage_planner'],
            'notifications templates' => ['method' => 'GET', 'path' => '/v1/admin/notifications/templates', 'permission' => 'can_manage_notifications'],
            'exams list' => ['method' => 'GET', 'path' => '/v1/admin/exams', 'permission' => 'can_manage_exams'],
            'analytics' => ['method' => 'GET', 'path' => '/v1/admin/analytics', 'permission' => 'can_view_analytics'],
            'security audit' => ['method' => 'GET', 'path' => '/v1/admin/security/login-audit', 'permission' => 'can_manage_security'],
            'rbac roles' => ['method' => 'GET', 'path' => '/v1/admin/rbac/roles', 'permission' => 'can_manage_delegation'],
            'data quality' => ['method' => 'GET', 'path' => '/v1/admin/data-quality', 'permission' => 'can_manage_data_quality'],
        ];
    }

    /**
     * @dataProvider protectedAdminRoutes
     */
    public function test_admin_route_returns_403_without_permission(
        string $method,
        string $path,
        string $permission,
    ): void {
        $otherPermissions = array_values(array_diff(
            array_column(self::protectedAdminRoutes(), 'permission'),
            [$permission],
        ));

        $token = $this->adminToken($otherPermissions);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->json($method, $path);

        $response->assertStatus(403)
            ->assertJson(['code' => 'permission_denied']);
    }

    /**
     * @dataProvider protectedAdminRoutes
     */
    public function test_admin_route_returns_success_with_permission(
        string $method,
        string $path,
        string $permission,
    ): void {
        if ($path === '/v1/admin/data-quality') {
            DB::table('data_quality_issues')->insert([
                'issue' => 'Missing email',
                'entity_type' => 'student',
                'entity_id' => 'student-1',
                'status' => 'open',
            ]);
        }

        $token = $this->adminToken([$permission]);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->json($method, $path);

        $this->assertContains($response->status(), [200, 201]);
    }

    public function test_dashboard_accessible_without_specific_permission(): void
    {
        $token = $this->adminToken(['can_view_analytics']);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/dashboard');

        $response->assertOk();
    }

    public function test_limited_admin_from_database_has_restricted_permissions(): void
    {
        $login = $this->postJson('/v1/auth/login', [
            'username' => 'admin.limited',
            'password' => 'secret',
            'access' => 2,
        ]);

        $login->assertOk();
        $token = $login->json('access_token');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/analytics')
            ->assertOk();

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/v1/admin/students')
            ->assertStatus(403)
            ->assertJson(['code' => 'permission_denied']);
    }
}
