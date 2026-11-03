
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/course_offering.dart';
import '../services/course_offering_service.dart';

class CourseOfferingFormDialog extends StatefulWidget {
  final CourseOffering? offering;

  const CourseOfferingFormDialog({
    super.key,
    this.offering,
  });

  @override
  State<CourseOfferingFormDialog> createState() =>
      _CourseOfferingFormDialogState();
}

class _CourseOfferingFormDialogState
    extends State<CourseOfferingFormDialog> {
  static const Color _orange = Color(0xFFF97316);

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _sessions = [];

  int? _courseId;
  int? _sessionId;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.offering != null;

  @override
  void initState() {
    super.initState();
    _courseId = widget.offering?.courseId;
    _sessionId = widget.offering?.sessionId;
    _loadOptions();
  }

  Future<List<Map<String, dynamic>>> _loadList(
    String endpoint,
  ) async {
    final response = await ApiClient.get(endpoint);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load $endpoint: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Unexpected response from $endpoint.');
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _loadList('/courses'),
        _loadList('/sessions'),
      ]);

      if (!mounted) return;

      setState(() {
        _courses = results[0];
        _sessions = results[1];

        if (!_courses.any((item) => _toInt(item['id']) == _courseId)) {
          _courseId = null;
        }

        if (!_sessions.any((item) => _toInt(item['id']) == _sessionId)) {
          _sessionId = null;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _courseLabel(Map<String, dynamic> course) {
    final code = (course['course_code'] ?? '').toString();
    final name = (course['course_name'] ?? course['name'] ?? '').toString();

    if (code.isEmpty) return name;
    if (name.isEmpty) return code;

    return '$code — $name';
  }

  String _sessionLabel(Map<String, dynamic> session) {
    final name = (session['name'] ?? session['session_name'] ?? '').toString();
    final start = session['start_date']?.toString();
    final end = session['end_date']?.toString();

    if (start != null && start.isNotEmpty &&
        end != null && end.isNotEmpty) {
      return '$name ($start – $end)';
    }

    return name;
  }

  Future<void> _save() async {
    if (_courseId == null || _sessionId == null) {
      setState(() => _error = 'Select both a course and an academic session.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await CourseOfferingService.updateCourseOffering(
          id: widget.offering!.id,
          courseId: _courseId!,
          sessionId: _sessionId!,
        );
      } else {
        await CourseOfferingService.createCourseOffering(
          courseId: _courseId!,
          sessionId: _sessionId!,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Course Offering' : 'Create Course Offering',
      ),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null && _courses.isEmpty && _sessions.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadOptions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the course and academic session for this offering.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _courseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _courses.map((course) {
                          final id = _toInt(course['id']);

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              _courseLabel(course),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _courseId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _sessionId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Academic Session',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _sessions.map((session) {
                          final id = _toInt(session['id']);

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              _sessionLabel(session),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _sessionId = value),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading || _saving ||
                  (_courses.isEmpty || _sessions.isEmpty)
              ? null
              : _save,
          style: FilledButton.styleFrom(backgroundColor: _orange),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
