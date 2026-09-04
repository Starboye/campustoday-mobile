<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\HandlesSchema;
use App\Http\Controllers\Controller;
use App\Services\Admin\CursorPaginator;

abstract class AdminController extends Controller
{
    use HandlesSchema;

    public function __construct(protected readonly CursorPaginator $cursor) {}
}
