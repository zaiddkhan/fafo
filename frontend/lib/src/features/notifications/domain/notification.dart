/// A single in-app notification (mirror of a dispatched push).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.templateId,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String templateId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      templateId: json['template_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

/// A page of notifications plus the current unread count (drives the badge).
class NotificationList {
  const NotificationList({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
    return NotificationList(
      items: items,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
