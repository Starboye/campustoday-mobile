<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Student\Concerns\InteractsWithStudentSchema;
use App\Models\StudentInfo;
use Dompdf\Dompdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpFoundation\Response;

class ReportCardController extends Controller
{
    use InteractsWithStudentSchema;

    public function show(Request $request): JsonResponse
    {
        if (! Schema::hasTable('marks_new')) {
            return $this->schemaMissingResponse();
        }

        $auth = $request->attributes->get('auth_user');

        return response()->json([
            'terms' => $this->buildTerms($auth['id']),
        ]);
    }

    public function pdf(Request $request): Response|JsonResponse
    {
        if (! Schema::hasTable('marks_new')) {
            return $this->schemaMissingResponse();
        }

        if (! class_exists(Dompdf::class)) {
            return response()->json([
                'code' => 'pdf_unavailable',
                'message' => 'PDF generation not configured. Install dompdf/dompdf.',
            ], 501);
        }

        $auth = $request->attributes->get('auth_user');
        $student = StudentInfo::query()->find($auth['id']);
        $term = $request->query('term', 'Term 1');

        if (! in_array($term, $this->reportCardTerms(), true)) {
            return response()->json(['message' => 'Invalid term. Use Term 1, Term 2, or Term 3.'], 422);
        }

        $row = DB::table('marks_new')
            ->where('id', $auth['id'])
            ->where('testName', $term)
            ->first();

        $labels = $this->reportCardSubjectLabels();
        $subjects = [];
        $total = 0;
        $perSubjectMax = (int) ($row->totalMarks ?? 100);

        foreach ($this->reportCardSubjects() as $subject) {
            $marks = (int) ($row?->{$subject} ?? 0);
            $subjects[] = [
                'subject_name' => $labels[$subject],
                'marks' => $marks,
                'max_marks' => $perSubjectMax,
            ];
            $total += $marks;
        }

        $maxTotal = $perSubjectMax * count($this->reportCardSubjects());
        $schoolName = htmlspecialchars((string) config('app.name', 'CampusToday'), ENT_QUOTES, 'UTF-8');
        $studentName = htmlspecialchars((string) ($student->name ?? $auth['name']), ENT_QUOTES, 'UTF-8');
        $standard = htmlspecialchars((string) ($student->standard ?? ''), ENT_QUOTES, 'UTF-8');
        $section = htmlspecialchars((string) ($student->section ?? ''), ENT_QUOTES, 'UTF-8');
        $studentId = htmlspecialchars((string) $auth['id'], ENT_QUOTES, 'UTF-8');
        $termLabel = htmlspecialchars($term, ENT_QUOTES, 'UTF-8');

        $html = <<<HTML
<style>
body { font-family: DejaVu Sans, sans-serif; }
table { width: 100%; border-collapse: collapse; }
td, th { border: 1px solid #333; padding: 8px; }
h1, h2, h3 { text-align: center; }
</style>
<h1>{$schoolName}</h1>
<h2>Report Card - {$termLabel}</h2>
<p><strong>Name:</strong> {$studentName}<br>
<strong>Class:</strong> {$standard} - {$section}<br>
<strong>Student ID:</strong> {$studentId}</p>
<h3>Marks</h3>
<table>
<tr><th>Subject</th><th>Marks</th><th>Out of</th></tr>
HTML;

        foreach ($subjects as $subject) {
            $name = htmlspecialchars($subject['subject_name'], ENT_QUOTES, 'UTF-8');
            $html .= '<tr><td>'.$name.'</td><td>'.$subject['marks'].'</td><td>'.$subject['max_marks'].'</td></tr>';
        }

        $html .= '<tr><td><strong>Total</strong></td><td><strong>'.$total.'</strong></td><td><strong>'.$maxTotal.'</strong></td></tr>';
        $html .= '</table><p style="margin-top:50px;">_____________________________<br>Class Teacher Signature</p>';

        $dompdf = new Dompdf;
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        $filename = 'report-card-'.preg_replace('/[^A-Za-z0-9_-]/', '_', $term).'.pdf';

        return response($dompdf->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'inline; filename="'.$filename.'"',
        ]);
    }

    /** @return list<array<string, mixed>> */
    private function buildTerms(string $studentId): array
    {
        $labels = $this->reportCardSubjectLabels();
        $terms = [];

        foreach ($this->reportCardTerms() as $index => $termName) {
            $row = DB::table('marks_new')
                ->where('id', $studentId)
                ->where('testName', $termName)
                ->first();

            $subjects = [];
            foreach ($this->reportCardSubjects() as $subject) {
                $subjects[] = [
                    'subject_key' => $subject,
                    'subject_name' => $labels[$subject],
                    'marks' => (int) ($row?->{$subject} ?? 0),
                    'max_marks' => (int) ($row?->totalMarks ?? 100),
                ];
            }

            $terms[] = [
                'term' => $index + 1,
                'term_label' => $termName,
                'date' => (string) ($row->date ?? ''),
                'grand_total' => (int) ($row->grandTotal ?? array_sum(array_column($subjects, 'marks'))),
                'subjects' => $subjects,
            ];
        }

        return $terms;
    }
}
