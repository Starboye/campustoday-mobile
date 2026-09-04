class DashboardData {
  const DashboardData({
    required this.profile,
    required this.attendanceSummary,
    required this.unreadNotifications,
    required this.latestMarks,
  });

  final DashboardProfile profile;
  final DashboardAttendance attendanceSummary;
  final int unreadNotifications;
  final List<DashboardMark> latestMarks;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      profile: DashboardProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
      attendanceSummary: DashboardAttendance.fromJson(
        json['attendance_summary'] as Map<String, dynamic>? ?? {},
      ),
      unreadNotifications: json['unread_notifications'] as int? ?? 0,
      latestMarks: (json['latest_marks'] as List<dynamic>? ?? [])
          .map((e) => DashboardMark.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardProfile {
  const DashboardProfile({
    required this.id,
    required this.name,
    this.standard,
    this.section,
  });

  final String id;
  final String name;
  final int? standard;
  final String? section;

  factory DashboardProfile.fromJson(Map<String, dynamic> json) {
    return DashboardProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      standard: json['standard'] as int?,
      section: json['section'] as String?,
    );
  }

  String get classLabel {
    if (standard != null && section != null) {
      return 'Class $standard-$section';
    }
    return '';
  }
}

class DashboardAttendance {
  const DashboardAttendance({
    required this.present,
    required this.absent,
    required this.totalDays,
  });

  final int present;
  final int absent;
  final int totalDays;

  double get percentage {
    if (totalDays == 0) return 0;
    return (present / totalDays) * 100;
  }

  factory DashboardAttendance.fromJson(Map<String, dynamic> json) {
    return DashboardAttendance(
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      totalDays: json['total_days'] as int? ?? 0,
    );
  }
}

class DashboardMark {
  const DashboardMark({
    required this.subjectName,
    required this.marks,
    required this.term,
    this.examType,
  });

  final String subjectName;
  final dynamic marks;
  final dynamic term;
  final String? examType;

  factory DashboardMark.fromJson(Map<String, dynamic> json) {
    return DashboardMark(
      subjectName: json['subject_name'] as String? ?? '',
      marks: json['marks'],
      term: json['term'],
      examType: json['exam_type'] as String?,
    );
  }
}
