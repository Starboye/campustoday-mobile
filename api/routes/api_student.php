<?php

use App\Http\Controllers\Student\AnnouncementsController;
use App\Http\Controllers\Student\DashboardController;
use App\Http\Controllers\Student\FeesController;
use App\Http\Controllers\Student\HomeworkController;
use App\Http\Controllers\Student\ReportCardController;
use App\Http\Controllers\Student\TimetableController;
use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':0'])->prefix('student')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'show']);
    Route::get('/homework', [HomeworkController::class, 'index']);
    Route::get('/announcements', [AnnouncementsController::class, 'index']);
    Route::patch('/announcements/{id}/read', [AnnouncementsController::class, 'markRead']);
    Route::get('/timetable', [TimetableController::class, 'show']);
    Route::get('/fees', [FeesController::class, 'index']);
    Route::get('/report-card', [ReportCardController::class, 'show']);
    Route::get('/report-card.pdf', [ReportCardController::class, 'pdf']);
});
