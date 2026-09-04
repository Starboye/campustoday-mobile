import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/approvals_repository.dart';

final approvalsListProvider = FutureProvider.autoDispose<List<ApprovalItem>>((ref) {
  return ref.watch(approvalsRepositoryProvider).list(status: 'pending');
});
