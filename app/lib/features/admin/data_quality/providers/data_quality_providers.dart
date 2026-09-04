import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_quality_repository.dart';

final dataQualityListProvider = FutureProvider.autoDispose<List<DataQualityIssue>>((ref) {
  final status = ref.watch(dataQualityStatusFilterProvider);
  return ref.watch(dataQualityRepositoryProvider).list(status: status);
});

final dataQualityStatusFilterProvider = StateProvider<String?>((ref) => 'open');
