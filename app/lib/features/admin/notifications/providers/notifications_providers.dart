import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';

final notificationTemplatesProvider = FutureProvider.autoDispose<List<NotificationTemplate>>((ref) {
  return ref.watch(notificationsRepositoryProvider).listTemplates();
});

final notificationSchedulesProvider = FutureProvider.autoDispose<List<NotificationSchedule>>((ref) {
  return ref.watch(notificationsRepositoryProvider).listSchedules();
});
