class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.message,
    required this.postedAt,
    required this.isRead,
    this.priority,
  });

  final int id;
  final String title;
  final String message;
  final String postedAt;
  final bool isRead;
  final String? priority;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      postedAt: json['posted_at'] as String? ?? json['created_at'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      priority: json['priority'] as String?,
    );
  }
}

class AnnouncementsResponse {
  const AnnouncementsResponse({required this.items});

  final List<AnnouncementItem> items;

  factory AnnouncementsResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementsResponse(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
