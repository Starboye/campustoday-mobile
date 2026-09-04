import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/notifications_repository.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.notifications)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: AdminEmptyView(message: 'You do not have notifications access.'),
      );
    }

    final templatesAsync = ref.watch(notificationTemplatesProvider);
    final schedulesAsync = ref.watch(notificationSchedulesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () => _sendNow(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Templates'),
              Tab(text: 'Schedules'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            templatesAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load templates.\n$e',
                onRetry: () => ref.invalidate(notificationTemplatesProvider),
              ),
              data: (items) => _list(
                items,
                (t) => ListTile(title: Text(t.name), subtitle: Text(t.channel)),
                'No templates.',
                () => ref.invalidate(notificationTemplatesProvider),
              ),
            ),
            schedulesAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load schedules.\n$e',
                onRetry: () => ref.invalidate(notificationSchedulesProvider),
              ),
              data: (items) => _list(
                items,
                (s) => ListTile(title: Text(s.name), subtitle: Text(s.cron)),
                'No schedules.',
                () => ref.invalidate(notificationSchedulesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list<T>(
    List<T> items,
    Widget Function(T) tile,
    String empty,
    Future<void> Function() onRefresh,
  ) {
    if (items.isEmpty) return AdminEmptyView(message: empty);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(child: tile(items[i])),
      ),
    );
  }

  Future<void> _sendNow(BuildContext context, WidgetRef ref) async {
    final templateId = TextEditingController();
    final audience = TextEditingController(text: 'all');

    await showAdminEditSheet(
      context: context,
      title: 'Send notification now',
      fields: [
        TextField(controller: templateId, decoration: const InputDecoration(labelText: 'Template ID')),
        TextField(controller: audience, decoration: const InputDecoration(labelText: 'Audience')),
      ],
      onSave: () async {
        await ref.read(notificationsRepositoryProvider).sendNow(
              templateId: templateId.text.trim(),
              audience: audience.text.trim(),
            );
      },
    );

    templateId.dispose();
    audience.dispose();
  }
}
