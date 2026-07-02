class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final String time;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });
}