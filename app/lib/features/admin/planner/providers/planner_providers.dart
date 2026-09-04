import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planner_repository.dart';

final plannerSlotsProvider = FutureProvider.autoDispose<List<PlannerSlot>>((ref) {
  return ref.watch(plannerRepositoryProvider).listSlots();
});

final plannerAssignmentsProvider = FutureProvider.autoDispose<List<PlannerAssignment>>((ref) {
  return ref.watch(plannerRepositoryProvider).listAssignments();
});

final plannerTimetablesProvider = FutureProvider.autoDispose<List<PlannerTimetable>>((ref) {
  return ref.watch(plannerRepositoryProvider).listTimetables();
});
