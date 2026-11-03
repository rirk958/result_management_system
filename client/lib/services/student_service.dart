import 'dart:convert';

import '../core/api_client.dart';
import '../models/student.dart';

class StudentService {
  static String _errorMessage(dynamic body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}

    return fallback;
  }

  // Get one student by ID
  static Future<Student> getStudentById(int id) async {
    final response = await ApiClient.get('/students/$id');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['message']?.toString() ?? 'Could not load student details.',
      );
    }

    return Student.fromJson(data);
  }

// Update student academic information
  static Future<void> updateStudent({
    required int id,
    required String studentNo,
    required int programId,
    required int sessionId,
    required String admissionDate,
  }) async {
    final response = await ApiClient.put(
      '/students/$id',
      body: {
        'student_no': studentNo,
        'program_id': programId,
        'session_id': sessionId,
        'admission_date': admissionDate,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['message']?.toString() ?? 'Could not update student.',
      );
    }
  }

// Change student status
  static Future<void> updateStudentStatus({
    required int id,
    required String status,
  }) async {
    final response = await ApiClient.patch(
      '/students/$id/status',
      body: {
        'status': status,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['message']?.toString() ?? 'Could not update student status.',
      );
    }
  }

  static Future<int> createStudentAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/users',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': 'student',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message']?.toString() ?? 'Could not create user account.',
      );
    }

    final user = data['user'];
    if (user == null || user['id'] == null) {
      throw Exception('Account was created, but the server did not return its ID.');
    }

    return int.parse(user['id'].toString());
  }

  static Future<void> createStudentProfile({
    required int userId,
    required String studentNo,
    required int programId,
    required int sessionId,
    required String admissionDate,
  }) async {
    final response = await ApiClient.post(
      '/students',
      body: {
        'user_id': userId,
        'student_no': studentNo,
        'program_id': programId,
        'session_id': sessionId,
        'admission_date': admissionDate,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message']?.toString() ?? 'Could not create student profile.',
      );
    }
  }

  static Future<List<Student>> getStudents() async {
    final response = await ApiClient.get('/students');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Failed to load students'),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Unexpected student data received from server');
    }

    return data
        .map((item) => Student.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getPrograms() async {
    final response = await ApiClient.get('/programs');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Failed to load programs'),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Unexpected program data received');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['is_active'] == true)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await ApiClient.get('/sessions');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Failed to load sessions'),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Unexpected session data received');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['is_active'] == true)
        .toList();
  }
}