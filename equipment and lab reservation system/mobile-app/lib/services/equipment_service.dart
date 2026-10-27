import '../core/network/api_client.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  EquipmentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<EquipmentModel>> list({
    String search = '',
    String? condition,
    String? category,
  }) async {
    final query = <String, String>{};
    if (search.isNotEmpty) query['search'] = search;
    if (condition != null) query['condition'] = condition;
    if (category != null && category.isNotEmpty) query['category'] = category;
    final result = await _client.get(
      '/equipment/${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}',
    );
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) return [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(EquipmentModel.fromJson)
        .toList();
  }

  Future<EquipmentModel> get(int id) async {
    final result = await _client.get('/equipment/$id/');
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Equipment response was not valid.');
    }
    return EquipmentModel.fromJson(result);
  }

  Future<List<Map<String, dynamic>>> myLoans() async {
    final result = await _client.get('/loans/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) return [];
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> returnItem(int id, String condition) async {
    await _client.post('/loans/$id/return_item/', {
      'return_condition': condition,
    });
  }

  Future<void> checkOut(Map<String, Object?> details) async {
    await _client.post('/loans/', details);
  }

  Future<List<Map<String, dynamic>>> users() async {
    final result = await _client.get('/users/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) {
      throw const FormatException('User list response was not valid.');
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .where((user) => user['is_active'] == true)
        .toList();
  }
}
