import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import '../models/exam_timetable_models.dart';
import '../providers/exam_timetable_providers.dart';

class ExamTimetableScreen extends ConsumerWidget {
  const ExamTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(examTimetableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam timetable')),
      body: timetableAsync.when(
        loading: () => const LoadingContent(),
        error: (e, _) => ErrorContent(
          message: 'Could not load exam timetable.\n$e',
          onRetry: () => ref.invalidate(examTimetableProvider),
        ),
        data: (slots) {
          if (slots.isEmpty) {
            return const EmptyContent(
              message: 'No exam timetable entries yet.',
              icon: Icons.calendar_month_outlined,
            );
          }

          final byDate = <String, List<ExamTimetableSlot>>{};
          for (final slot in slots) {
            final key = slot.date.isNotEmpty ? slot.date : 'Unknown date';
            byDate.putIfAbsent(key, () => []).add(slot);
          }

          final dates = byDate.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examTimetableProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final dateKey = dates[index];
                final daySlots = byDate[dateKey]!;
                final parsed = DateTime.tryParse(dateKey);
                final label =
                    parsed != null ? DateFormat('EEE, d MMM yyyy').format(parsed) : dateKey;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(AppConstants.navyColor),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...daySlots.map((slot) => _ExamSlotCard(slot: slot)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({required this.slot});

  final ExamTimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (slot.classLabel.isNotEmpty) slot.classLabel,
      if (slot.startTime != null && slot.endTime != null)
        '${slot.startTime} – ${slot.endTime}'
      else if (slot.startTime != null)
        slot.startTime!,
      if (slot.room != null && slot.room!.isNotEmpty) 'Room ${slot.room}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
          child: const Icon(Icons.school_outlined, color: Color(AppConstants.primaryColor)),
        ),
        title: Text(
          slot.subjectName ?? slot.examName ?? 'Exam',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(' · ')) : null,
        trailing: slot.examName != null && slot.subjectName != null
            ? Text(slot.examName!, style: Theme.of(context).textTheme.bodySmall)
            : null,
      ),
    );
  }
}
