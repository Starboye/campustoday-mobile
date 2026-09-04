import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/security_repository.dart';

class UserSecurityScreen extends ConsumerStatefulWidget {
  const UserSecurityScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserSecurityScreen> createState() => _UserSecurityScreenState();
}

class _UserSecurityScreenState extends ConsumerState<UserSecurityScreen> {
  bool _saving = false;
  bool _forcePasswordReset = false;
  DateTime? _lockedUntil;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.security)) {
      return const Scaffold(
        appBar: AppBar(title: Text('User security')),
        body: AdminEmptyView(message: 'You do not have security access.'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('User ${widget.userId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User ID: ${widget.userId}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _lockedUntil != null
                        ? 'Locked until ${_lockedUntil!.toLocal()}'
                        : 'Not locked',
                  ),
                  Text(
                    _forcePasswordReset
                        ? 'Password reset required'
                        : 'No forced password reset',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _saving ? null : _lockUser,
            child: const Text('Lock for 24 hours'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : _unlockUser,
            child: const Text('Unlock user'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Force password reset'),
            value: _forcePasswordReset,
            onChanged: _saving
                ? null
                : (value) => _update(forcePasswordReset: value),
          ),
        ],
      ),
    );
  }

  Future<void> _lockUser() async {
    final until = DateTime.now().add(const Duration(hours: 24));
    await _update(lockedUntil: until);
  }

  Future<void> _unlockUser() async {
    await _update(lockedUntil: null, clearLock: true);
  }

  Future<void> _update({
    DateTime? lockedUntil,
    bool clearLock = false,
    bool? forcePasswordReset,
  }) async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(securityRepositoryProvider).updateUserSecurity(
            widget.userId,
            lockedUntil: lockedUntil,
            forcePasswordReset: forcePasswordReset,
            clearLock: clearLock,
          );
      setState(() {
        _lockedUntil = result.lockedUntil;
        if (forcePasswordReset != null) {
          _forcePasswordReset = result.forcePasswordReset;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
