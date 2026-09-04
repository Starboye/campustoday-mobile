import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/homework_repository.dart';
import '../providers/homework_providers.dart';

class AdminHomeworkListScreen extends ConsumerWidget {
  const AdminHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.homework)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Homework')),
        body: AdminEmptyView(message: 'You do not have homework moderation access.'),
      );
    }

    final listAsync = ref.watch(adminHomeworkListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load homework.\n$e',
          onRetry: () => ref.invalidate(adminHomeworkListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No homework to moderate.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminHomeworkListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text('${item.className} · ${item.teacherName} · ${item.date}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete homework?'),
                            content: Text('Remove "${item.title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref.read(adminHomeworkRepositoryProvider).delete(item.id);
                          ref.invalidate(adminHomeworkListProvider);
                        }
                      },
                    ),
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
