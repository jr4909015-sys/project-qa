class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.reservationId,
    this.readAt,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final int? reservationId;
  final DateTime? readAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        reservationId: json['reservation'] as int?,
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
      );
}
