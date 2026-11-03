
import 'dart:convert';

import '../core/api_client.dart';
import '../models/course_result.dart';

class CourseResultService {
  static dynamic _decodeResponse(dynamic response) {
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'Request failed (${response.statusCode})');
    }

    return data;
  }

  static Future<List<CourseResult>> getCourseResults({
    int? studentId,
    int? courseId,
    int? sessionId,
    String? status,
  }) async {
    final parameters = <String, String>{};

    if (studentId != null) {
      parameters['student_id'] = studentId.toString();
    }
    if (courseId != null) {
      parameters['course_id'] = courseId.toString();
    }
    if (sessionId != null) {
      parameters['session_id'] = sessionId.toString();
    }
    if (status != null && status != 'all') {
      parameters['status'] = status;
    }

    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';

    final response = await ApiClient.get('/course-results$query');
    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid course results response from server');
    }

    return data
        .map(
          (item) => CourseResult.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> getCourseResultById(int id) async {
    final response = await ApiClient.get('/course-results/$id');
    final data = _decodeResponse(response);

    if (data is! Map) {
      throw Exception('Invalid course result response from server');
    }

    return Map<String, dynamic>.from(data);
  }
}
