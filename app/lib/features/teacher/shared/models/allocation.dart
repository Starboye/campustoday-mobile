class TeacherAllocation {
  const TeacherAllocation({
    required this.id,
    required this.standard,
    required this.section,
    required this.subjectId,
    required this.subjectName,
  });

  final String id;
  final int standard;
  final String section;
  final String subjectId;
  final String subjectName;

  String get classLabel => 'Class $standard$section';

  factory TeacherAllocation.fromJson(Map<String, dynamic> json) {
    return TeacherAllocation(
      id: json['id'] as String,
      standard: json['standard'] as int,
      section: json['section'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
    );
  }
}
