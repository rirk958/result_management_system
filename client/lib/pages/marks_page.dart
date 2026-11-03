
import 'package:flutter/material.dart';

import '../services/marks_service.dart';

class MarksPage extends StatefulWidget {
  const MarksPage({super.key});

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _assessments = [];
  List<Map<String, dynamic>> _marks = [];

  int? _assessmentId;
  final Map<int, TextEditingController> _controllers = {};

  static const Color _orange = Color(0xFFFF7900);
  static const Color _background = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assessments = await MarksService.getAssessments();

      if (!mounted) return;

      setState(() {
        _assessments = assessments;
        _loading = false;
      });

      if (_assessments.isNotEmpty && _assessmentId == null) {
        await _selectAssessment(_toInt(_assessments.first['id']));
      } else if (_assessmentId != null) {
        final stillExists = _assessments.any(
          (item) => _toInt(item['id']) == _assessmentId,
        );

        if (stillExists) {
          await _selectAssessment(_assessmentId!);
        } else {
          _clearMarks();
          if (mounted) setState(() => _assessmentId = null);
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _clearMarks() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _marks = [];
  }

  Future<void> _selectAssessment(int id) async {
    setState(() {
      _assessmentId = id;
      _loading = true;
      _error = null;
    });

    _clearMarks();

    try {
      final marks = await MarksService.getAssessmentMarks(id);

      if (!mounted) return;

      setState(() {
        _marks = marks;

        for (final mark in marks) {
          final enrollmentId = _toInt(mark['enrollment_id']);
          final obtainedMarks = mark['obtained_marks'];

          _controllers[enrollmentId] = TextEditingController(
            text: obtainedMarks == null ? '' : obtainedMarks.toString(),
          );
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedAssessment {
    for (final assessment in _assessments) {
      if (_toInt(assessment['id']) == _assessmentId) {
        return assessment;
      }
    }
    return null;
  }

  Future<void> _saveMarks() async {
    if (_assessmentId == null) {
      _showMessage('Please select an assessment.');
      return;
    }

    final assessment = _selectedAssessment;
    if (assessment == null) {
      _showMessage('The selected assessment could not be found.');
      return;
    }

    final maxMarks = _toDouble(assessment['max_marks']);

    final entries = <Map<String, dynamic>>[];

    for (final mark in _marks) {
      final enrollmentId = _toInt(mark['enrollment_id']);
      final controller = _controllers[enrollmentId];

      if (controller == null || controller.text.trim().isEmpty) {
        _showMessage(
          'Enter marks for ${mark['student_name'] ?? 'every student'}.',
        );
        return;
      }

      final obtainedMarks = double.tryParse(controller.text.trim());

      if (obtainedMarks == null || obtainedMarks < 0) {
        _showMessage('Marks must be valid non-negative numbers.');
        return;
      }

      if (obtainedMarks > maxMarks) {
        _showMessage(
          'Marks cannot exceed ${maxMarks.toStringAsFixed(2)}.',
        );
        return;
      }

      entries.add({
        'enrollment_id': enrollmentId,
        'obtained_marks': obtainedMarks,
      });
    }

    setState(() => _saving = true);

    try {
      await MarksService.saveAssessmentMarks(
        assessmentId: _assessmentId!,
        marks: entries,
      );

      if (!mounted) return;

      _showMessage('Marks saved successfully.');
      await _selectAssessment(_assessmentId!);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not save marks: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _studentCard(Map<String, dynamic> mark) {
    final enrollmentId = _toInt(mark['enrollment_id']);
    final controller = _controllers[enrollmentId];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _orange.withValues(alpha: 0.12),
              child: const Icon(Icons.person_outline, color: _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mark['student_name'] ?? 'Unknown student'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${mark['student_no'] ?? '—'}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 105,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Marks',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFFFFF2E8),
        ),
        columns: const [
          DataColumn(label: Text('Student No.')),
          DataColumn(label: Text('Student Name')),
          DataColumn(label: Text('Obtained Marks')),
        ],
        rows: _marks.map((mark) {
          final enrollmentId = _toInt(mark['enrollment_id']);

          return DataRow(
            cells: [
              DataCell(Text('${mark['student_no'] ?? '—'}')),
              DataCell(
                SizedBox(
                  width: 250,
                  child: Text(
                    '${mark['student_name'] ?? 'Unknown student'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _controllers[enrollmentId],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter marks',
                      isDense: true,
                      border: OutlineInputBorder(),
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
    final assessment = _selectedAssessment;
    final isMobile = MediaQuery.sizeOf(context).width < 750;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAssessments,
          child: ListView(
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marks Entry',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Enter and save student assessment marks.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadAssessments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Assessment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _assessmentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assessment',
                          border: OutlineInputBorder(),
                        ),
                        items: _assessments.map((item) {
                          final id = _toInt(item['id']);
                          final courseCode =
                              item['course_code'] ?? item['course_name'] ?? '';
                          final name = item['name'] ?? 'Assessment $id';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$courseCode — $name',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _loading
                            ? null
                            : (id) {
                                if (id != null) _selectAssessment(id);
                              },
                      ),
                      if (assessment != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Maximum marks: ${assessment['max_marks'] ?? '—'}',
                            ),
                            Text(
                              'Students: ${_marks.length}',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Student Marks',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text('${_marks.length} students'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(35),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_assessmentId == null)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text('No assessments available.'),
                          ),
                        )
                      else if (_marks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text(
                              'No students or marks were returned for this assessment.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else if (isMobile)
                        Column(
                          children: _marks.map(_studentCard).toList(),
                        )
                      else
                        _desktopTable(),
                      if (!_loading && _marks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveMarks,
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 15,
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _saving ? 'Saving...' : 'Save Marks',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
