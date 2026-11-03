
import 'dart:convert';

import '../core/api_client.dart';
import '../models/course_offering.dart';

class CourseOfferingService {
  static List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (decoded is Map) {
      final list = decoded['offerings'] ??
          decoded['data'];

      if (list is List) {
        return list
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }

    throw Exception('Unexpected course offerings response.');
  }

  static Future<List<Map<String, dynamic>>> getCourseOfferings() async {
    final response = await ApiClient.get('/course-offerings');
    print('Course offerings status: ${response.statusCode}');
    print('Course offerings body: ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load course offerings: ${response.body}',
      );
    }

    return _decodeList(response.body);
  }

  static Future<List<CourseOffering>> getOfferingModels() async {
    final rows = await getCourseOfferings();

    return rows.map(CourseOffering.fromJson).toList();
  }

  static Future<void> createCourseOffering({
    required int courseId,
    required int sessionId,
  }) async {
    final response = await ApiClient.post(
      '/course-offerings',
      body:{
        'course_id': courseId,
        'session_id': sessionId,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create course offering: ${response.body}');
    }
  }

  static Future<void> updateCourseOffering({
    required int id,
    required int courseId,
    required int sessionId,
  }) async {
    final response = await ApiClient.put(
      '/course-offerings/$id',
      body:{
        'course_id': courseId,
        'session_id': sessionId,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update course offering: ${response.body}');
    }
  }

  static Future<void> deleteCourseOffering(int id) async {
    final response = await ApiClient.delete('/course-offerings/$id');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete course offering: ${response.body}');
    }
  }
}
