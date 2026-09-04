import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fees_repository.dart';

final feeStructuresProvider = FutureProvider.autoDispose<List<FeeStructure>>((ref) {
  return ref.watch(feesRepositoryProvider).listStructures();
});

final feePaymentsProvider = FutureProvider.autoDispose<List<FeePayment>>((ref) {
  return ref.watch(feesRepositoryProvider).listPayments();
});
