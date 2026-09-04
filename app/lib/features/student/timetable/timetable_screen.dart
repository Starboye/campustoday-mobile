import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'providers/timetable_providers.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableProvider);

    return timetableAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load timetable.\n$e',
        onRetry: () => ref.invalidate(timetableProvider),
      ),
      data: (response) {
        if (!response.isApproved || response.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(timetableProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                EmptyContent(
                  message: response.message ??
                      'Timetable is not available yet (${response.status}).',
                  icon: Icons.calendar_month_outlined,
                ),
              ],
            ),
          );
        }

        final byDay = response.itemsByDay;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(timetableProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: byDay.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final dayName = byDay.keys.elementAt(index);
              final items = byDay[dayName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(AppConstants.navyColor),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                          child: Text(
                            '${item.period}',
                            style: const TextStyle(
                              color: Color(AppConstants.primaryColor),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          item.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: item.startTime != null && item.endTime != null
                            ? Text('${item.startTime} – ${item.endTime}')
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
