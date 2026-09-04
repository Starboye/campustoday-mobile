import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/fees_repository.dart';
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
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add structure',
              onPressed: () => _addStructure(context, ref),
            ),
          ],
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
                  title: Text(item.name.isEmpty ? item.term : item.name),
                  subtitle: Text(item.term),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.amount.toStringAsFixed(2)),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await _editStructure(context, ref, item);
                          } else if (action == 'delete') {
                            await ref.read(feesRepositoryProvider).deleteStructure(item.id);
                            ref.invalidate(feeStructuresProvider);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.amount.toStringAsFixed(2)),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editPayment(context, ref, item),
                      ),
                    ],
                  ),
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

  Future<void> _addStructure(BuildContext context, WidgetRef ref) async {
    final term = TextEditingController();
    final amount = TextEditingController();
    final description = TextEditingController();

    await showAdminEditSheet(
      context: context,
      title: 'Add fee structure',
      fields: [
        TextField(controller: term, decoration: const InputDecoration(labelText: 'Term')),
        TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
      ],
      onSave: () async {
        await ref.read(feesRepositoryProvider).createStructure(
              term: term.text.trim(),
              amount: double.tryParse(amount.text.trim()) ?? 0,
              description: description.text.trim().isEmpty ? null : description.text.trim(),
            );
        ref.invalidate(feeStructuresProvider);
      },
    );

    term.dispose();
    amount.dispose();
    description.dispose();
  }

  Future<void> _editStructure(BuildContext context, WidgetRef ref, FeeStructure item) async {
    final term = TextEditingController(text: item.term);
    final amount = TextEditingController(text: item.amount.toString());
    final description = TextEditingController(text: item.name);

    await showAdminEditSheet(
      context: context,
      title: 'Edit fee structure',
      fields: [
        TextField(controller: term, decoration: const InputDecoration(labelText: 'Term')),
        TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
      ],
      onSave: () async {
        await ref.read(feesRepositoryProvider).updateStructure(
              item.id,
              term: term.text.trim(),
              amount: double.tryParse(amount.text.trim()),
              description: description.text.trim(),
            );
        ref.invalidate(feeStructuresProvider);
      },
    );

    term.dispose();
    amount.dispose();
    description.dispose();
  }

  Future<void> _editPayment(BuildContext context, WidgetRef ref, FeePayment item) async {
    final status = TextEditingController(text: item.status);
    final amountPaid = TextEditingController(text: item.amount.toString());

    await showAdminEditSheet(
      context: context,
      title: 'Update payment',
      fields: [
        TextField(controller: status, decoration: const InputDecoration(labelText: 'Status (paid/unpaid/partial)')),
        TextField(controller: amountPaid, decoration: const InputDecoration(labelText: 'Amount paid'), keyboardType: TextInputType.number),
      ],
      onSave: () async {
        await ref.read(feesRepositoryProvider).updatePayment(
              item.id,
              status: status.text.trim(),
              amountPaid: double.tryParse(amountPaid.text.trim()),
            );
        ref.invalidate(feePaymentsProvider);
      },
    );

    status.dispose();
    amountPaid.dispose();
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
