<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeesController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');

        if (! Schema::hasTable('fee_structures')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $structures = DB::table('fee_structures')
            ->orderBy('term')
            ->get();

        $statusMap = [];
        if (Schema::hasTable('student_fee_status')) {
            $statusMap = DB::table('student_fee_status')
                ->where('student_id', $auth['id'])
                ->get()
                ->keyBy(fn ($row) => $row->term ?? $row->fee_structure_id ?? $row->id);
        }

        $items = $structures->map(function ($fee) use ($statusMap, $auth) {
            $key = $fee->term ?? $fee->id;
            $status = $statusMap[$key] ?? null;

            return [
                'term' => $fee->term ?? null,
                'structure_id' => (int) $fee->id,
                'amount' => $fee->amount ?? $fee->total_amount ?? 0,
                'description' => $fee->description ?? $fee->name ?? null,
                'payment_status' => $status->status ?? $status->payment_status ?? 'unpaid',
                'amount_paid' => $status->amount_paid ?? $status->paid_amount ?? 0,
            ];
        })->values();

        return response()->json(['items' => $items]);
    }
}
