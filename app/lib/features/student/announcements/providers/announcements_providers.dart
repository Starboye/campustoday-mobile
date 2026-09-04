import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements_repository.dart';
import '../models/announcement_item.dart';

final announcementsProvider =
    FutureProvider.autoDispose<AnnouncementsResponse>((ref) async {
  return ref.watch(announcementsRepositoryProvider).fetchAnnouncements();
});

final markAnnouncementReadProvider =
    FutureProvider.autoDispose.family<void, int>((ref, id) async {
  await ref.watch(announcementsRepositoryProvider).markRead(id);
  ref.invalidate(announcementsProvider);
});
