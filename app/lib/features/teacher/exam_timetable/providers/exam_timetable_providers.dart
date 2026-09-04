import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_timetable_repository.dart';
import '../models/exam_timetable_models.dart';

final examTimetableProvider = FutureProvider.autoDispose<ExamTimetableResponse>((ref) {
  return ref.watch(examTimetableRepositoryProvider).fetchExamTimetable();
});
