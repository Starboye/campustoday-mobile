import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/homework_repository.dart';

final adminHomeworkListProvider = FutureProvider.autoDispose<List<HomeworkModerationItem>>((ref) {
  return ref.watch(adminHomeworkRepositoryProvider).list();
});
