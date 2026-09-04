import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../providers/planner_providers.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.planner)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Planner')),
        body: AdminEmptyView(message: 'You do not have planner access.'),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planner'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Slots'),
              Tab(text: 'Assignments'),
              Tab(text: 'Timetables'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlannerTab(
              asyncValue: ref.watch(plannerSlotsProvider),
              onRetry: () => ref.invalidate(plannerSlotsProvider),
              builder: (items, width) => _gridOrList(
                width: width,
                items: items,
                tile: (slot) => ListTile(
                  title: Text('${slot.day} · Period ${slot.period}'),
                  subtitle: Text(slot.className),
                ),
              ),
            ),
            _PlannerTab(
              asyncValue: ref.watch(plannerAssignmentsProvider),
              onRetry: () => ref.invalidate(plannerAssignmentsProvider),
              builder: (items, width) => _gridOrList(
                width: width,
                items: items,
                tile: (a) => ListTile(
                  title: Text(a.subject),
                  subtitle: Text('${a.teacherName} · ${a.className}'),
                ),
              ),
            ),
            _PlannerTab(
              asyncValue: ref.watch(plannerTimetablesProvider),
              onRetry: () => ref.invalidate(plannerTimetablesProvider),
              builder: (items, width) => _gridOrList(
                width: width,
                items: items,
                tile: (t) => ListTile(
                  title: Text(t.className),
                  subtitle: Text('${t.entries} entries'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridOrList<T>({
    required double width,
    required List<T> items,
    required Widget Function(T) tile,
  }) {
    if (items.isEmpty) {
      return const AdminEmptyView(message: 'No items.');
    }
    final useGrid = width >= 600;
    if (useGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => Card(child: tile(items[i])),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => Card(child: tile(items[i])),
    );
  }
}

class _PlannerTab<T> extends StatelessWidget {
  const _PlannerTab({
    required this.asyncValue,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<List<T>> asyncValue;
  final VoidCallback onRetry;
  final Widget Function(List<T> items, double width) builder;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const AdminLoadingView(),
      error: (e, _) => AdminErrorView(
        message: 'Could not load planner data.\n$e',
        onRetry: onRetry,
      ),
      data: (items) => LayoutBuilder(
        builder: (context, constraints) => builder(items, constraints.maxWidth),
      ),
    );
  }
}
