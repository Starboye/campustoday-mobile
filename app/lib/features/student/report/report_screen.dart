import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'data/report_repository.dart';
import 'models/report_term.dart';
import 'providers/report_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  Future<void> _downloadAndShare(
    BuildContext context,
    WidgetRef ref,
    ReportTerm term,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Downloading report card…')),
      );

      final bytes = await ref.read(reportRepositoryProvider).downloadPdf(term.termId);
      if (bytes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Report PDF is empty or unavailable.')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final safeName = term.termName.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final file = File('${dir.path}/report_$safeName.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${term.termName} Report Card',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportCardProvider);

    return reportAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load report card.\n$e',
        onRetry: () => ref.invalidate(reportCardProvider),
      ),
      data: (response) {
        if (response.terms.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reportCardProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyContent(
                  message: 'No report cards published yet.',
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportCardProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: response.terms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final term = response.terms[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term.termName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(AppConstants.navyColor),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (term.academicYear != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          term.academicYear!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (term.overallGrade != null)
                            _ReportStat(label: 'Grade', value: term.overallGrade!),
                          if (term.percentage != null) ...[
                            const SizedBox(width: 24),
                            _ReportStat(
                              label: 'Average',
                              value: '${term.percentage!.toStringAsFixed(1)}%',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: term.pdfAvailable
                              ? () => _downloadAndShare(context, ref, term)
                              : null,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Download PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(AppConstants.primaryColor),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
