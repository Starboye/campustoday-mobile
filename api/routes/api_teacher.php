<?php

use App\Http\Controllers\Teacher\AllocationsController;
use App\Http\Controllers\Teacher\AnnouncementsController;
use App\Http\Controllers\Teacher\AttendanceController;
use App\Http\Controllers\Teacher\ClassTimetableController;
use App\Http\Controllers\Teacher\DashboardController;
use App\Http\Controllers\Teacher\ExamTimetableController;
use App\Http\Controllers\Teacher\HomeworkController;
use App\Http\Controllers\Teacher\MarksController;
use App\Http\Controllers\Teacher\StudentsController;
use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':1'])->prefix('teacher')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'show']);
    Route::get('/allocations', [AllocationsController::class, 'index']);

    Route::get('/attendance', [AttendanceController::class, 'index']);
    Route::put('/attendance', [AttendanceController::class, 'update']);

    Route::get('/homework', [HomeworkController::class, 'index']);
    Route::post('/homework', [HomeworkController::class, 'store']);
    Route::put('/homework/{id}', [HomeworkController::class, 'update']);
    Route::delete('/homework/{id}', [HomeworkController::class, 'destroy']);

    Route::get('/marks', [MarksController::class, 'index']);
    Route::put('/marks', [MarksController::class, 'update']);

    Route::post('/announcements', [AnnouncementsController::class, 'store']);

    Route::get('/students', [StudentsController::class, 'index']);
    Route::get('/students/{id}', [StudentsController::class, 'show']);

    Route::get('/exam-timetable', [ExamTimetableController::class, 'show']);

    Route::get('/class-timetable', [ClassTimetableController::class, 'show']);
    Route::put('/class-timetable', [ClassTimetableController::class, 'update']);
    Route::post('/class-timetable/submit', [ClassTimetableController::class, 'submit']);
});
