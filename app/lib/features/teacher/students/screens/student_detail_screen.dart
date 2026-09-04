import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/student_models.dart';
import '../providers/students_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossierAsync = ref.watch(studentDossierProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student dossier')),
      body: dossierAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load student.\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(studentDossierProvider(studentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (dossier) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentDossierProvider(studentId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(profile: dossier.profile),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Marks', icon: Icons.grade_outlined),
              if (dossier.marks.isEmpty)
                const _EmptySection(message: 'No marks recorded.')
              else
                ...dossier.marks.map((m) => _MarkTile(mark: m)),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Attendance', icon: Icons.fact_check_outlined),
              if (dossier.attendance.isEmpty)
                const _EmptySection(message: 'No attendance records.')
              else
                ...dossier.attendance.take(10).map((a) => _AttendanceTile(entry: a)),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Homework', icon: Icons.assignment_outlined),
              if (dossier.homework.isEmpty)
                const _EmptySection(message: 'No homework assigned.')
              else
                ...dossier.homework.take(10).map((h) => _HomeworkTile(entry: h)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final fields = <String, String?>{
      'Class': profile.classLabel.isNotEmpty ? profile.classLabel : null,
      'Email': profile.email,
      'Phone': profile.phone,
      'Father': profile.fatherName,
      'Mother': profile.motherName,
      'Date of birth': profile.dob,
      'Gender': profile.gender,
      'Blood group': profile.bloodGroup,
      'Address': profile.address,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text('ID: ${profile.id}', style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 24),
            ...fields.entries.where((e) => e.value != null && e.value!.isNotEmpty).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ),
                        Expanded(child: Text(e.value!)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(AppConstants.primaryColor)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(AppConstants.navyColor),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.mark});

  final StudentMarkRow mark;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (mark.term != null) 'Term ${mark.term}',
      if (mark.examType != null) mark.examType!,
      if (mark.grade != null) 'Grade ${mark.grade}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(mark.subjectName),
        subtitle: details.isNotEmpty ? Text(details.join(' · ')) : null,
        trailing: Text(
          '${mark.marks ?? '—'}${mark.maxMarks != null ? ' / ${mark.maxMarks}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.entry});

  final StudentAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(entry.date);
    final label = date != null ? DateFormat('d MMM yyyy').format(date) : entry.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          'AM: ${entry.morning ?? '—'} · PM: ${entry.afternoon ?? '—'} · EV: ${entry.evening ?? '—'}',
        ),
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({required this.entry});

  final StudentHomeworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(entry.date);
    final label = date != null ? DateFormat('d MMM yyyy').format(date) : entry.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(entry.title),
        subtitle: Text('${entry.subjectName} · $label'),
        trailing: entry.isMine
            ? const Icon(Icons.person_outline, size: 18)
            : null,
      ),
    );
  }
}
