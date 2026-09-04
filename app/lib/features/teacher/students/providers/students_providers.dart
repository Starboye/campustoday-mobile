import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance/models/attendance_models.dart';
import '../data/students_repository.dart';
import '../models/student_models.dart';

final studentsClassFilterProvider = StateProvider<ClassSectionKey?>((ref) => null);

final studentsListProvider = FutureProvider.autoDispose<List<StudentSummary>>((ref) async {
  final filter = ref.watch(studentsClassFilterProvider);
  return ref.watch(studentsRepositoryProvider).fetchStudents(
        standard: filter?.standard,
        section: filter?.section,
      );
});

final studentDossierProvider =
    FutureProvider.autoDispose.family<StudentDossier, String>((ref, id) {
  return ref.watch(studentsRepositoryProvider).fetchStudent(id);
});
