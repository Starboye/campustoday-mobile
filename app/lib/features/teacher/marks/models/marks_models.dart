class TeacherMarkRow {
  const TeacherMarkRow({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.standard,
    required this.section,
    required this.subjectName,
    required this.marks,
    this.term,
    this.examType,
    this.grade,
    this.maxMarks,
  });

  final int id;
  final String studentId;
  final String studentName;
  final int standard;
  final String section;
  final String subjectName;
  final dynamic marks;
  final int? term;
  final String? examType;
  final String? grade;
  final dynamic maxMarks;

  String get classLabel => 'Class $standard$section';

  factory TeacherMarkRow.fromJson(Map<String, dynamic> json) {
    return TeacherMarkRow(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? '',
      standard: json['standard'] as int,
      section: json['section'] as String,
      subjectName: json['subject_name'] as String? ?? '',
      marks: json['marks'],
      term: json['term'] as int?,
      examType: json['exam_type'] as String?,
      grade: json['grade'] as String?,
      maxMarks: json['max_marks'],
    );
  }
}

class TeacherMarksListResponse {
  const TeacherMarksListResponse({required this.items});

  final List<TeacherMarkRow> items;

  factory TeacherMarksListResponse.fromJson(Map<String, dynamic> json) {
    return TeacherMarksListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => TeacherMarkRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherMarkUpdate {
  const TeacherMarkUpdate({
    required this.studentId,
    required this.subjectName,
    required this.marks,
    this.term,
    this.examType,
    this.grade,
    this.maxMarks,
  });

  final String studentId;
  final String subjectName;
  final dynamic marks;
  final int? term;
  final String? examType;
  final String? grade;
  final dynamic maxMarks;

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'subject_name': subjectName,
        'marks': marks,
        if (term != null) 'term': term,
        if (examType != null) 'exam_type': examType,
        if (grade != null) 'grade': grade,
        if (maxMarks != null) 'max_marks': maxMarks,
      };
}
