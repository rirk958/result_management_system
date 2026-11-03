import 'dart:convert';

import '../core/api_client.dart';
import '../models/program.dart';

class ProgramService {
  static String _errorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // GET ALL ACTIVE PROGRAMS
  static Future<List<Program>> getPrograms({
    int? departmentId,
  }) async {
    var path = '/programs';

    if (departmentId != null) {
      path += '?department_id=$departmentId';
    }

    final response = await ApiClient.get(path);

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not load programs.'),
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((item) => Program.fromJson(item))
        .toList();
  }

  // CREATE PROGRAM
  static Future<void> createProgram({
    required int departmentId,
    required String code,
    required String name,
    required String degreeName,
    required int totalSemesters,
  }) async {
    final response = await ApiClient.post(
      '/programs',
      body: {
        'department_id': departmentId,
        'code': code.trim(),
        'name': name.trim(),
        'degree_name': degreeName.trim(),
        'total_semesters': totalSemesters,
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        _errorMessage(response.body, 'Could not create program.'),
      );
    }
  }

  // GET ONE PROGRAM
  static Future<Program> getProgramById(int id) async {
    final response = await ApiClient.get('/programs/$id');

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not load program details.'),
      );
    }

    return Program.fromJson(jsonDecode(response.body));
  }

  // UPDATE PROGRAM
  static Future<void> updateProgram({
    required int id,
    required int departmentId,
    required String code,
    required String name,
    required String degreeName,
    required int totalSemesters,
  }) async {
    final response = await ApiClient.put(
      '/programs/$id',
      body: {
        'department_id': departmentId,
        'code': code.trim(),
        'name': name.trim(),
        'degree_name': degreeName.trim(),
        'total_semesters': totalSemesters,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not update program.'),
      );
    }
  }

  // DEACTIVATE PROGRAM
  static Future<void> deactivateProgram(int id) async {
    final response = await ApiClient.patch(
      '/programs/$id/status',
      body: {},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response.body, 'Could not deactivate program.'),
      );
    }
  }
}