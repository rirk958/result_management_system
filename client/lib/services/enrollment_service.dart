
import 'dart:convert';

import '../core/api_client.dart';
import '../models/enrollment.dart';

class EnrollmentService {
  static List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (decoded is Map) {
      final list = decoded['enrollments'] ??
          decoded['data'];

      if (list is List) {
        return list
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }

    throw Exception('Unexpected enrollments response.');
  }

  static Future<List<Enrollment>> getEnrollments() async {
    final response = await ApiClient.get('/enrollments');
    print('Enrollments status: ${response.statusCode}');
    print('Enrollments body: ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load enrollments: ${response.body}');
    }

    return _decodeList(response.body).map(Enrollment.fromJson).toList();
  }

  static Future<void> createEnrollment({
    required int studentId,
    required int courseOfferingId,
  }) async {
    final response = await ApiClient.post('/enrollments', body:{
      'student_id': studentId,
      'course_offering_id': courseOfferingId,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to enroll student: ${response.body}');
    }
  }

  static Future<void> updateEnrollment({
    required int id,
    required int studentId,
    required int courseOfferingId,
  }) async {
    final response = await ApiClient.put('/enrollments/$id', body:{
      'student_id': studentId,
      'course_offering_id': courseOfferingId,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update enrollment: ${response.body}');
    }
  }

  static Future<void> deleteEnrollment(int id) async {
    final response = await ApiClient.delete('/enrollments/$id');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to remove enrollment: ${response.body}');
    }
  }
}
