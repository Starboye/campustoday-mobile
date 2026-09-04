import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/approvals_repository.dart';
import '../providers/approvals_providers.dart';

class ApprovalsListScreen extends ConsumerWidget {
  const ApprovalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.approvals)) {
      return const AdminEmptyView(message: 'You do not have approvals access.');
    }

    final listAsync = ref.watch(approvalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load approvals.\n$e',
          onRetry: () => ref.invalidate(approvalsListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No pending approvals.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(approvalsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text('${item.type} · ${item.requester}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _decide(context, ref, item, action),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'approve', child: Text('Approve')),
                        PopupMenuItem(value: 'reject', child: Text('Reject')),
                      ],
                    ),
                    onTap: () => _showDetail(context, ref, item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    ApprovalItem item,
    String action,
  ) async {
    final noteController = TextEditingController();
    await showAdminEditSheet(
      context: context,
      title: '${action == 'approve' ? 'Approve' : 'Reject'} request',
      fields: [
        TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
          maxLines: 3,
        ),
      ],
      onSave: () async {
        await ref.read(approvalsRepositoryProvider).decide(
              id: item.id,
              action: action,
              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            );
        ref.invalidate(approvalsListProvider);
      },
    );
    noteController.dispose();
  }

  void _showDetail(BuildContext context, WidgetRef ref, ApprovalItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Type: ${item.type}'),
            Text('Requester: ${item.requester}'),
            Text('Status: ${item.status}'),
            Text('Created: ${item.createdAt}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _decide(context, ref, item, 'reject');
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _decide(context, ref, item, 'approve');
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
