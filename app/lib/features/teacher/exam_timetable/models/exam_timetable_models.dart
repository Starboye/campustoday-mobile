class ExamTimetableSlot {
  const ExamTimetableSlot({
    required this.id,
    this.standard,
    this.section,
    this.subjectName,
    this.examName,
    required this.date,
    this.startTime,
    this.endTime,
    this.room,
    this.teacherId,
  });

  final int id;
  final int? standard;
  final String? section;
  final String? subjectName;
  final String? examName;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? room;
  final String? teacherId;

  String get classLabel {
    if (standard == null || section == null) return '';
    return 'Class $standard$section';
  }

  factory ExamTimetableSlot.fromJson(Map<String, dynamic> json) {
    return ExamTimetableSlot(
      id: json['id'] as int,
      standard: json['standard'] as int?,
      section: json['section'] as String?,
      subjectName: json['subject_name'] as String?,
      examName: json['exam_name'] as String?,
      date: json['date'] as String? ?? '',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      room: json['room'] as String?,
      teacherId: json['teacher_id'] as String?,
    );
  }
}

class ExamTimetableResponse {
  const ExamTimetableResponse({required this.items});

  final List<ExamTimetableSlot> items;

  factory ExamTimetableResponse.fromJson(Map<String, dynamic> json) {
    return ExamTimetableResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => ExamTimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
