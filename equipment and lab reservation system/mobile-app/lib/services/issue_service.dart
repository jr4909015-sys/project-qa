import '../core/network/api_client.dart';

class IssueService {
  IssueService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final result = await _client.get('/issues/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) {
      throw const FormatException('Issue report response was not valid.');
    }
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> create({
    required String description,
    int? equipmentId,
    int? laboratoryId,
    String? photoPath,
  }) async {
    await _client.uploadFile('/issues/', {
      'description': description,
      if (equipmentId != null) 'equipment': equipmentId.toString(),
      if (laboratoryId != null) 'laboratory': laboratoryId.toString(),
    }, filePath: photoPath);
  }
}
