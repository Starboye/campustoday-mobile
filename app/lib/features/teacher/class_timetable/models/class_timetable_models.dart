class ClassTimetableItem {
  const ClassTimetableItem({
    this.assignmentId,
    required this.slotId,
    required this.day,
    required this.period,
    required this.subjectName,
    this.startTime,
    this.endTime,
    this.teacherId,
  });

  final int? assignmentId;
  final int slotId;
  final String day;
  final int period;
  final String subjectName;
  final String? startTime;
  final String? endTime;
  final String? teacherId;

  ClassTimetableItem copyWith({String? subjectName}) {
    return ClassTimetableItem(
      assignmentId: assignmentId,
      slotId: slotId,
      day: day,
      period: period,
      subjectName: subjectName ?? this.subjectName,
      startTime: startTime,
      endTime: endTime,
      teacherId: teacherId,
    );
  }

  factory ClassTimetableItem.fromJson(Map<String, dynamic> json) {
    return ClassTimetableItem(
      assignmentId: json['assignment_id'] as int?,
      slotId: json['slot_id'] as int,
      day: json['day']?.toString() ?? '',
      period: json['period'] as int? ?? 0,
      subjectName: json['subject_name'] as String? ?? '',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      teacherId: json['teacher_id'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'slot_id': slotId,
        'subject_name': subjectName,
        if (teacherId != null) 'teacher_id': teacherId,
      };
}

class ClassTimetableResponse {
  const ClassTimetableResponse({
    required this.status,
    required this.standard,
    required this.section,
    required this.items,
    this.timetableId,
  });

  final String status;
  final int standard;
  final String section;
  final List<ClassTimetableItem> items;
  final int? timetableId;

  bool get isEditable => status == 'draft' || status == 'pending';

  String get classLabel => 'Class $standard$section';

  factory ClassTimetableResponse.fromJson(Map<String, dynamic> json) {
    return ClassTimetableResponse(
      status: json['status'] as String? ?? 'draft',
      standard: json['standard'] as int? ?? 0,
      section: json['section'] as String? ?? '',
      timetableId: json['timetable_id'] as int?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ClassTimetableItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, List<ClassTimetableItem>> get itemsByDay {
    final map = <String, List<ClassTimetableItem>>{};
    for (final item in items) {
      final key = item.day.isNotEmpty ? item.day : 'Day';
      map.putIfAbsent(key, () => []).add(item);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.period.compareTo(b.period));
    }
    return map;
  }
}
