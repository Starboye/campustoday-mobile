import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/report_term.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioProvider));
});

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  Future<ReportCardResponse> fetchReportCard() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/report-card');
    return ReportCardResponse.fromJson(data);
  }

  Future<Uint8List> downloadPdf(int termId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/student/report-card/$termId/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw ApiException(data['message'] as String, statusCode: e.response?.statusCode);
      }
      throw ApiException(e.message ?? 'Download failed', statusCode: e.response?.statusCode);
    }
  }
}
