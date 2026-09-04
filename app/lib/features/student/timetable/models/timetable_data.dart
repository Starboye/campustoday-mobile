class TimetableItem {
  const TimetableItem({
    required this.day,
    required this.period,
    required this.subjectName,
    this.startTime,
    this.endTime,
    this.teacherId,
  });

  final String day;
  final int period;
  final String subjectName;
  final String? startTime;
  final String? endTime;
  final String? teacherId;

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      day: json['day']?.toString() ?? '',
      period: json['period'] as int? ?? 0,
      subjectName: json['subject_name'] as String? ?? '',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      teacherId: json['teacher_id'] as String?,
    );
  }
}

class TimetableResponse {
  const TimetableResponse({
    required this.status,
    required this.items,
    this.message,
    this.timetableId,
  });

  final String status;
  final List<TimetableItem> items;
  final String? message;
  final int? timetableId;

  bool get isApproved => status == 'approved';

  factory TimetableResponse.fromJson(Map<String, dynamic> json) {
    return TimetableResponse(
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
      timetableId: json['timetable_id'] as int?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TimetableItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, List<TimetableItem>> get itemsByDay {
    final map = <String, List<TimetableItem>>{};
    for (final item in items) {
      final key = item.day.isNotEmpty ? item.day : 'Day';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}
