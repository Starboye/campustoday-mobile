import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(dioProvider));
});

class PlannerRepository {
  PlannerRepository(this._dio);

  final Dio _dio;

  Future<List<PlannerSlot>> listSlots() async {
    final data = await _dio.adminGet<dynamic>('/admin/planner/slots');
    return parseListData(data).map(PlannerSlot.fromJson).toList();
  }

  Future<List<PlannerAssignment>> listAssignments() async {
    final data = await _dio.adminGet<dynamic>('/admin/planner/assignments');
    return parseListData(data).map(PlannerAssignment.fromJson).toList();
  }

  Future<List<PlannerTimetable>> listTimetables() async {
    final data = await _dio.adminGet<dynamic>('/admin/planner/timetables');
    return parseListData(data).map(PlannerTimetable.fromJson).toList();
  }
}

class PlannerSlot {
  const PlannerSlot({required this.id, required this.day, required this.period, required this.className});

  final String id;
  final String day;
  final String period;
  final String className;

  factory PlannerSlot.fromJson(Map<String, dynamic> json) {
    return PlannerSlot(
      id: '${json['id']}',
      day: json['day']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
    );
  }
}

class PlannerAssignment {
  const PlannerAssignment({
    required this.id,
    required this.teacherName,
    required this.subject,
    required this.className,
  });

  final String id;
  final String teacherName;
  final String subject;
  final String className;

  factory PlannerAssignment.fromJson(Map<String, dynamic> json) {
    return PlannerAssignment(
      id: '${json['id']}',
      teacherName: json['teacher_name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
    );
  }
}

class PlannerTimetable {
  const PlannerTimetable({required this.id, required this.className, required this.entries});

  final String id;
  final String className;
  final int entries;

  factory PlannerTimetable.fromJson(Map<String, dynamic> json) {
    return PlannerTimetable(
      id: '${json['id']}',
      className: json['class_name']?.toString() ?? '',
      entries: (json['entries'] as num?)?.toInt() ?? 0,
    );
  }
}
