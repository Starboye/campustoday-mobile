import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';
import '../models/teacher.dart';

final teachersRepositoryProvider = Provider<TeachersRepository>((ref) {
  return TeachersRepository(ref.watch(dioProvider));
});

class TeachersRepository {
  TeachersRepository(this._dio);

  final Dio _dio;

  Future<List<Teacher>> list({String? search}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/teachers',
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    return parseListData(data).map(Teacher.fromJson).toList();
  }

  Future<Teacher> get(String id) async {
    final data = await _dio.adminGet<dynamic>('/admin/teachers/$id');
    return Teacher.fromJson(parseItemData(data));
  }

  Future<Teacher> create(Map<String, dynamic> body) async {
    final data = await _dio.adminPost<dynamic>('/admin/teachers', data: body);
    return Teacher.fromJson(parseItemData(data));
  }

  Future<Teacher> update(String id, Map<String, dynamic> body) async {
    final data = await _dio.adminPut<dynamic>('/admin/teachers/$id', data: body);
    return Teacher.fromJson(parseItemData(data));
  }

  Future<void> delete(String id) async {
    await _dio.adminDelete('/admin/teachers/$id');
  }
}
