import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final approvalsRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(ref.watch(dioProvider));
});

class ApprovalsRepository {
  ApprovalsRepository(this._dio);

  final Dio _dio;

  Future<List<ApprovalItem>> list({String? status}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/approvals',
      queryParameters: status != null ? {'status': status} : null,
    );
    return parseListData(data).map(ApprovalItem.fromJson).toList();
  }

  Future<void> decide({
    required String id,
    required String action,
    String? note,
  }) async {
    final body = action == 'reject' && note != null ? {'notes': note} : null;
    await _dio.adminPost('/admin/approvals/$id/$action', data: body);
  }
}

class ApprovalItem {
  const ApprovalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.requester,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String requester;
  final String status;
  final String createdAt;

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: '${json['id']}',
      type: json['request_type']?.toString() ?? json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? json['request_type']?.toString() ?? 'Approval request',
      requester: json['requested_by']?.toString() ?? json['requester']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
