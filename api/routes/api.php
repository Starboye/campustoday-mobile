<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\MeController;
use App\Http\Controllers\Student\HomeworkController;
use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::get('/health', [HealthController::class, 'show']);

Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/refresh', [AuthController::class, 'refresh']);
    Route::post('/logout', [AuthController::class, 'logout']);
});

Route::middleware(JwtAuthenticate::class)->group(function () {
    Route::get('/me', [MeController::class, 'show']);
    Route::put('/me/device', [MeController::class, 'updateDevice']);
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);

    Route::middleware(JwtAuthenticate::class.':0')->prefix('student')->group(function () {
        Route::get('/homework', [HomeworkController::class, 'index']);
    });
});
