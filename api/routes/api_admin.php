<?php

use App\Http\Controllers\Admin\AnalyticsController;
use App\Http\Controllers\Admin\ApprovalsController;
use App\Http\Controllers\Admin\AttendanceController;
use App\Http\Controllers\Admin\AttendanceLockController;
use App\Http\Controllers\Admin\BulkController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\DataQualityController;
use App\Http\Controllers\Admin\ExamsController;
use App\Http\Controllers\Admin\FeesController;
use App\Http\Controllers\Admin\HomeworkController;
use App\Http\Controllers\Admin\MarksController;
use App\Http\Controllers\Admin\NotificationsController;
use App\Http\Controllers\Admin\PlannerController;
use App\Http\Controllers\Admin\RbacController;
use App\Http\Controllers\Admin\SecurityController;
use App\Http\Controllers\Admin\StudentsController;
use App\Http\Controllers\Admin\TeachersController;
use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':2'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'show']);

    Route::middleware('permission:can_manage_users')->group(function () {
        Route::get('/students', [StudentsController::class, 'index']);
        Route::post('/students', [StudentsController::class, 'store']);
        Route::put('/students/{id}', [StudentsController::class, 'update']);

        Route::get('/teachers', [TeachersController::class, 'index']);
        Route::post('/teachers', [TeachersController::class, 'store']);
        Route::put('/teachers/{id}', [TeachersController::class, 'update']);

        Route::get('/homework', [HomeworkController::class, 'index']);
        Route::delete('/homework/{id}', [HomeworkController::class, 'destroy']);

        Route::get('/approvals', [ApprovalsController::class, 'index']);
        Route::post('/approvals/{id}/approve', [ApprovalsController::class, 'approve']);
        Route::post('/approvals/{id}/reject', [ApprovalsController::class, 'reject']);

        Route::post('/bulk', [BulkController::class, 'store']);
    });

    Route::middleware('permission:can_delete_attendance')->group(function () {
        Route::get('/attendance', [AttendanceController::class, 'index']);
        Route::delete('/attendance/{id}', [AttendanceController::class, 'destroy']);

        Route::get('/attendance/locks', [AttendanceLockController::class, 'index']);
        Route::post('/attendance/locks', [AttendanceLockController::class, 'store']);
        Route::delete('/attendance/locks/{id}', [AttendanceLockController::class, 'destroy']);
    });

    Route::middleware('permission:can_edit_marks')->group(function () {
        Route::get('/marks-new', [MarksController::class, 'index']);
        Route::put('/marks-new/{id}', [MarksController::class, 'update']);
    });

    Route::middleware('permission:can_manage_fees')->group(function () {
        Route::get('/fees/structures', [FeesController::class, 'listStructures']);
        Route::post('/fees/structures', [FeesController::class, 'storeStructure']);
        Route::put('/fees/structures/{id}', [FeesController::class, 'updateStructure']);
        Route::delete('/fees/structures/{id}', [FeesController::class, 'destroyStructure']);

        Route::get('/fees/status', [FeesController::class, 'listStatus']);
        Route::put('/fees/status/{id}', [FeesController::class, 'updateStatus']);
    });

    Route::middleware('permission:can_manage_planner')->group(function () {
        Route::get('/planner/assignments', [PlannerController::class, 'listAssignments']);
        Route::post('/planner/assignments', [PlannerController::class, 'storeAssignment']);
        Route::put('/planner/assignments/{id}', [PlannerController::class, 'updateAssignment']);
        Route::delete('/planner/assignments/{id}', [PlannerController::class, 'destroyAssignment']);

        Route::get('/planner/slots', [PlannerController::class, 'listSlots']);
        Route::post('/planner/slots', [PlannerController::class, 'storeSlot']);
        Route::put('/planner/slots/{id}', [PlannerController::class, 'updateSlot']);
        Route::delete('/planner/slots/{id}', [PlannerController::class, 'destroySlot']);

        Route::get('/planner/timetables', [PlannerController::class, 'listTimetables']);
        Route::post('/planner/timetables', [PlannerController::class, 'storeTimetable']);
        Route::post('/planner/timetables/{id}/approve', [PlannerController::class, 'approveTimetable']);
    });

    Route::middleware('permission:can_manage_notifications')->group(function () {
        Route::get('/notifications/templates', [NotificationsController::class, 'listTemplates']);
        Route::post('/notifications/templates', [NotificationsController::class, 'storeTemplate']);
        Route::get('/notifications/schedules', [NotificationsController::class, 'listSchedules']);
        Route::post('/notifications/schedules', [NotificationsController::class, 'storeSchedule']);
        Route::post('/notifications/send', [NotificationsController::class, 'send']);
    });

    Route::middleware('permission:can_manage_exams')->group(function () {
        Route::get('/exams', [ExamsController::class, 'index']);
        Route::post('/exams', [ExamsController::class, 'store']);
        Route::put('/exams/{id}', [ExamsController::class, 'update']);
        Route::delete('/exams/{id}', [ExamsController::class, 'destroy']);
    });

    Route::middleware('permission:can_view_analytics')->group(function () {
        Route::get('/analytics', [AnalyticsController::class, 'show']);
    });

    Route::middleware('permission:can_manage_security')->group(function () {
        Route::get('/security/login-audit', [SecurityController::class, 'loginAudit']);
        Route::put('/security/users/{id}', [SecurityController::class, 'updateUser']);
    });

    Route::middleware('permission:can_manage_delegation')->group(function () {
        Route::get('/rbac/roles', [RbacController::class, 'listRoles']);
        Route::put('/rbac/users/{id}/roles', [RbacController::class, 'updateUserRoles']);
    });

    Route::middleware('permission:can_manage_data_quality')->group(function () {
        Route::get('/data-quality', [DataQualityController::class, 'index']);
        Route::put('/data-quality/{id}', [DataQualityController::class, 'update']);
    });
});
