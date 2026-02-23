class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'ABUS_NEARBY' | 'REPORT_CONFIRMED'
  final bool read;
  final Map<String, dynamic> data;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String? ?? '',
        read: j['read'] as bool? ?? false,
        data: (j['data'] as Map<String, dynamic>?) ?? {},
        createdAt: j['createdAt'] as String? ?? '',
      );

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        data: data,
        createdAt: createdAt,
      );
}
