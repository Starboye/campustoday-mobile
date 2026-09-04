import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.dashboard)) {
      return const AdminEmptyView(message: 'You do not have dashboard access.');
    }

    final statsAsync = ref.watch(dashboardStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Welcome, ${user?.name ?? ''}'),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const AdminLoadingView(),
            error: (e, _) => AdminErrorView(
              message: 'Could not load KPIs.\n$e',
              onRetry: () => ref.invalidate(dashboardStatsProvider),
            ),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Students',
                        value: '${stats.studentCount}',
                        icon: Icons.school_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        label: 'Teachers',
                        value: '${stats.teacherCount}',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Attendance',
                        value: '${stats.attendanceToday.toStringAsFixed(1)}%',
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        label: 'Fees Collected',
                        value: '${stats.feeCollection.toStringAsFixed(0)}%',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                if (can(user, AdminPermissions.approvals) && stats.pendingApprovals > 0) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                        child: Text('${stats.pendingApprovals}'),
                      ),
                      title: const Text('Pending approvals'),
                      subtitle: const Text('Review requests awaiting action'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin/home/approvals'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(AppConstants.primaryColor)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
