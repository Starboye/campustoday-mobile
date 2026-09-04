<?php

use App\Http\Controllers\Student\HomeworkController;
use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':0'])->prefix('student')->group(function () {
    Route::get('/homework', [HomeworkController::class, 'index']);
    // StudentAPI-Agent: add dashboard, announcements, timetable, fees, report-card routes here
});
