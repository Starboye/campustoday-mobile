import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/security_repository.dart';
import '../providers/security_providers.dart';

class LoginAuditScreen extends ConsumerWidget {
  const LoginAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.security)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Security')),
        body: AdminEmptyView(message: 'You do not have security access.'),
      );
    }

    final listAsync = ref.watch(loginAuditProvider);
    final statusFilter = ref.watch(loginAuditStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login audit'),
        actions: [
          PopupMenuButton<String?>(
            initialValue: statusFilter,
            onSelected: (value) =>
                ref.read(loginAuditStatusFilterProvider.notifier).state = value,
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('All statuses')),
              PopupMenuItem(value: 'success', child: Text('Success')),
              PopupMenuItem(value: 'failed', child: Text('Failed')),
            ],
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load login audit.\n$e',
          onRetry: () => ref.invalidate(loginAuditProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No login events found.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(loginAuditProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AuditCard(entry: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry});

  final LoginAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status.toLowerCase() == 'success';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.red.withValues(alpha: 0.12),
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
        title: Text(entry.username ?? 'User ${entry.userId}'),
        subtitle: Text(
          '${entry.status} · ${entry.ipAddress ?? '—'}\n${entry.createdAt ?? ''}',
        ),
        isThreeLine: true,
        trailing: entry.userId.isNotEmpty ? const Icon(Icons.chevron_right) : null,
        onTap: entry.userId.isNotEmpty
            ? () => context.push('/admin/more/security/users/${entry.userId}')
            : null,
      ),
    );
  }
}
