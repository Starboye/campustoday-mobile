import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/exam_timetable_providers.dart';

class ExamTimetableScreen extends ConsumerWidget {
  const ExamTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(examTimetableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam timetable')),
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load exam timetable.\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(examTimetableProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (response) {
          if (response.items.isEmpty) {
            return const Center(child: Text('No exam slots scheduled.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examTimetableProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: response.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slot = response.items[index];
                final date = DateTime.tryParse(slot.date);
                final dateLabel = date != null
                    ? DateFormat('EEE, d MMM yyyy').format(date)
                    : slot.date;
                final timeLabel = [
                  if (slot.startTime != null) slot.startTime,
                  if (slot.endTime != null) slot.endTime,
                ].join(' – ');

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(AppConstants.primaryColor),
                      ),
                    ),
                    title: Text(
                      slot.examName ?? slot.subjectName ?? 'Exam',
                      style: const TextStyle(
                        color: Color(AppConstants.navyColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (slot.classLabel.isNotEmpty) slot.classLabel,
                        if (slot.subjectName != null) slot.subjectName!,
                        dateLabel,
                        if (timeLabel.isNotEmpty) timeLabel,
                        if (slot.room != null) 'Room ${slot.room}',
                      ].join(' · '),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
