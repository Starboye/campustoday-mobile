import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> fetchStats() async {
    final data = await _dio.adminGet<Map<String, dynamic>>('/admin/dashboard');
    return DashboardStats.fromJson(parseItemData(data));
  }
}

class DashboardStats {
  const DashboardStats({
    required this.studentCount,
    required this.teacherCount,
    required this.pendingApprovals,
    required this.attendanceToday,
    required this.feeCollection,
  });

  final int studentCount;
  final int teacherCount;
  final int pendingApprovals;
  final double attendanceToday;
  final double feeCollection;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      studentCount: _asInt(json['student_count']),
      teacherCount: _asInt(json['teacher_count']),
      pendingApprovals: _asInt(json['pending_approvals']),
      attendanceToday: _asDouble(json['attendance_today']),
      feeCollection: _asDouble(json['fee_collection']),
    );
  }

  static int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
