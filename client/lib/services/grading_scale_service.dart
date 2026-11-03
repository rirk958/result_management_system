
import 'dart:convert';

import '../core/api_client.dart';
import '../models/grading_scale.dart';

class GradingScaleService {
  static Future<List<GradingScale>> getGradingScales() async {
    final response = await ApiClient.get('/grading-scales');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load grading scales: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> rows;

    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      rows = decoded['data'] as List;
    } else {
      throw Exception('Unexpected grading scales response.');
    }

    return rows
        .map(
          (row) => GradingScale.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> createGradingScale({
    required double minMarks,
    required double maxMarks,
    required String letterGrade,
    required double gradePoint,
    required String description,
  }) async {
    final response = await ApiClient.post('/grading-scales', body:{
      'min_marks': minMarks,
      'max_marks': maxMarks,
      'letter_grade': letterGrade,
      'grade_point': gradePoint,
      'description': description,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create grading scale: ${response.body}');
    }
  }

  static Future<void> updateGradingScale({
    required int id,
    required double minMarks,
    required double maxMarks,
    required String letterGrade,
    required double gradePoint,
    required String description,
  }) async {
    final response = await ApiClient.put('/grading-scales/$id', body: {
      'min_marks': minMarks,
      'max_marks': maxMarks,
      'letter_grade': letterGrade,
      'grade_point': gradePoint,
      'description': description,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update grading scale: ${response.body}');
    }
  }

  static Future<void> deleteGradingScale(int id) async {
    final response = await ApiClient.delete('/grading-scales/$id');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete grading scale: ${response.body}');
    }
  }
}
