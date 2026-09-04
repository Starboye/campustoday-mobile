import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'change_password_screen.dart';
import 'providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final authUser = ref.watch(authControllerProvider).value;

    return profileAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load profile.\n$e',
        onRetry: () => ref.invalidate(studentProfileProvider),
      ),
      data: (profile) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentProfileProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                      child: Text(
                        (profile.displayName ?? profile.name).isNotEmpty
                            ? (profile.displayName ?? profile.name)[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(AppConstants.primaryColor),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName ?? profile.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(AppConstants.navyColor),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text('Username: ${profile.name}'),
                          Text('ID: ${profile.id}'),
                          if (profile.classLabel.isNotEmpty)
                            Text(
                              profile.classLabel,
                              style: const TextStyle(
                                color: Color(AppConstants.primaryColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/student/change-password?required=false'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    title: Text(
                      'Sign out',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
            if (authUser?.forcePasswordReset == true) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: const ListTile(
                  leading: Icon(Icons.warning_amber_rounded),
                  title: Text('You must change your password before continuing.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
