import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';
import '../models/student.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(ref.watch(dioProvider));
});

class StudentsRepository {
  StudentsRepository(this._dio);

  final Dio _dio;

  Future<List<Student>> list({String? search}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/students',
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    return parseListData(data).map(Student.fromJson).toList();
  }

  Future<Student> get(String id) async {
    final data = await _dio.adminGet<dynamic>('/admin/students/$id');
    return Student.fromJson(parseItemData(data));
  }

  Future<Student> create(Map<String, dynamic> body) async {
    final data = await _dio.adminPost<dynamic>('/admin/students', data: body);
    return Student.fromJson(parseItemData(data));
  }

  Future<Student> update(String id, Map<String, dynamic> body) async {
    final data = await _dio.adminPut<dynamic>('/admin/students/$id', data: body);
    return Student.fromJson(parseItemData(data));
  }

  Future<void> delete(String id) async {
    await _dio.adminDelete('/admin/students/$id');
  }
}
