import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../models/student_profile.dart';

final studentProfileProvider = FutureProvider.autoDispose<StudentProfile>((ref) async {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});
