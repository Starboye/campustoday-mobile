import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final marksRepositoryProvider = Provider<MarksRepository>((ref) {
  return MarksRepository(ref.watch(dioProvider));
});

class MarksRepository {
  MarksRepository(this._dio);

  final Dio _dio;

  Future<List<MarksEntry>> list({String? studentId, String? term}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/marks',
      queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (term != null) 'term': term,
      },
    );
    return parseListData(data, key: 'items').map(MarksEntry.fromJson).toList();
  }

  Future<MarksEntry> save(Map<String, dynamic> body) async {
    final data = await _dio.adminPost<dynamic>('/admin/marks', data: body);
    return MarksEntry.fromJson(parseItemData(data));
  }
}

class MarksEntry {
  const MarksEntry({
    required this.id,
    required this.studentName,
    required this.subject,
    required this.term,
    required this.score,
  });

  final String id;
  final String studentName;
  final String subject;
  final String term;
  final double score;

  factory MarksEntry.fromJson(Map<String, dynamic> json) {
    return MarksEntry(
      id: '${json['id']}',
      studentName: json['student_name']?.toString() ?? '',
      subject: json['subject_name']?.toString() ?? json['subject']?.toString() ?? '',
      term: json['term']?.toString() ?? '',
      score: (json['marks'] as num?)?.toDouble() ?? (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
