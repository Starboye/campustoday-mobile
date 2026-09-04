<?php

namespace App\Http\Controllers\Admin\Concerns;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Schema;

trait HandlesSchema
{
    /** @param list<string> $tables */
    protected function requireTables(array $tables): ?JsonResponse
    {
        foreach ($tables as $table) {
            if (! Schema::hasTable($table)) {
                return response()->json(['code' => 'schema_missing'], 501);
            }
        }

        return null;
    }
}
