import '../../shared/models/allocation.dart';

enum AttendanceSession { morning, afternoon, evening }

enum AttendanceStatus { present, absent, leave }

extension AttendanceSessionX on AttendanceSession {
  String get apiValue => name;

  String get label => switch (this) {
        AttendanceSession.morning => 'AM',
        AttendanceSession.afternoon => 'PM',
        AttendanceSession.evening => 'EV',
      };
}

extension AttendanceStatusX on AttendanceStatus {
  String get apiValue => name;
}

AttendanceStatus? attendanceStatusFromApi(String? value) {
  if (value == null) return null;
  return AttendanceStatus.values.cast<AttendanceStatus?>().firstWhere(
        (s) => s?.apiValue == value,
        orElse: () => null,
      );
}

class StudentAttendanceRow {
  const StudentAttendanceRow({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.sessions,
  });

  final String studentId;
  final String name;
  final String rollNo;
  final Map<AttendanceSession, AttendanceStatus?> sessions;

  StudentAttendanceRow copyWithSession(AttendanceSession session, AttendanceStatus? status) {
    final updated = Map<AttendanceSession, AttendanceStatus?>.from(sessions);
    updated[session] = status;
    return StudentAttendanceRow(
      studentId: studentId,
      name: name,
      rollNo: rollNo,
      sessions: updated,
    );
  }

  factory StudentAttendanceRow.fromJson(Map<String, dynamic> json) {
    if (json['sessions'] is Map) {
      final raw = json['sessions'] as Map<String, dynamic>;
      return StudentAttendanceRow(
        studentId: json['student_id'] as String,
        name: json['name'] as String,
        rollNo: json['roll_no'] as String? ?? '',
        sessions: {
          for (final session in AttendanceSession.values)
            session: attendanceStatusFromApi(raw[session.apiValue] as String?),
        },
      );
    }

    return StudentAttendanceRow(
      studentId: json['student_id'] as String,
      name: json['name'] as String? ?? '',
      rollNo: json['roll_no'] as String? ?? '',
      sessions: {
        AttendanceSession.morning: attendanceStatusFromApi(json['morning'] as String?),
        AttendanceSession.afternoon: attendanceStatusFromApi(json['afternoon'] as String?),
        AttendanceSession.evening: attendanceStatusFromApi(json['evening'] as String?),
      },
    );
  }
}

class AttendanceSheet {
  const AttendanceSheet({
    required this.date,
    required this.standard,
    required this.section,
    required this.locked,
    required this.students,
  });

  final String date;
  final int standard;
  final String section;
  final bool locked;
  final List<StudentAttendanceRow> students;

  AttendanceSheet copyWithStudents(List<StudentAttendanceRow> students) {
    return AttendanceSheet(
      date: date,
      standard: standard,
      section: section,
      locked: locked,
      students: students,
    );
  }

  factory AttendanceSheet.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? json['students'] as List<dynamic>? ?? [];
    return AttendanceSheet(
      date: json['date'] as String,
      standard: json['standard'] as int,
      section: json['section'] as String,
      locked: json['locked'] as bool? ?? false,
      students: items.map((e) => StudentAttendanceRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ClassSectionKey {
  const ClassSectionKey({required this.standard, required this.section});

  final int standard;
  final String section;

  factory ClassSectionKey.fromAllocation(TeacherAllocation allocation) {
    return ClassSectionKey(standard: allocation.standard, section: allocation.section);
  }

  @override
  bool operator ==(Object other) =>
      other is ClassSectionKey && other.standard == standard && other.section == section;

  @override
  int get hashCode => Object.hash(standard, section);

  String get label => 'Class $standard$section';
}
