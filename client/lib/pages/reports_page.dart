
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color _orange = Color(0xFFF47721);
  static const Color _ink = Color(0xFF202124);

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _results = [];

  bool _loading = true;
  String? _error;
  String _reportType = 'Semester Results';
  String _search = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      for (final key in ['data', 'results', 'students', 'items', 'records']) {
        if (decoded[key] is List) {
          return decoded[key] as List;
        }
      }
    }

    return [];
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.get('/students'),
        ApiClient.get('/semester-results'),
      ]);

      if (responses[0].statusCode < 200 ||
          responses[0].statusCode >= 300) {
        throw Exception('Could not load student records.');
      }

      if (responses[1].statusCode < 200 ||
          responses[1].statusCode >= 300) {
        throw Exception('Could not load semester results.');
      }

      final students = _extractList(jsonDecode(responses[0].body));
      final results = _extractList(jsonDecode(responses[1].body));

      if (!mounted) return;

      setState(() {
        _students = students
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        _results = results
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

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

  double? _number(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) return double.tryParse(value.toString());
    }
    return null;
  }

  List<Map<String, dynamic>> get _activeRows {
    final source = _reportType == 'Students' ? _students : _results;
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return source;

    return source.where((row) {
      final searchable = _reportType == 'Students'
          ? [
              _value(row, ['student_no', 'student_number']),
              _value(row, ['full_name', 'student_name', 'name']),
              _value(row, ['email', 'email_address']),
              _value(row, ['department_name', 'department']),
              _value(row, ['program_name', 'program']),
            ].join(' ')
          : [
              _value(row, ['student_no', 'student_number']),
              _value(row, ['student_name', 'full_name', 'name']),
              _value(row, ['semester_name', 'semester']),
              _value(row, ['session_name', 'session']),
              _value(row, ['status']),
            ].join(' ');

      return searchable.toLowerCase().contains(query);
    }).toList();
  }

  int get _publishedCount {
    return _results.where((row) {
      final status =
          _value(row, ['status', 'publication_status'], fallback: 'draft')
              .toLowerCase();
      return ['published', 'public', 'released'].contains(status);
    }).length;
  }

  double? get _averageGpa {
    final values = _results
        .map((row) => _number(row, ['gpa', 'semester_gpa']))
        .whereType<double>()
        .toList();

    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTypeButton(String label, IconData icon) {
    final selected = _reportType == label;

    return InkWell(
      onTap: () {
        setState(() {
          _reportType = label;
          _search = '';
          _searchController.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _orange.withValues(alpha: 0.09) : Colors.white,
          border: Border.all(
            color: selected ? _orange : const Color(0xFFE6E6E6),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _orange : Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? _orange : _ink,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _orange, size: 19),
          ],
        ),
      ),
    );
  }

  Widget _studentTable(List<Map<String, dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFFF7F7F8),
        ),
        columns: const [
          DataColumn(label: Text('Student No.')),
          DataColumn(label: Text('Student Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Department')),
          DataColumn(label: Text('Program')),
        ],
        rows: rows.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(_value(row, ['student_no', 'student_number']))),
              DataCell(Text(_value(row, ['full_name', 'student_name', 'name']))),
              DataCell(Text(_value(row, ['email', 'email_address']))),
              DataCell(Text(_value(row, ['department_name', 'department']))),
              DataCell(Text(_value(row, ['program_name', 'program']))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _resultsTable(List<Map<String, dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFFF7F7F8),
        ),
        columns: const [
          DataColumn(label: Text('Student No.')),
          DataColumn(label: Text('Student Name')),
          DataColumn(label: Text('Semester')),
          DataColumn(label: Text('Session')),
          DataColumn(label: Text('GPA')),
          DataColumn(label: Text('CGPA')),
          DataColumn(label: Text('Status')),
        ],
        rows: rows.map((row) {
          final status =
              _value(row, ['status', 'publication_status'], fallback: 'draft');

          return DataRow(
            cells: [
              DataCell(Text(_value(row, ['student_no', 'student_number']))),
              DataCell(Text(_value(row, ['student_name', 'full_name', 'name']))),
              DataCell(Text(_value(row, ['semester_name', 'semester']))),
              DataCell(Text(_value(row, ['session_name', 'session']))),
              DataCell(Text(_value(row, ['gpa', 'semester_gpa']))),
              DataCell(Text(_value(row, ['cgpa', 'cumulative_gpa']))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'published'
                        ? Colors.green.withValues(alpha: 0.10)
                        : _orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status.toLowerCase() == 'published'
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _activeRows;

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
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review student records and academic performance.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh reports',
                        onPressed: _loadReports,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
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
                            onPressed: _loadReports,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1000
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: _summaryCard(
                              title: 'Total Students',
                              value: '${_students.length}',
                              description: 'Student records',
                              icon: Icons.people_outline,
                              color: _ink,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _summaryCard(
                              title: 'Semester Results',
                              value: '${_results.length}',
                              description: 'Calculated result records',
                              icon: Icons.school_outlined,
                              color: _orange,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _summaryCard(
                              title: 'Published Results',
                              value: '$_publishedCount',
                              description: 'Marked as published',
                              icon: Icons.check_circle_outline,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _summaryCard(
                              title: 'Average GPA',
                              value: _averageGpa == null
                                  ? '—'
                                  : _averageGpa!.toStringAsFixed(2),
                              description: 'Across available GPA records',
                              icon: Icons.trending_up,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Choose a Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700 ? 2 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: _reportTypeButton(
                              'Semester Results',
                              Icons.assessment_outlined,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _reportTypeButton(
                              'Students',
                              Icons.people_outline,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _reportType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ),
                      Text(
                        '${rows.length} records',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: _reportType == 'Students'
                          ? 'Search student, email or department...'
                          : 'Search student, semester or session...',
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: rows.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(35),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 40,
                                  color: Colors.black38,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No matching records',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _reportType == 'Students'
                            ? _studentTable(rows)
                            : _resultsTable(rows),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showMessage(
                          'Report data is displayed on screen. PDF/Excel '
                          'export has not been connected yet.',
                        );
                      },
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Export report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _orange,
                        side: const BorderSide(color: _orange),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
