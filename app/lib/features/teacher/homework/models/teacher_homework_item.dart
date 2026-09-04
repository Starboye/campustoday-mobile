class TeacherHomeworkItem {
  const TeacherHomeworkItem({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.standard,
    required this.section,
    required this.date,
    required this.title,
    required this.description,
    required this.targetType,
    this.studentId,
    this.studentName,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final int standard;
  final String section;
  final String date;
  final String title;
  final String? description;
  final String targetType;
  final String? studentId;
  final String? studentName;

  factory TeacherHomeworkItem.fromJson(Map<String, dynamic> json) {
    return TeacherHomeworkItem(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      standard: json['standard'] as int,
      section: json['section'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetType: json['target_type'] as String? ?? 'class',
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'standard': standard,
        'section': section,
        'date': date,
        'title': title,
        'description': description,
        'target_type': targetType,
        if (studentId != null) 'student_id': studentId,
      };
}

class TeacherHomeworkListResponse {
  const TeacherHomeworkListResponse({required this.items});

  final List<TeacherHomeworkItem> items;

  factory TeacherHomeworkListResponse.fromJson(Map<String, dynamic> json) {
    return TeacherHomeworkListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => TeacherHomeworkItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
