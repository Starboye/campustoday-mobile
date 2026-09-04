import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/teacher_homework_providers.dart';
import 'teacher_homework_form_screen.dart';

/// Loads a homework item by id when navigating directly (no route extra).
class TeacherHomeworkEditLoader extends ConsumerWidget {
  const TeacherHomeworkEditLoader({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(teacherHomeworkListProvider);

    return listAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit homework')),
        body: Center(child: Text('Could not load homework.\n$e')),
      ),
      data: (response) {
        final match = response.items.where((item) => item.id == homeworkId).toList();
        if (match.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit homework')),
            body: const Center(child: Text('Homework not found.')),
          );
        }
        return TeacherHomeworkFormScreen(existing: match.first);
      },
    );
  }
}
