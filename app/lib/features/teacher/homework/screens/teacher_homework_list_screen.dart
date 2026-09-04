import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/teacher_homework_providers.dart';

class TeacherHomeworkListScreen extends ConsumerWidget {
  const TeacherHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(teacherHomeworkListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teacher/homework/new'),
        child: const Icon(Icons.add),
      ),
      body: homeworkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load homework.\n$e')),
        data: (response) {
          if (response.items.isEmpty) {
            return const Center(child: Text('No homework yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherHomeworkListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: response.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = response.items[index];
                final dateLabel = DateFormat('d MMM yyyy').format(
                  DateTime.tryParse(item.date) ?? DateTime.now(),
                );
                return Card(
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(AppConstants.navyColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${item.subjectName} · Class ${item.standard}${item.section} · $dateLabel',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          context.push('/teacher/homework/${item.id}/edit', extra: item);
                        } else if (action == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete homework?'),
                              content: Text('Remove "${item.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await ref
                                .read(teacherHomeworkRepositoryProvider)
                                .deleteHomework(item.id);
                            ref.invalidate(teacherHomeworkListProvider);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => context.push('/teacher/homework/${item.id}/edit', extra: item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
