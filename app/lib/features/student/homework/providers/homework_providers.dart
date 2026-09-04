import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/homework_repository.dart';
import '../models/homework_item.dart';

final homeworkDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final homeworkListProvider = FutureProvider.autoDispose<HomeworkListResponse>((ref) async {
  final date = ref.watch(homeworkDateProvider);
  final formatted = DateFormat('yyyy-MM-dd').format(date);
  return ref.watch(homeworkRepositoryProvider).fetchHomework(date: formatted);
});
