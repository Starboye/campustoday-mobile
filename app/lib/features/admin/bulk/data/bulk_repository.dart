import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final bulkRepositoryProvider = Provider<BulkRepository>((ref) {
  return BulkRepository(ref.watch(dioProvider));
});

class BulkRepository {
  BulkRepository(this._dio);

  final Dio _dio;

  Future<BulkImportResult> upload({
    required String type,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'type': type,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    try {
      final response = await _dio.post<dynamic>(
        '/admin/bulk',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return BulkImportResult.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'Import accepted'},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw Exception(data['message'] as String);
      }
      rethrow;
    }
  }
}

class BulkImportResult {
  const BulkImportResult({
    required this.message,
    this.imported,
    this.failed,
    this.errors,
  });

  final String message;
  final int? imported;
  final int? failed;
  final List<String>? errors;

  factory BulkImportResult.fromJson(Map<String, dynamic> json) {
    final errs = json['errors'];
    return BulkImportResult(
      message: json['message']?.toString() ?? 'Import complete',
      imported: (json['imported'] as num?)?.toInt(),
      failed: (json['failed'] as num?)?.toInt(),
      errors: errs is List ? errs.map((e) => e.toString()).toList() : null,
    );
  }
}
