import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fees_repository.dart';
import '../models/fee_term.dart';

final feesProvider = FutureProvider.autoDispose<FeesResponse>((ref) async {
  return ref.watch(feesRepositoryProvider).fetchFees();
});
