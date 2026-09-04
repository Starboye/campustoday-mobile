class HomeworkItem {
  const HomeworkItem({
    required this.id,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.standard,
    required this.section,
    required this.date,
    required this.title,
    required this.description,
    required this.targetType,
    this.studentId,
  });

  final int id;
  final String subjectName;
  final String teacherId;
  final String? teacherName;
  final int standard;
  final String section;
  final String date;
  final String title;
  final String? description;
  final String targetType;
  final dynamic studentId;

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    return HomeworkItem(
      id: json['id'] as int,
      subjectName: json['subject_name'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String?,
      standard: json['standard'] as int,
      section: json['section'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetType: json['target_type'] as String? ?? 'class',
      studentId: json['student_id'],
    );
  }
}

class HomeworkListResponse {
  const HomeworkListResponse({required this.date, required this.items});

  final String date;
  final List<HomeworkItem> items;

  factory HomeworkListResponse.fromJson(Map<String, dynamic> json) {
    return HomeworkListResponse(
      date: json['date'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => HomeworkItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
