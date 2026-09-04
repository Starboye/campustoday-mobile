<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Services\TeacherAllocationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AllocationsController extends Controller
{
    public function __construct(private readonly TeacherAllocationService $allocations) {}

    public function index(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');
        $items = $this->allocations
            ->allocations((string) $auth['id'])
            ->map(fn ($row) => $this->allocations->formatAllocation($row))
            ->values();

        return response()->json(['items' => $items]);
    }
}
