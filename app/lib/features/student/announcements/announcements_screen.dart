import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'models/announcement_item.dart';
import 'providers/announcements_providers.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return announcementsAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load announcements.\n$e',
        onRetry: () => ref.invalidate(announcementsProvider),
      ),
      data: (response) {
        if (response.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyContent(
                  message: 'No announcements yet.',
                  icon: Icons.notifications_none,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(announcementsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: response.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = response.items[index];
              return _AnnouncementCard(
                item: item,
                dateLabel: _formatDate(item.postedAt),
                onTap: () async {
                  if (!item.isRead) {
                    await ref.read(announcementsRepositoryProvider).markRead(item.id);
                    ref.invalidate(announcementsProvider);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  final AnnouncementItem item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = item.isRead == false;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Color(AppConstants.primaryColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(AppConstants.navyColor),
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (item.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.message),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
