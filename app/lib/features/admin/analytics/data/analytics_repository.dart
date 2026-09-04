import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(dioProvider));
});

class AnalyticsRepository {
  AnalyticsRepository(this._dio);

  final Dio _dio;

  Future<AnalyticsData> fetch() async {
    final data = await _dio.adminGet<Map<String, dynamic>>('/admin/analytics');
    return AnalyticsData.fromJson(parseItemData(data));
  }
}

class AnalyticsData {
  const AnalyticsData({
    required this.enrollmentTrend,
    required this.attendanceTrend,
    required this.feeTrend,
  });

  final List<double> enrollmentTrend;
  final List<double> attendanceTrend;
  final List<double> feeTrend;

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      enrollmentTrend: _asDoubles(json['enrollment_trend']),
      attendanceTrend: _asDoubles(json['attendance_trend']),
      feeTrend: _asDoubles(json['fee_trend']),
    );
  }

  static List<double> _asDoubles(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => (e as num).toDouble()).toList();
  }
}
