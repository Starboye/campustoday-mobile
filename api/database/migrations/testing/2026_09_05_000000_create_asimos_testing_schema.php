<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Minimal asimos-like schema for PHPUnit in-memory SQLite.
 * Not used in production — MariaDB tables come from SchoolCRM.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_login', function (Blueprint $table) {
            $table->string('id', 20)->primary();
            $table->string('name', 100)->unique();
            $table->string('password', 255);
            $table->unsignedTinyInteger('access')->default(0);
        });

        Schema::create('student_info', function (Blueprint $table) {
            $table->string('id', 20)->primary();
            $table->string('name', 150)->nullable();
            $table->unsignedTinyInteger('standard')->nullable();
            $table->string('section', 10)->nullable();
            $table->string('admission_no', 50)->nullable();
            $table->string('email', 150)->nullable();
            $table->string('phone', 30)->nullable();
            $table->string('status', 30)->nullable();
        });

        Schema::create('homeworks', function (Blueprint $table) {
            $table->increments('id');
            $table->string('subject_name', 100);
            $table->string('teacher_id', 20);
            $table->unsignedTinyInteger('standard');
            $table->string('section', 10);
            $table->date('date');
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->string('target_type', 20)->default('class');
            $table->string('student_id', 20)->nullable();
        });

        Schema::create('attendance', function (Blueprint $table) {
            $table->increments('id');
            $table->string('student_id', 20);
            $table->date('date');
            $table->string('morning', 20)->nullable();
            $table->string('afternoon', 20)->nullable();
            $table->string('evening', 20)->nullable();
            $table->unique(['student_id', 'date']);
        });

        Schema::create('attendance_day_lock', function (Blueprint $table) {
            $table->increments('id');
            $table->date('date');
            $table->unsignedTinyInteger('standard')->nullable();
            $table->string('section', 10)->nullable();
            $table->boolean('locked')->default(true);
        });

        Schema::create('marks', function (Blueprint $table) {
            $table->increments('id');
            $table->string('student_id', 20);
            $table->string('subject_name', 100);
            $table->string('marks', 20);
            $table->unsignedTinyInteger('term')->nullable();
            $table->string('exam_type', 50)->nullable();
            $table->string('grade', 10)->nullable();
            $table->string('max_marks', 20)->nullable();
        });

        Schema::create('marks_new', function (Blueprint $table) {
            $table->increments('id');
            $table->string('student_id', 20);
            $table->string('subject_name', 100);
            $table->decimal('marks', 8, 2)->default(0);
            $table->string('term', 50)->nullable();
            $table->string('grade', 10)->nullable();
            $table->string('exam_type', 50)->nullable();
        });

        Schema::create('approval_requests', function (Blueprint $table) {
            $table->increments('id');
            $table->string('request_type', 50);
            $table->string('entity_id', 50)->nullable();
            $table->string('status', 30)->default('pending');
            $table->string('requested_by', 20)->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('roles', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name', 100);
        });

        Schema::create('permissions', function (Blueprint $table) {
            $table->string('permission_key', 80)->primary();
        });

        Schema::create('role_permissions', function (Blueprint $table) {
            $table->unsignedInteger('role_id');
            $table->string('permission_key', 80);
            $table->primary(['role_id', 'permission_key']);
        });

        Schema::create('user_roles', function (Blueprint $table) {
            $table->string('user_id', 20);
            $table->unsignedInteger('role_id');
            $table->primary(['user_id', 'role_id']);
        });

        Schema::create('teacher_subject_allocation', function (Blueprint $table) {
            $table->increments('id');
            $table->string('teacher_id', 20);
            $table->unsignedTinyInteger('standard');
            $table->string('section', 10);
            $table->string('subject_name', 100);
            $table->boolean('is_class_teacher')->default(false);
        });

        Schema::create('fee_structures', function (Blueprint $table) {
            $table->increments('id');
            $table->string('term', 50);
            $table->decimal('amount', 10, 2)->default(0);
            $table->string('description', 255)->nullable();
        });

        Schema::create('student_fee_status', function (Blueprint $table) {
            $table->increments('id');
            $table->string('student_id', 20);
            $table->string('term', 50)->nullable();
            $table->unsignedInteger('fee_structure_id')->nullable();
            $table->string('status', 30)->default('unpaid');
            $table->decimal('amount_paid', 10, 2)->default(0);
        });

        Schema::create('notification', function (Blueprint $table) {
            $table->increments('id');
            $table->string('title', 255)->nullable();
            $table->text('message')->nullable();
            $table->string('target_id', 20)->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('notification_templates', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name', 100);
            $table->string('title', 200)->nullable();
            $table->text('message')->nullable();
            $table->string('channel', 50)->default('push');
        });

        Schema::create('login_audit', function (Blueprint $table) {
            $table->increments('id');
            $table->string('user_id', 20)->nullable();
            $table->string('username', 100)->nullable();
            $table->string('status', 30)->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('assignments', function (Blueprint $table) {
            $table->increments('id');
            $table->string('subject', 100)->nullable();
            $table->string('teacher_id', 20)->nullable();
            $table->unsignedTinyInteger('standard')->nullable();
            $table->string('section', 10)->nullable();
        });

        Schema::create('slots', function (Blueprint $table) {
            $table->increments('id');
            $table->string('day', 20)->nullable();
            $table->unsignedTinyInteger('period')->nullable();
            $table->string('class_name', 50)->nullable();
        });

        Schema::create('class_timetables', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedTinyInteger('standard')->nullable();
            $table->string('section', 10)->nullable();
            $table->string('status', 30)->default('draft');
            $table->string('class_teacher_id', 20)->nullable();
        });

        Schema::create('exam_windows', function (Blueprint $table) {
            $table->increments('id');
            $table->string('name', 150);
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
        });

        Schema::create('data_quality_issues', function (Blueprint $table) {
            $table->increments('id');
            $table->string('issue', 255);
            $table->string('entity_type', 50)->nullable();
            $table->string('entity_id', 50)->nullable();
            $table->string('status', 30)->default('open');
        });

        Schema::create('api_refresh_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('user_id', 20);
            $table->char('token_hash', 64);
            $table->dateTime('expires_at');
            $table->boolean('revoked')->default(false);
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('api_devices', function (Blueprint $table) {
            $table->id();
            $table->string('user_id', 20);
            $table->string('platform', 10);
            $table->string('fcm_token', 512)->nullable();
            $table->timestamp('updated_at')->nullable();
        });
    }

    public function down(): void
    {
        $tables = [
            'api_devices', 'api_refresh_tokens', 'login_audit', 'notification_templates',
            'data_quality_issues', 'exam_windows',
            'class_timetables', 'slots', 'assignments', 'notification', 'student_fee_status',
            'fee_structures', 'teacher_subject_allocation', 'user_roles', 'role_permissions',
            'permissions', 'roles', 'approval_requests', 'marks_new', 'marks', 'attendance_day_lock',
            'attendance', 'homeworks', 'student_info', 'user_login',
        ];

        foreach ($tables as $table) {
            Schema::dropIfExists($table);
        }
    }
};
