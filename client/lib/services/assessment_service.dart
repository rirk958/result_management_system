
import 'dart:convert';

import '../core/api_client.dart';
import '../models/assessment.dart';

class AssessmentService {
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

  static Future<List<Assessment>> getAssessments() async {
    final response = await ApiClient.get('/assessments');
    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid assessments response from server');
    }

    return data
        .map(
          (item) => Assessment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<void> createAssessment({
    required int courseOfferingId,
    required String name,
    required double maxMarks,
  }) async {
    final response = await ApiClient.post(
      '/assessments',
      body: {
        'course_offering_id': courseOfferingId,
        'name': name.trim(),
        'max_marks': maxMarks,
      },
    );

    _decodeResponse(response);
  }

  static Future<void> updateAssessment({
    required int id,
    required int courseOfferingId,
    required String name,
    required double maxMarks,
  }) async {
    final response = await ApiClient.put(
      '/assessments/$id',
      body: {
        'course_offering_id': courseOfferingId,
        'name': name.trim(),
        'max_marks': maxMarks,
      },
    );

    _decodeResponse(response);
  }

  static Future<void> deleteAssessment(int id) async {
    final response = await ApiClient.delete('/assessments/$id');
    _decodeResponse(response);
  }
}
