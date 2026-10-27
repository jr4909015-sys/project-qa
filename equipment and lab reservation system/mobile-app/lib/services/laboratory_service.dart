import '../core/network/api_client.dart';
import '../models/laboratory_model.dart';

class LaboratoryService {
  LaboratoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<LaboratoryModel>> list({
    String search = '',
    String building = '',
    int? minimumCapacity,
  }) async {
    final query = <String, String>{};
    if (search.isNotEmpty) query['search'] = search;
    if (building.isNotEmpty) query['building'] = building;
    if (minimumCapacity != null && minimumCapacity > 0) {
      query['min_capacity'] = minimumCapacity.toString();
    }
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final result = await _client.get('/laboratories/$suffix');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) return [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(LaboratoryModel.fromJson)
        .toList();
  }

  Future<LaboratoryModel> get(int id) async {
    final result = await _client.get('/laboratories/$id/');
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Laboratory response was not valid.');
    }
    return LaboratoryModel.fromJson(result);
  }
}
