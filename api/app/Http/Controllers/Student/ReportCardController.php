<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ReportCardController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $auth = $request->attributes->get('auth_user');

        if (! Schema::hasTable('marks_new')) {
            return response()->json(['code' => 'schema_missing'], 501);
        }

        $rows = DB::table('marks_new')
            ->where('student_id', $auth['id'])
            ->whereIn('term', [1, 2, 3])
            ->orderBy('term')
            ->orderBy('subject_name')
            ->get(['term', 'subject_name', 'marks', 'grade', 'exam_type']);

        $terms = [];
        foreach ($rows as $row) {
            $term = (int) $row->term;
            $terms[$term]['term'] = $term;
            $terms[$term]['subjects'][] = [
                'subject_name' => $row->subject_name,
                'marks' => $row->marks,
                'grade' => $row->grade ?? null,
                'exam_type' => $row->exam_type ?? null,
            ];
        }

        return response()->json([
            'terms' => array_values($terms),
        ]);
    }

    public function pdf(Request $request)
    {
        $auth = $request->attributes->get('auth_user');

        if (! class_exists(\Dompdf\Dompdf::class)) {
            return response()->json([
                'code' => 'pdf_unavailable',
                'message' => 'PDF generation not configured. Install dompdf/dompdf.',
            ], 501);
        }

        $data = $this->show($request)->getData(true);
        $html = '<html><body><h1>Report Card</h1><p>Student: '.htmlspecialchars($auth['id']).'</p>';
        foreach ($data['terms'] ?? [] as $term) {
            $html .= '<h2>Term '.(int) $term['term'].'</h2><table border="1"><tr><th>Subject</th><th>Marks</th></tr>';
            foreach ($term['subjects'] ?? [] as $sub) {
                $html .= '<tr><td>'.htmlspecialchars($sub['subject_name']).'</td><td>'.htmlspecialchars((string) $sub['marks']).'</td></tr>';
            }
            $html .= '</table>';
        }
        $html .= '</body></html>';

        $dompdf = new \Dompdf\Dompdf;
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4');
        $dompdf->render();

        return response($dompdf->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'inline; filename="report-card-'.$auth['id'].'.pdf"',
        ]);
    }
}
