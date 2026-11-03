
import 'dart:convert';

import '../core/api_client.dart';
import '../models/department.dart';

class DepartmentService {
  static String _errorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // GET ALL DEPARTMENTS
  static Future<List<Department>> getDepartments() async {
    final response = await ApiClient.get('/departments');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not load departments.'),
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> departments = data['departments'] ?? [];

    return departments
        .map((item) => Department.fromJson(item))
        .toList();
  }

  // CREATE DEPARTMENT
  static Future<void> createDepartment({
    required String code,
    required String name,
  }) async {
    final response = await ApiClient.post(
      '/departments',
      body: {
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body, 'Could not create department.'),
      );
    }
  }

  // UPDATE DEPARTMENT
  static Future<void> updateDepartment({
    required int id,
    required String code,
    required String name,
  }) async {
    final response = await ApiClient.put(
      '/departments/$id',
      body: {
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not update department.'),
      );
    }
  }

  // ACTIVATE OR DEACTIVATE DEPARTMENT
  static Future<void> updateDepartmentStatus({
    required int id,
    required bool isActive,
  }) async {
    final response = await ApiClient.patch(
      '/departments/$id/status',
      body: {
        'is_active': isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not update department status.'),
      );
    }
  }
}
