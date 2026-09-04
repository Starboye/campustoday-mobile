class ReportTerm {
  const ReportTerm({
    required this.termId,
    required this.termName,
    this.academicYear,
    this.overallGrade,
    this.percentage,
    this.pdfAvailable = false,
  });

  final int termId;
  final String termName;
  final String? academicYear;
  final String? overallGrade;
  final double? percentage;
  final bool pdfAvailable;

  factory ReportTerm.fromJson(Map<String, dynamic> json) {
    return ReportTerm(
      termId: json['term_id'] as int? ?? json['id'] as int? ?? 0,
      termName: json['term_name'] as String? ?? json['term'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? json['year'] as String?,
      overallGrade: json['overall_grade'] as String? ?? json['grade'] as String?,
      percentage: (json['percentage'] as num?)?.toDouble(),
      pdfAvailable: json['pdf_available'] as bool? ?? true,
    );
  }
}

class ReportCardResponse {
  const ReportCardResponse({required this.terms});

  final List<ReportTerm> terms;

  factory ReportCardResponse.fromJson(Map<String, dynamic> json) {
    final list = json['terms'] as List<dynamic>? ?? json['items'] as List<dynamic>? ?? [];
    return ReportCardResponse(
      terms: list.map((e) => ReportTerm.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
