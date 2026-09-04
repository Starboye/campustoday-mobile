import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance/models/attendance_models.dart';
import '../data/marks_repository.dart';
import '../models/marks_models.dart';

final marksClassFilterProvider = StateProvider<ClassSectionKey?>((ref) => null);

final marksTermFilterProvider = StateProvider<int?>((ref) => null);

final teacherMarksListProvider =
    FutureProvider.autoDispose<TeacherMarksListResponse>((ref) async {
  final filter = ref.watch(marksClassFilterProvider);
  final term = ref.watch(marksTermFilterProvider);
  return ref.watch(teacherMarksRepositoryProvider).fetchMarks(
        standard: filter?.standard,
        section: filter?.section,
        term: term,
      );
});
