import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/students_repository.dart';
import '../models/student.dart';

final studentSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final studentsListProvider = FutureProvider.autoDispose<List<Student>>((ref) {
  final search = ref.watch(studentSearchProvider);
  return ref.watch(studentsRepositoryProvider).list(search: search);
});

final studentDetailProvider = FutureProvider.autoDispose.family<Student, String>((ref, id) {
  return ref.watch(studentsRepositoryProvider).get(id);
});
