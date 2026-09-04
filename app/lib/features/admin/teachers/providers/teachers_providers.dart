import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teachers_repository.dart';
import '../models/teacher.dart';

final teacherSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final teachersListProvider = FutureProvider.autoDispose<List<Teacher>>((ref) {
  final search = ref.watch(teacherSearchProvider);
  return ref.watch(teachersRepositoryProvider).list(search: search);
});

final teacherDetailProvider = FutureProvider.autoDispose.family<Teacher, String>((ref, id) {
  return ref.watch(teachersRepositoryProvider).get(id);
});
