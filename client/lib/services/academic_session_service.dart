import 'dart:convert';

import '../core/api_client.dart';
import '../models/academic_session.dart';

class AcademicSessionService {
  static String _errorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // GET ALL SESSIONS
  static Future<List<AcademicSession>> getSessions() async {
    final response = await ApiClient.get('/sessions');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not load academic sessions.'),
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => AcademicSession.fromJson(item))
        .toList();
  }

  // CREATE SESSION
  static Future<void> createSession({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await ApiClient.post(
      '/sessions',
      body: {
        'name': name.trim(),
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body, 'Could not create academic session.'),
      );
    }
  }

  // GET ONE SESSION
  static Future<AcademicSession> getSessionById(int id) async {
    final response = await ApiClient.get('/sessions/$id');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not load session details.'),
      );
    }

    return AcademicSession.fromJson(jsonDecode(response.body));
  }

  // UPDATE SESSION
  static Future<void> updateSession({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await ApiClient.put(
      '/sessions/$id',
      body: {
        'name': name.trim(),
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not update academic session.'),
      );
    }
  }

  // ACTIVATE OR DEACTIVATE SESSION
  static Future<void> updateSessionStatus({
    required int id,
    required bool isActive,
  }) async {
    final response = await ApiClient.patch(
      '/sessions/$id/status',
      body: {'is_active': isActive},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not update session status.'),
      );
    }
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}