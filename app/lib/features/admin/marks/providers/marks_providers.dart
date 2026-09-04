import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marks_repository.dart';

final marksTermProvider = StateProvider.autoDispose<String>((ref) => '');
final marksStudentProvider = StateProvider.autoDispose<String>((ref) => '');

final marksListProvider = FutureProvider.autoDispose<List<MarksEntry>>((ref) {
  final term = ref.watch(marksTermProvider);
  final studentId = ref.watch(marksStudentProvider);
  return ref.watch(marksRepositoryProvider).list(
        term: term.isEmpty ? null : term,
        studentId: studentId.isEmpty ? null : studentId,
      );
});
