import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  return ExamsRepository(ref.watch(dioProvider));
});

class ExamsRepository {
  ExamsRepository(this._dio);

  final Dio _dio;

  Future<List<ExamWindow>> list() async {
    final data = await _dio.adminGet<dynamic>('/admin/exams');
    return parseListData(data).map(ExamWindow.fromJson).toList();
  }

  Future<ExamWindow> save(Map<String, dynamic> body) async {
    final data = await _dio.adminPost<dynamic>('/admin/exams', data: body);
    return ExamWindow.fromJson(parseItemData(data));
  }
}

class ExamWindow {
  const ExamWindow({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.term,
  });

  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String term;

  factory ExamWindow.fromJson(Map<String, dynamic> json) {
    return ExamWindow(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      term: json['term']?.toString() ?? '',
    );
  }
}
