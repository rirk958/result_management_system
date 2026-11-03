
import 'dart:convert';

import '../core/api_client.dart';
import '../models/semester.dart';

class SemesterService {
  static dynamic _decodeResponse(dynamic response) {
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? data['message']?.toString()
          : null;
      throw Exception(message ?? 'Request failed (${response.statusCode})');
    }

    return data;
  }

  static Future<List<Semester>> getSemesters({
    int? programId,
  }) async {
    final query = programId == null ? '' : '?program_id=$programId';
    final response = await ApiClient.get('/semesters$query');
    final data = _decodeResponse(response);

    if (data is! List) {
      throw Exception('Invalid semesters response from server');
    }

    return data
        .map(
          (item) => Semester.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  static Future<Semester> getSemesterById(int id) async {
    final response = await ApiClient.get('/semesters/$id');
    final data = _decodeResponse(response);

    return Semester.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> createSemester({
    required int programId,
    required int semesterNumber,
    required String name,
  }) async {
    final response = await ApiClient.post(
      '/semesters',
      body: {
        'program_id': programId,
        'semester_number': semesterNumber,
        'name': name.trim(),
      },
    );

    _decodeResponse(response);
  }

  static Future<void> updateSemester({
    required int id,
    required int programId,
    required int semesterNumber,
    required String name,
  }) async {
    final response = await ApiClient.put(
      '/semesters/$id',
      body: {
        'program_id': programId,
        'semester_number': semesterNumber,
        'name': name.trim(),
      },
    );

    _decodeResponse(response);
  }

  static Future<void> updateSemesterStatus({
    required int id,
    required bool isActive,
  }) async {
    final response = await ApiClient.patch(
      '/semesters/$id/status',
      body: {'is_active': isActive},
    );

    _decodeResponse(response);
  }
}
