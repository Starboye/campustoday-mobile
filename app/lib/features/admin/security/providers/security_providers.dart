import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/security_repository.dart';

final loginAuditProvider = FutureProvider.autoDispose<List<LoginAuditEntry>>((ref) {
  final status = ref.watch(loginAuditStatusFilterProvider);
  return ref.watch(securityRepositoryProvider).loginAudit(status: status);
});

final loginAuditStatusFilterProvider = StateProvider<String?>((ref) => null);
