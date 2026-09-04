import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../providers/fees_providers.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.fees)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Fees')),
        body: AdminEmptyView(message: 'You do not have fees access.'),
      );
    }

    final structuresAsync = ref.watch(feeStructuresProvider);
    final paymentsAsync = ref.watch(feePaymentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fees'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Structures'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            structuresAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load structures.\n$e',
                onRetry: () => ref.invalidate(feeStructuresProvider),
              ),
              data: (items) => _buildList(
                items,
                (item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.term),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                ),
                'No fee structures.',
                () => ref.invalidate(feeStructuresProvider),
              ),
            ),
            paymentsAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load payments.\n$e',
                onRetry: () => ref.invalidate(feePaymentsProvider),
              ),
              data: (items) => _buildList(
                items,
                (item) => ListTile(
                  title: Text(item.studentName),
                  subtitle: Text(item.status),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                ),
                'No payments found.',
                () => ref.invalidate(feePaymentsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList<T>(
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
}
