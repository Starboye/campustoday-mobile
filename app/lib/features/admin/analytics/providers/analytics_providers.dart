import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repository.dart';

final analyticsDataProvider = FutureProvider.autoDispose<AnalyticsData>((ref) {
  return ref.watch(analyticsRepositoryProvider).fetch();
});
