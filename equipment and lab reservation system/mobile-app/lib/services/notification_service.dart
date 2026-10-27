import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<NotificationModel>> list() async {
    final result = await _client.get('/notifications/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) return [];
    return rows.whereType<Map<String, dynamic>>().map(NotificationModel.fromJson).toList();
  }

  Future<void> markRead(int id) async {
    await _client.post('/notifications/$id/mark_read/', {});
  }
}