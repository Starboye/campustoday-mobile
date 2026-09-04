import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'models/fee_term.dart';
import 'providers/fees_providers.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount);
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'paid' => Colors.green,
      'partial' => Colors.orange,
      'overdue' => Colors.red,
      _ => const Color(AppConstants.primaryColor),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesProvider);

    return feesAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load fees.\n$e',
        onRetry: () => ref.invalidate(feesProvider),
      ),
      data: (response) {
        if (response.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(feesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyContent(
                  message: 'No fee records found.',
                  icon: Icons.receipt_long_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(feesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: response.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final term = response.items[index];
              return _FeeCard(
                term: term,
                formatCurrency: _formatCurrency,
                statusColor: _statusColor(term.status),
              );
            },
          ),
        );
      },
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.term,
    required this.formatCurrency,
    required this.statusColor,
  });

  final FeeTerm term;
  final String Function(double) formatCurrency;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    term.termName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(AppConstants.navyColor),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    term.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(label: 'Due', value: formatCurrency(term.amountDue)),
                ),
                Expanded(
                  child: _AmountColumn(label: 'Paid', value: formatCurrency(term.amountPaid)),
                ),
              ],
            ),
            if (term.dueDate != null && term.dueDate!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Due: ${term.dueDate}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
