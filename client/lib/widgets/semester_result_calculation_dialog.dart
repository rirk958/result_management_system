
import 'package:flutter/material.dart';

import '../models/academic_session.dart';
import '../models/semester.dart';
import '../models/student.dart';
import '../services/academic_session_service.dart';
import '../services/semester_result_service.dart';
import '../services/semester_service.dart';
import '../services/student_service.dart';

class SemesterResultCalculationDialog extends StatefulWidget {
  const SemesterResultCalculationDialog({super.key});

  @override
  State<SemesterResultCalculationDialog> createState() =>
      _SemesterResultCalculationDialogState();
}

class _SemesterResultCalculationDialogState
    extends State<SemesterResultCalculationDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Student> _students = [];
  List<Semester> _semesters = [];
  List<AcademicSession> _sessions = [];

  int? _studentId;
  int? _semesterId;
  int? _sessionId;

  bool _loading = true;
  bool _calculating = false;
  String? _error;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _calculation;

  static const _orange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        StudentService.getStudents(),
        SemesterService.getSemesters(),
        AcademicSessionService.getSessions(),
      ]);

      if (!mounted) return;

      setState(() {
        _students = (results[0] as List<Student>)
            .where((student) => student.status == 'active')
            .toList();

        _semesters = (results[1] as List<Semester>)
            .where((semester) => semester.isActive)
            .toList();

        _sessions = (results[2] as List<AcademicSession>)
            .where((session) => session.isActive)
            .toList();

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

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _calculating = true;
      _error = null;
    });

    try {
      final response =
      await SemesterResultService.calculateSemesterResult(
        studentId: _studentId!,
        semesterId: _semesterId!,
        sessionId: _sessionId!,
      );

      if (!mounted) return;

      setState(() {
        _result = response['result'] is Map
            ? Map<String, dynamic>.from(response['result'] as Map)
            : null;

        _calculation = response['calculation'] is Map
            ? Map<String, dynamic>.from(
          response['calculation'] as Map,
        )
            : null;

        _calculating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _calculating = false;
      });
    }
  }

  String _number(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);
    return double.tryParse(value?.toString() ?? '')?.toStringAsFixed(2) ??
        '0.00';
  }

  String _credits(dynamic value) {
    if (value is num) return value.toString();
    return value?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _result != null;

    return AlertDialog(
      title: Text(
        completed ? 'Semester Result Calculated' : 'Calculate Semester Result',
      ),
      content: SizedBox(
        width: 480,
        child: _loading
            ? const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        )
            : SingleChildScrollView(
          child: completed
              ? _buildResultSummary()
              : _buildForm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _calculating
              ? null
              : () => Navigator.of(context).pop(completed),
          child: Text(completed ? 'Done' : 'Cancel'),
        ),
        if (!completed)
          FilledButton.icon(
            onPressed: _calculating ||
                _students.isEmpty ||
                _semesters.isEmpty ||
                _sessions.isEmpty
                ? null
                : _calculate,
            icon: _calculating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.calculate_outlined),
            label: Text(_calculating ? 'Calculating...' : 'Calculate Result'),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            _message(_error!, isError: true),
            const SizedBox(height: 16),
          ],
          const Text(
            'Select the student and academic period for calculation.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<int>(
            initialValue: _students.any(
                  (student) => student.id == _studentId,
            )
                ? _studentId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Student',
              border: OutlineInputBorder(),
            ),
            items: _students.map((student) {
              return DropdownMenuItem<int>(
                value: student.id,
                child: Text(
                  '${student.studentNo} — ${student.fullName}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _calculating
                ? null
                : (value) => setState(() => _studentId = value),
            validator: (value) =>
            value == null ? 'Please select a student' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _semesters.any(
                  (semester) => semester.id == _semesterId,
            )
                ? _semesterId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: _semesters.map((semester) {
              return DropdownMenuItem<int>(
                value: semester.id,
                child: Text(
                  '${semester.name} — ${semester.programCode}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _calculating
                ? null
                : (value) => setState(() => _semesterId = value),
            validator: (value) =>
            value == null ? 'Please select a semester' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _sessions.any(
                  (session) => session.id == _sessionId,
            )
                ? _sessionId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Academic Session',
              border: OutlineInputBorder(),
            ),
            items: _sessions.map((session) {
              return DropdownMenuItem<int>(
                value: session.id,
                child: Text(
                  session.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _calculating
                ? null
                : (value) => setState(() => _sessionId = value),
            validator: (value) =>
            value == null ? 'Please select a session' : null,
          ),
          if (_students.isEmpty ||
              _semesters.isEmpty ||
              _sessions.isEmpty) ...[
            const SizedBox(height: 16),
            _message(
              'An active student, semester, and academic session are '
                  'required before calculating results.',
              isError: true,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'All eligible course results must be calculated first.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary() {
    final result = _result!;
    final calculation = _calculation ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _message(
          'The result was saved successfully. Its status remains '
              '"${result['status'] ?? 'draft'}".',
          isError: false,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _scoreCard(
                'Semester GPA',
                _number(result['gpa']),
                Icons.school_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _scoreCard(
                'Cumulative CGPA',
                _number(result['cgpa']),
                Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Calculation Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _detailRow(
          'Semester credits',
          _credits(calculation['semester_credits']),
        ),
        _detailRow(
          'Semester quality points',
          _number(calculation['semester_quality_points']),
        ),
        _detailRow(
          'Cumulative credits',
          _credits(calculation['cumulative_credits']),
        ),
        _detailRow(
          'Cumulative quality points',
          _number(calculation['cumulative_quality_points']),
        ),
      ],
    );
  }

  Widget _scoreCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _orange.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _orange),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, {required bool isError}) {
    final color = isError ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
