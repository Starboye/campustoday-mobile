import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final dataQualityRepositoryProvider = Provider<DataQualityRepository>((ref) {
  return DataQualityRepository(ref.watch(dioProvider));
});

class DataQualityRepository {
  DataQualityRepository(this._dio);

  final Dio _dio;

  Future<List<DataQualityIssue>> list({String? status}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/data-quality',
      queryParameters: status != null ? {'status': status} : null,
    );
    return parseListData(data, key: 'items').map(DataQualityIssue.fromJson).toList();
  }

  Future<void> resolve(int id, String status) async {
    await _dio.adminPut<dynamic>('/admin/data-quality/$id', data: {'status': status});
  }
}

class DataQualityIssue {
  const DataQualityIssue({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.issue,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String? entityType;
  final String? entityId;
  final String issue;
  final String status;
  final String? createdAt;

  factory DataQualityIssue.fromJson(Map<String, dynamic> json) {
    return DataQualityIssue(
      id: (json['id'] as num?)?.toInt() ?? 0,
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      issue: json['issue']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at']?.toString(),
    );
  }
}
