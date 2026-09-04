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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useMasterDetail = constraints.maxWidth >= 900;

        if (useMasterDetail) {
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
                  _masterDetailTab(
                    ref.watch(plannerSlotsProvider),
                    () => ref.invalidate(plannerSlotsProvider),
                    (slot) => '${slot.day} · Period ${slot.period}',
                    (slot) => slot.className,
                  ),
                  _masterDetailTab(
                    ref.watch(plannerAssignmentsProvider),
                    () => ref.invalidate(plannerAssignmentsProvider),
                    (a) => a.subject,
                    (a) => '${a.teacherName} · ${a.className}',
                  ),
                  _masterDetailTab(
                    ref.watch(plannerTimetablesProvider),
                    () => ref.invalidate(plannerTimetablesProvider),
                    (t) => t.className,
                    (t) => '${t.entries} entries',
                  ),
                ],
              ),
            ),
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
      },
    );
  }

  Widget _masterDetailTab<T>(
    AsyncValue<List<T>> asyncValue,
    VoidCallback onRetry,
    String Function(T) title,
    String Function(T) subtitle,
  ) {
    return asyncValue.when(
      loading: () => const AdminLoadingView(),
      error: (e, _) => AdminErrorView(message: 'Could not load planner data.\n$e', onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) return const AdminEmptyView(message: 'No items.');
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text(title(item)),
                    subtitle: Text(subtitle(item)),
                  );
                },
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title(item), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(subtitle(item)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
