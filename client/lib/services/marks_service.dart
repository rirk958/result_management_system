
import 'dart:convert';

import '../core/api_client.dart';

class MarksService {
  static dynamic _decodeResponse(dynamic response) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'Request failed (${response.statusCode})');
    }

    return data;
  }

  /// Loads assessments.
  ///
  /// Requires GET /api/assessments to return a JSON array.
  static Future<List<Map<String, dynamic>>> getAssessments() async {
    final response = await ApiClient.get('/assessments');
    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid assessments response from server');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Loads marks for one assessment.
  ///
  /// Requires GET /api/assessments/:id/marks.
  static Future<List<Map<String, dynamic>>> getAssessmentMarks(
    int assessmentId,
  ) async {
    final response = await ApiClient.get(
      '/assessments/$assessmentId/marks',
    );

    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid marks response from server');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Saves marks for one assessment.
  ///
  /// Each entry must contain enrollment_id and obtained_marks.
  static Future<void> saveAssessmentMarks({
    required int assessmentId,
    required List<Map<String, dynamic>> marks,
  }) async {
    final response = await ApiClient.put(
      '/assessments/$assessmentId/marks',
      body: {'marks': marks},
    );

    _decodeResponse(response);
  }
}
