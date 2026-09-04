import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.analytics)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Analytics')),
        body: AdminEmptyView(message: 'You do not have analytics access.'),
      );
    }

    final dataAsync = ref.watch(analyticsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: dataAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load analytics.\n$e',
          onRetry: () => ref.invalidate(analyticsDataProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(analyticsDataProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChartCard(title: 'Enrollment', values: data.enrollmentTrend),
              const SizedBox(height: 16),
              _ChartCard(title: 'Attendance', values: data.attendanceTrend),
              const SizedBox(height: 16),
              _ChartCard(title: 'Fee collection', values: data.feeTrend),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.values});

  final String title;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final spots = values.isEmpty
        ? [const FlSpot(0, 0), const FlSpot(1, 0)]
        : List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(AppConstants.primaryColor),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
