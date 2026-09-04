import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/class_timetable_repository.dart';
import '../models/class_timetable_models.dart';

final classTimetableProvider = FutureProvider.autoDispose<ClassTimetableResponse>((ref) {
  return ref.watch(classTimetableRepositoryProvider).fetchTimetable();
});
