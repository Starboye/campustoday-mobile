import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../models/report_term.dart';

final reportCardProvider = FutureProvider.autoDispose<ReportCardResponse>((ref) async {
  return ref.watch(reportRepositoryProvider).fetchReportCard();
});

final reportPdfDownloadProvider =
    FutureProvider.autoDispose.family<List<int>, int>((ref, termId) async {
  final bytes = await ref.watch(reportRepositoryProvider).downloadPdf(termId);
  return bytes;
});
