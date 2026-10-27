import '../core/network/api_client.dart';
import '../models/reservation_model.dart';

class ReservationService {
  ReservationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ReservationModel?> get(int id) async {
    final result = await _client.get('/reservations/$id/');
    if (result is! Map<String, dynamic>) return null;
    return ReservationModel.fromJson(result);
  }

  Future<List<ReservationModel>> list() async {
    final result = await _client.get('/reservations/');
    final rows = result is Map<String, dynamic> ? result['results'] : result;
    if (rows is! List) return [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ReservationModel.fromJson)
        .toList();
  }

  Future<Object?> create(Map<String, Object?> data) =>
      _client.post('/reservations/', data);

  Future<void> cancel(int id) async {
    await _client.post('/reservations/$id/cancel/', {});
  }

  Future<Map<String, dynamic>> availability({
    required String resourceType,
    required int resourceId,
    required DateTime date,
    int quantity = 1,
  }) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final result = await _client.get(
      '/reservations/availability/?resource_type=$resourceType&resource_id=$resourceId&date=$day&quantity=$quantity&utc_offset_minutes=${date.timeZoneOffset.inMinutes}',
    );
    if (result is! Map<String, dynamic> || result['slots'] is! List) {
      throw const FormatException('Availability response was not valid.');
    }
    return result;
  }

  Future<void> requestReschedule(
    int id, {
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    await _client.post('/reservations/$id/request_reschedule/', {
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    });
  }
}
