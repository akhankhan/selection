class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? sentAt;
}
