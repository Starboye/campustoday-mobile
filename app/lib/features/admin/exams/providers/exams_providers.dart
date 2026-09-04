import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exams_repository.dart';

final examsListProvider = FutureProvider.autoDispose<List<ExamWindow>>((ref) {
  return ref.watch(examsRepositoryProvider).list();
});
