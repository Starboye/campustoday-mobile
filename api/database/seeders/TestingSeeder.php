<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class TestingSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make('secret');

        DB::table('user_login')->insert([
            ['id' => 'student-1', 'name' => 'student.test', 'password' => $password, 'access' => 0],
            ['id' => 'teacher-1', 'name' => 'teacher.test', 'password' => $password, 'access' => 1],
            ['id' => 'admin-1', 'name' => 'admin.test', 'password' => $password, 'access' => 2],
            ['id' => 'admin-limited', 'name' => 'admin.limited', 'password' => $password, 'access' => 2],
        ]);

        DB::table('student_info')->insert([
            'id' => 'student-1',
            'name' => 'Test Student',
            'standard' => 10,
            'section' => 'A',
            'admission_no' => 'ADM001',
            'status' => 'active',
        ]);

        DB::table('homeworks')->insert([
            'subject_name' => 'Mathematics',
            'teacher_id' => 'teacher-1',
            'standard' => 10,
            'section' => 'A',
            'date' => '2026-09-04',
            'title' => 'Chapter 5 exercises',
            'description' => 'Complete problems 1-10',
            'target_type' => 'class',
            'student_id' => null,
        ]);

        DB::table('teacher_subject_allocation')->insert([
            'teacher_id' => 'teacher-1',
            'standard' => 10,
            'section' => 'A',
            'subject_name' => 'Mathematics',
            'is_class_teacher' => true,
        ]);

        $permissionKeys = [
            'can_manage_users',
            'can_delete_attendance',
            'can_edit_marks',
            'can_manage_fees',
            'can_manage_planner',
            'can_manage_notifications',
            'can_manage_exams',
            'can_view_analytics',
            'can_manage_security',
            'can_manage_delegation',
            'can_manage_data_quality',
        ];

        foreach ($permissionKeys as $key) {
            DB::table('permissions')->insert(['permission_key' => $key]);
        }

        DB::table('roles')->insert(['id' => 1, 'name' => 'Limited Admin']);
        DB::table('role_permissions')->insert([
            ['role_id' => 1, 'permission_key' => 'can_view_analytics'],
        ]);
        DB::table('user_roles')->insert([
            'user_id' => 'admin-limited',
            'role_id' => 1,
        ]);

        DB::table('approval_requests')->insert([
            'request_type' => 'timetable',
            'entity_id' => '1',
            'status' => 'pending',
            'requested_by' => 'teacher-1',
            'created_at' => now(),
        ]);

        DB::table('marks_new')->insert([
            'student_id' => 'student-1',
            'subject_name' => 'Mathematics',
            'marks' => 85,
            'term' => 'Term 1',
        ]);

        DB::table('fee_structures')->insert([
            'term' => 'Term 1',
            'amount' => 5000,
            'description' => 'Tuition',
        ]);

        DB::table('student_fee_status')->insert([
            'student_id' => 'student-1',
            'term' => 'Term 1',
            'fee_structure_id' => 1,
            'status' => 'unpaid',
            'amount_paid' => 0,
        ]);
    }
}
