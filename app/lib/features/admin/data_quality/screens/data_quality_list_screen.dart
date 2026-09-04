import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/data_quality_repository.dart';
import '../providers/data_quality_providers.dart';

class DataQualityListScreen extends ConsumerWidget {
  const DataQualityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.dataQuality)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Data Quality')),
        body: AdminEmptyView(message: 'You do not have data quality access.'),
      );
    }

    final listAsync = ref.watch(dataQualityListProvider);
    final statusFilter = ref.watch(dataQualityStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Quality'),
        actions: [
          PopupMenuButton<String?>(
            initialValue: statusFilter,
            onSelected: (value) =>
                ref.read(dataQualityStatusFilterProvider.notifier).state = value,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'resolved', child: Text('Resolved')),
              PopupMenuItem(value: 'ignored', child: Text('Ignored')),
              PopupMenuItem(value: null, child: Text('All')),
            ],
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load data quality issues.\n$e',
          onRetry: () => ref.invalidate(dataQualityListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No data quality issues.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dataQualityListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.issue),
                    subtitle: Text(
                      '${item.entityType ?? 'entity'} ${item.entityId ?? ''} · ${item.status}',
                    ),
                    trailing: item.status == 'open'
                        ? PopupMenuButton<String>(
                            onSelected: (status) =>
                                _updateStatus(context, ref, item, status),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'resolved', child: Text('Resolve')),
                              PopupMenuItem(value: 'ignored', child: Text('Ignore')),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    DataQualityIssue item,
    String status,
  ) async {
    try {
      await ref.read(dataQualityRepositoryProvider).resolve(item.id, status);
      ref.invalidate(dataQualityListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issue marked as $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }
}
