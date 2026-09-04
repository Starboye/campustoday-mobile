import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../../rbac/providers/rbac_providers.dart';

/// Delegation hub — assign roles to users (mirrors SchoolCRM web delegation).
class DelegationScreen extends ConsumerWidget {
  const DelegationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.delegation)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Delegation')),
        body: AdminEmptyView(message: 'You do not have delegation access.'),
      );
    }

    final rolesAsync = ref.watch(rolesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delegation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Assign roles to user',
            onPressed: () => _promptAssignUser(context),
          ),
        ],
      ),
      body: rolesAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load roles.\n$e',
          onRetry: () => ref.invalidate(rolesListProvider),
        ),
        data: (roles) {
          if (roles.isEmpty) {
            return const AdminEmptyView(message: 'No roles defined.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rolesListProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Role catalog',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a user ID to assign one or more roles. Permissions follow SchoolCRM RBAC keys.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ...roles.map(
                  (role) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: Text(role.name),
                      subtitle: Text(
                        role.permissions.isEmpty
                            ? 'Full admin (no explicit permissions on role)'
                            : role.permissions.join(', '),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _promptAssignUser(context),
        icon: const Icon(Icons.assignment_ind_outlined),
        label: const Text('Assign roles'),
      ),
    );
  }

  Future<void> _promptAssignUser(BuildContext context) async {
    final controller = TextEditingController();
    final userId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign roles to user'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'User ID'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (userId != null && userId.isNotEmpty && context.mounted) {
      context.push('/admin/people/delegation/users/$userId');
    }
  }
}
