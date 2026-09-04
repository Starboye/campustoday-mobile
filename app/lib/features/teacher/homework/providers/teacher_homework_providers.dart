import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/teacher_homework_repository.dart';
import '../models/teacher_homework_item.dart';

final teacherHomeworkListProvider =
    FutureProvider.autoDispose<TeacherHomeworkListResponse>((ref) {
  return ref.watch(teacherHomeworkRepositoryProvider).fetchHomework();
});
