import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationTemplate>> listTemplates() async {
    final data = await _dio.adminGet<dynamic>('/admin/notifications/templates');
    return parseListData(data).map(NotificationTemplate.fromJson).toList();
  }

  Future<List<NotificationSchedule>> listSchedules() async {
    final data = await _dio.adminGet<dynamic>('/admin/notifications/schedules');
    return parseListData(data).map(NotificationSchedule.fromJson).toList();
  }

  Future<void> sendNow({required String templateId, required String audience}) async {
    await _dio.adminPost('/admin/notifications/send', data: {
      'template_id': templateId,
      'audience': audience,
    });
  }
}

class NotificationTemplate {
  const NotificationTemplate({required this.id, required this.name, required this.channel});

  final String id;
  final String name;
  final String channel;

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
    );
  }
}

class NotificationSchedule {
  const NotificationSchedule({required this.id, required this.name, required this.cron});

  final String id;
  final String name;
  final String cron;

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      cron: json['cron']?.toString() ?? '',
    );
  }
}
