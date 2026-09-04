<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Student\Concerns\InteractsWithStudentSchema;
use App\Models\StudentInfo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeesController extends Controller
{
    use InteractsWithStudentSchema;

    public function index(Request $request): JsonResponse
    {
        if (! Schema::hasTable('fee_structures')) {
            return $this->schemaMissingResponse();
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);

        if (! $student || $student->standard === null || $student->section === null) {
            return response()->json(['academic_year' => $this->currentAcademicYear(), 'items' => []]);
        }

        $academicYear = $this->currentAcademicYear();

        $query = DB::table('fee_structures as fs')
            ->where('fs.standard', $student->standard)
            ->where('fs.section', $student->section)
            ->where('fs.academic_year', $academicYear)
            ->orderBy('fs.term_label');

        if (Schema::hasTable('student_fee_status')) {
            $query->leftJoin('student_fee_status as sfs', function ($join) use ($auth) {
                $join->on('sfs.fee_structure_id', '=', 'fs.id')
                    ->where('sfs.student_id', '=', $auth['id']);
            })->select([
                'fs.id as fee_structure_id',
                'fs.term_label',
                'fs.term_fee',
                'fs.special_fee',
                'fs.tuition_fee',
                'fs.lab_fee',
                'fs.total_fee',
                'fs.academic_year',
                DB::raw('COALESCE(sfs.status, "unpaid") as payment_status'),
                DB::raw('COALESCE(sfs.amount_paid, 0) as amount_paid'),
                'sfs.paid_on',
            ]);
        } else {
            $query->select([
                'fs.id as fee_structure_id',
                'fs.term_label',
                'fs.term_fee',
                'fs.special_fee',
                'fs.tuition_fee',
                'fs.lab_fee',
                'fs.total_fee',
                'fs.academic_year',
            ]);
        }

        $items = $query->get()->map(function ($row) {
            $status = (string) ($row->payment_status ?? 'unpaid');

            return [
                'fee_structure_id' => (int) $row->fee_structure_id,
                'term_label' => (string) $row->term_label,
                'term_fee' => (float) $row->term_fee,
                'special_fee' => (float) $row->special_fee,
                'tuition_fee' => (float) $row->tuition_fee,
                'lab_fee' => (float) $row->lab_fee,
                'total_fee' => (float) $row->total_fee,
                'payment_status' => $status,
                'amount_paid' => (float) ($row->amount_paid ?? 0),
                'paid_on' => $row->paid_on ?? null,
            ];
        })->values();

        return response()->json([
            'academic_year' => $academicYear,
            'items' => $items,
        ]);
    }
}
