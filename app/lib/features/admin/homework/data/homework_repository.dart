import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final adminHomeworkRepositoryProvider = Provider<AdminHomeworkRepository>((ref) {
  return AdminHomeworkRepository(ref.watch(dioProvider));
});

class AdminHomeworkRepository {
  AdminHomeworkRepository(this._dio);

  final Dio _dio;

  Future<List<HomeworkModerationItem>> list() async {
    final data = await _dio.adminGet<dynamic>('/admin/homework');
    return parseListData(data).map(HomeworkModerationItem.fromJson).toList();
  }

  Future<void> delete(String id) async {
    await _dio.adminDelete('/admin/homework/$id');
  }
}

class HomeworkModerationItem {
  const HomeworkModerationItem({
    required this.id,
    required this.title,
    required this.className,
    required this.teacherName,
    required this.date,
  });

  final String id;
  final String title;
  final String className;
  final String teacherName;
  final String date;

  factory HomeworkModerationItem.fromJson(Map<String, dynamic> json) {
    return HomeworkModerationItem(
      id: '${json['id']}',
      title: json['title']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}
