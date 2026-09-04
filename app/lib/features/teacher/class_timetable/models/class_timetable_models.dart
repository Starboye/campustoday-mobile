class ClassTimetableItem {
  const ClassTimetableItem({
    required this.assignmentId,
    required this.slotId,
    required this.day,
    required this.period,
    required this.subjectName,
    required this.teacherId,
    this.startTime,
    this.endTime,
  });

  final int assignmentId;
  final int slotId;
  final String day;
  final int period;
  final String subjectName;
  final String teacherId;
  final String? startTime;
  final String? endTime;

  factory ClassTimetableItem.fromJson(Map<String, dynamic> json) {
    return ClassTimetableItem(
      assignmentId: json['assignment_id'] as int? ?? 0,
      slotId: json['slot_id'] as int,
      day: json['day'] as String? ?? '',
      period: json['period'] as int,
      subjectName: json['subject_name'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'slot_id': slotId,
        'subject_name': subjectName,
        if (teacherId.isNotEmpty) 'teacher_id': teacherId,
      };
}

class ClassTimetableResponse {
  const ClassTimetableResponse({
    required this.status,
    this.timetableId,
    this.standard,
    this.section,
    required this.items,
  });

  final String status;
  final int? timetableId;
  final int? standard;
  final String? section;
  final List<ClassTimetableItem> items;

  String get classLabel {
    if (standard == null || section == null) return '';
    return 'Class $standard$section';
  }

  factory ClassTimetableResponse.fromJson(Map<String, dynamic> json) {
    return ClassTimetableResponse(
      status: json['status'] as String? ?? 'draft',
      timetableId: json['timetable_id'] as int?,
      standard: json['standard'] as int?,
      section: json['section'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ClassTimetableItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
