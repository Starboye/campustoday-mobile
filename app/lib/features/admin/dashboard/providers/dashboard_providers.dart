import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchStats();
});
