import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../attendance/models/attendance_models.dart';
import '../providers/students_providers.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocationsAsync = ref.watch(teacherAllocationsProvider);
    final selected = ref.watch(studentsClassFilterProvider);
    final studentsAsync = ref.watch(studentsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: allocationsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load classes: $e'),
            data: (classes) {
              if (classes.isEmpty) {
                return const Text('No class allocations.');
              }
              return DropdownButtonFormField<ClassSectionKey?>(
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Filter by class',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<ClassSectionKey?>(
                    value: null,
                    child: Text('All classes'),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                  ),
                ],
                onChanged: (v) => ref.read(studentsClassFilterProvider.notifier).state = v,
              );
            },
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load students.\n$e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(studentsListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (students) {
              if (students.isEmpty) {
                return const Center(child: Text('No students found.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(studentsListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                          child: Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(AppConstants.primaryColor),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(
                            color: Color(AppConstants.navyColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (student.classLabel.isNotEmpty) student.classLabel,
                            'ID: ${student.id}',
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/teacher/students/${student.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
