<?php

use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':2'])->prefix('admin')->group(function () {
    // AdminAPI-Agent: add dashboard, students, teachers, attendance, fees, marks, planner, rbac, etc.
});
