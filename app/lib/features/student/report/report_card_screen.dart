import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/student_repository.dart';

final reportCardProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(studentRepositoryProvider).fetchReportCard();
});

class ReportCardScreen extends ConsumerStatefulWidget {
  const ReportCardScreen({super.key});

  @override
  ConsumerState<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends ConsumerState<ReportCardScreen> {
  bool _downloading = false;

  Future<void> _sharePdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(studentRepositoryProvider).downloadReportPdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report-card.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My report card');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF unavailable: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportCardProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _sharePdf,
              icon: _downloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_downloading ? 'Generating…' : 'Download / Share PDF'),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load report card.\n$e')),
            data: (data) {
              final terms = data['terms'] as List<dynamic>? ?? [];
              if (terms.isEmpty) {
                return const Center(child: Text('No report card data.'));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(reportCardProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final term = terms[index] as Map<String, dynamic>;
                    final subjects = term['subjects'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Term ${term['term']}',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            ...subjects.map((s) {
                              final sub = s as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(sub['subject_name']?.toString() ?? '')),
                                    Text(
                                      sub['marks']?.toString() ?? '—',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
