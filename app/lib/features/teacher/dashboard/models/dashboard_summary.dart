import '../../shared/models/allocation.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.allocations,
    required this.attendanceCompleteness,
    required this.homeworkCount,
  });

  final List<TeacherAllocation> allocations;
  final AttendanceCompleteness attendanceCompleteness;
  final int homeworkCount;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      allocations: (json['allocations'] as List<dynamic>)
          .map((e) => TeacherAllocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendanceCompleteness: AttendanceCompleteness.fromJson(
        json['attendance_completeness'] as Map<String, dynamic>,
      ),
      homeworkCount: json['homework_count'] as int? ?? 0,
    );
  }
}

class AttendanceCompleteness {
  const AttendanceCompleteness({
    required this.date,
    required this.totalSections,
    required this.completedSections,
    required this.percent,
  });

  final String date;
  final int totalSections;
  final int completedSections;
  final double percent;

  factory AttendanceCompleteness.fromJson(Map<String, dynamic> json) {
    return AttendanceCompleteness(
      date: json['date'] as String,
      totalSections: json['total_sections'] as int? ?? 0,
      completedSections: json['completed_sections'] as int? ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}
