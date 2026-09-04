import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_controller.dart';
import '../admin_module_entry.dart';
import '../permission.dart';

class AdminHubScreen extends ConsumerWidget {
  const AdminHubScreen({
    super.key,
    required this.title,
    required this.modules,
  });

  final String title;
  final List<AdminModuleEntry> modules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final visible = modules.where((m) => can(user, m.permission)).toList();

    if (visible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          const AdminHubEmpty(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...visible.map(
          (module) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(module.icon),
              title: Text(module.title),
              subtitle: Text(module.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(module.route),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminHubEmpty extends StatelessWidget {
  const AdminHubEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No modules available for your permissions.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
