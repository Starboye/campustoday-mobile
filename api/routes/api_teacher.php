<?php

use App\Http\Middleware\JwtAuthenticate;
use Illuminate\Support\Facades\Route;

Route::middleware([JwtAuthenticate::class.':1'])->prefix('teacher')->group(function () {
    // TeacherAPI-Agent: add dashboard, allocations, attendance, homework, marks, announcements, students, timetables routes here
});
