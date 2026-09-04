import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/rbac_repository.dart';
import '../providers/rbac_providers.dart';

class AssignRolesScreen extends ConsumerStatefulWidget {
  const AssignRolesScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AssignRolesScreen> createState() => _AssignRolesScreenState();
}

class _AssignRolesScreenState extends ConsumerState<AssignRolesScreen> {
  final _selected = <int>{};
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.rbac)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Assign roles')),
        body: AdminEmptyView(message: 'You do not have RBAC access.'),
      );
    }

    final rolesAsync = ref.watch(rolesListProvider);
    final userRolesAsync = ref.watch(userRolesProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Roles for user ${widget.userId}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: rolesAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load roles.\n$e',
          onRetry: () {
            ref.invalidate(rolesListProvider);
            ref.invalidate(userRolesProvider(widget.userId));
          },
        ),
        data: (roles) {
          return userRolesAsync.when(
            loading: () => const AdminLoadingView(),
            error: (e, _) {
              if (!_initialized) {
                _initialized = true;
              }
              return _roleList(roles);
            },
            data: (userRoles) {
              if (!_initialized) {
                _selected
                  ..clear()
                  ..addAll(userRoles.roleIds);
                _initialized = true;
              }
              return _roleList(roles);
            },
          );
        },
      ),
    );
  }

  Widget _roleList(List<AdminRole> roles) {
    if (roles.isEmpty) {
      return const AdminEmptyView(message: 'No roles available.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final role = roles[index];
        return Card(
          child: CheckboxListTile(
            value: _selected.contains(role.id),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selected.add(role.id);
                } else {
                  _selected.remove(role.id);
                }
              });
            },
            title: Text(role.name),
            subtitle: Text('${role.permissions.length} permissions'),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(rbacRepositoryProvider).updateUserRoles(
            widget.userId,
            _selected.toList(),
          );
      ref.invalidate(userRolesProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roles updated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
