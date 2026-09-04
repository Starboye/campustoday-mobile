<?php

namespace App\Http\Controllers\Admin;

use App\Services\Admin\BulkImportService;
use App\Services\Admin\CursorPaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BulkController extends AdminController
{
    public function __construct(
        CursorPaginator $cursor,
        private readonly BulkImportService $bulk,
    ) {
        parent::__construct($cursor);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'type' => ['required', 'string', 'in:students,marks,attendance'],
            'file' => ['required', 'file', 'mimes:csv,txt', 'max:5120'],
        ]);

        $file = $request->file('file');
        if (! $file) {
            return response()->json(['message' => 'CSV file required.'], 422);
        }

        $result = $this->bulk->import(
            $request->input('type'),
            $file->getRealPath()
        );

        if (isset($result['code']) && $result['code'] === 'schema_missing') {
            return response()->json($result, 501);
        }

        return response()->json($result);
    }
}
