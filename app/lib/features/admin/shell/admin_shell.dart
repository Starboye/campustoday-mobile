import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final permissions = user?.permissions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/brand/header-light.png', height: 40),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Admin — ${user?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            permissions.isEmpty
                ? 'Full admin access (default RBAC fallback).'
                : '${permissions.length} permissions assigned.',
          ),
          const SizedBox(height: 16),
          const _AdminPlaceholder(
            title: 'Dashboard',
            subtitle: 'KPIs and approvals — Phase 3',
          ),
          const _AdminPlaceholder(
            title: 'People',
            subtitle: 'Students & teachers — Phase 3',
          ),
          const _AdminPlaceholder(
            title: 'Ops',
            subtitle: 'Fees, planner, notifications — Phase 3–4',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Academics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ops'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
