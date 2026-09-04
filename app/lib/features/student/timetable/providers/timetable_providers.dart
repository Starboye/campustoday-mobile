import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timetable_repository.dart';
import '../models/timetable_data.dart';

final timetableProvider = FutureProvider.autoDispose<TimetableResponse>((ref) async {
  return ref.watch(timetableRepositoryProvider).fetchTimetable();
});
