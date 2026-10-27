import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({http.Client? client, SecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? SecureStorage();

  final http.Client _client;
  final SecureStorage _storage;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Object?> get(String path) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<Object?> patch(String path, Map<String, Object?> body) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Object?> post(String path, Map<String, Object?> body) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Object?> uploadFile(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'photo',
    String method = 'POST',
  }) async {
    final request = http.MultipartRequest(
      method,
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );
    request.headers['Accept'] = 'application/json';
    final token = await _storage.readAccessToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileField, File(filePath).path),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Object? _decode(http.Response response) {
    final payload = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, payload);
    }
    return payload;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.payload);

  final int statusCode;
  final Object? payload;

  @override
  String toString() => 'Request failed ($statusCode)';
}
