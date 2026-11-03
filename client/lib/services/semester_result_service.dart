
import 'dart:convert';

import '../core/api_client.dart';
import '../models/semester_result.dart';

class SemesterResultService {
  static dynamic _decodeResponse(dynamic response) {
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
      data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Request failed (${response.statusCode})',
      );
    }

    return data;
  }

  static Future<List<SemesterResult>> getSemesterResults({
    int? studentId,
    int? semesterId,
    int? sessionId,
    String? status,
  }) async {
    final params = <String, String>{};

    if (studentId != null) {
      params['student_id'] = '$studentId';
    }
    if (semesterId != null) {
      params['semester_id'] = '$semesterId';
    }
    if (sessionId != null) {
      params['session_id'] = '$sessionId';
    }
    if (status != null && status != 'all') {
      params['status'] = status;
    }

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((entry) {
      return '${Uri.encodeQueryComponent(entry.key)}='
          '${Uri.encodeQueryComponent(entry.value)}';
    }).join('&')}';

    final response =
    await ApiClient.get('/semester-results$query');
    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid semester results response');
    }

    return data
        .map(
          (item) => SemesterResult.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  static Future<SemesterResult> getSemesterResultById(int id) async {
    final response = await ApiClient.get('/semester-results/$id');
    final data = _decodeResponse(response);

    return SemesterResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<Map<String, dynamic>> calculateSemesterResult({
    required int studentId,
    required int semesterId,
    required int sessionId,
  }) async {
    final response = await ApiClient.post(
      '/semester-results/calculate',
      body: {
        'student_id': studentId,
        'semester_id': semesterId,
        'session_id': sessionId,
      },
    );

    final data = _decodeResponse(response);

    if (data is! Map) {
      throw Exception('Invalid semester calculation response');
    }

    return Map<String, dynamic>.from(data);
  }

  // Fetch only the logged-in student's published results.
  static Future<List<SemesterResult>> getMyPublishedResults() async {
    final response = await ApiClient.get(
      '/my/published-results',
    );

    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid published results response');
    }

    return data
        .map(
          (item) => SemesterResult.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }
  
}
