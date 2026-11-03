
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class TranscriptsPage extends StatefulWidget {
  const TranscriptsPage({super.key});

  @override
  State<TranscriptsPage> createState() => _TranscriptsPageState();
}

class _TranscriptsPageState extends State<TranscriptsPage> {
  static const Color _orange = Color(0xFFF47721);
  static const Color _ink = Color(0xFF202124);

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _results = [];

  int? _selectedStudentId;
  bool _loading = true;
  String? _error;
  String _search = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      for (final key in ['data', 'students', 'results', 'items', 'records']) {
        if (decoded[key] is List) {
          return decoded[key] as List;
        }
      }
    }

    return [];
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.get('/students'),
        ApiClient.get('/semester-results'),
      ]);

      final studentsResponse = responses[0];
      final resultsResponse = responses[1];

      if (studentsResponse.statusCode < 200 ||
          studentsResponse.statusCode >= 300) {
        throw Exception('Could not load students.');
      }

      if (resultsResponse.statusCode < 200 ||
          resultsResponse.statusCode >= 300) {
        throw Exception('Could not load semester results.');
      }

      final studentRows = _extractList(jsonDecode(studentsResponse.body));
      final resultRows = _extractList(jsonDecode(resultsResponse.body));

      if (!mounted) return;

      setState(() {
        _students = studentRows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        _results = resultRows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        if (_selectedStudentId != null &&
            !_students.any((s) => _studentId(s) == _selectedStudentId)) {
          _selectedStudentId = null;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? _parseId(dynamic value) => int.tryParse(value?.toString() ?? '');

  int? _studentId(Map<String, dynamic> student) {
    return _parseId(student['id'] ?? student['student_id']);
  }

  int? _resultStudentId(Map<String, dynamic> result) {
    return _parseId(result['student_id']);
  }

  String _value(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _studentName(Map<String, dynamic> student) {
    return _value(
      student,
      ['full_name', 'student_name', 'name'],
      fallback: 'Unnamed student',
    );
  }

  String _studentNumber(Map<String, dynamic> student) {
    return _value(student, ['student_no', 'student_number', 'registration_no']);
  }

  Map<String, dynamic>? get _selectedStudent {
    for (final student in _students) {
      if (_studentId(student) == _selectedStudentId) return student;
    }
    return null;
  }

  List<Map<String, dynamic>> get _studentResults {
    if (_selectedStudentId == null) return [];

    final rows = _results.where((result) {
      return _resultStudentId(result) == _selectedStudentId;
    }).toList();

    rows.sort((a, b) {
      final aName = _value(a, ['semester_name', 'semester']);
      final bName = _value(b, ['semester_name', 'semester']);
      return aName.compareTo(bName);
    });

    return rows;
  }

  List<Map<String, dynamic>> get _filteredStudents {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _students;

    return _students.where((student) {
      return '${_studentName(student)} ${_studentNumber(student)}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  double? _number(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) return double.tryParse(value.toString());
    }
    return null;
  }

  String _formatNumber(double? value) {
    return value == null ? '—' : value.toStringAsFixed(2);
  }

  double? get _latestGpa {
    if (_studentResults.isEmpty) return null;
    return _number(_studentResults.last, ['gpa', 'semester_gpa']);
  }

  double? get _latestCgpa {
    if (_studentResults.isEmpty) return null;
    return _number(_studentResults.last, ['cgpa', 'cumulative_gpa']);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 190,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> result, int index) {
    final status = _value(result, ['status'], fallback: 'draft');
    final semester = _value(result, ['semester_name', 'semester']);
    final session = _value(result, ['session_name', 'session']);
    final gpa = _value(result, ['gpa', 'semester_gpa']);
    final cgpa = _value(result, ['cgpa', 'cumulative_gpa']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semester,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: status.toLowerCase() == 'published'
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'GPA',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
              Text(
                gpa,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'CGPA $cgpa',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transcriptPreview() {
    final student = _selectedStudent;
    if (student == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          children: [
            Icon(Icons.description_outlined, size: 45, color: Colors.black38),
            SizedBox(height: 12),
            Text(
              'Select a student to view their transcript',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    final results = _studentResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      color: _orange,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACADEMIC TRANSCRIPT',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Student academic record preview',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh records',
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const Divider(height: 30),
              Wrap(
                spacing: 25,
                runSpacing: 5,
                children: [
                  _infoItem('Student name', _studentName(student)),
                  _infoItem('Student number', _studentNumber(student)),
                  _infoItem(
                    'Email',
                    _value(student, ['email', 'email_address']),
                  ),
                  _infoItem(
                    'Department',
                    _value(student, ['department_name', 'department']),
                  ),
                  _infoItem(
                    'Program',
                    _value(student, ['program_name', 'program']),
                  ),
                  _infoItem(
                    'Academic record entries',
                    '${results.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (results.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 3 : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: _summaryCard(
                      'Semester Results',
                      '${results.length}',
                      Icons.school_outlined,
                      _ink,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _summaryCard(
                      'Latest GPA',
                      _formatNumber(_latestGpa),
                      Icons.bar_chart_rounded,
                      _orange,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _summaryCard(
                      'Latest CGPA',
                      _formatNumber(_latestCgpa),
                      Icons.trending_up_rounded,
                      Colors.green.shade700,
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 22),
        const Text(
          'Semester History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
        if (results.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'No semester results are available for this student yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ...results.asMap().entries.map(
                (entry) => _resultCard(entry.value, entry.key),
              ),
        const SizedBox(height: 15),
        const Text(
          'Note: This is a transcript preview based on available semester-result '
          'records. It is not an official document until the backend supports '
          'official transcript generation and publication.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _orange),
              )
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transcripts',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View student academic history and GPA records.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                          TextButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find Student',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _search = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name or student number...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select student',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: filteredStudents
                              .where((student) => _studentId(student) != null)
                              .map((student) {
                            final id = _studentId(student)!;

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '${_studentNumber(student)} — ${_studentName(student)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStudentId = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _transcriptPreview(),
                ],
              ),
      ),
    );
  }
}
