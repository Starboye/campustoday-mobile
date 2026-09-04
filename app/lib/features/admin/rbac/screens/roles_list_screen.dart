import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/rbac_repository.dart';
import '../providers/rbac_providers.dart';

class RolesListScreen extends ConsumerWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.rbac)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Roles & Access')),
        body: AdminEmptyView(message: 'You do not have RBAC access.'),
      );
    }

    final rolesAsync = ref.watch(rolesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Access'),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(role.name),
                    subtitle: Text(
                      role.permissions.isEmpty
                          ? 'No permissions'
                          : '${role.permissions.length} permissions',
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

  Future<void> _promptAssignUser(BuildContext context) async {
    final controller = TextEditingController();
    final userId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign roles to user'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'User ID'),
          keyboardType: TextInputType.number,
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
      context.push('/admin/people/rbac/users/$userId');
    }
  }
}
