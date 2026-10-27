import '../core/network/api_client.dart';

class UserManagementService {
  UserManagementService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final result = await _client.get('/users/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) {
      throw const FormatException('User list response was not valid.');
    }
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> create(Map<String, Object?> values) async {
    await _client.post('/users/', values);
  }

  Future<void> update(int id, Map<String, Object?> values) async {
    await _client.patch('/users/$id/', values);
  }
}
