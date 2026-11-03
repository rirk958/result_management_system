
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/student_service.dart';

class StudentDetailsPage extends StatefulWidget {
  final int studentId;

  const StudentDetailsPage({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _studentNoController = TextEditingController();
  final _admissionDateController = TextEditingController();

  Student? _student;
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _sessions = [];

  int? _programId;
  int? _sessionId;
  String _status = 'active';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _statuses = [
    'active',
    'graduated',
    'suspended',
    'withdrawn',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _studentNoController.dispose();
    _admissionDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StudentService.getStudentById(widget.studentId),
        StudentService.getPrograms(),
        StudentService.getSessions(),
      ]);

      final student = results[0] as Student;
      final programs = results[1] as List<Map<String, dynamic>>;
      final sessions = results[2] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _student = student;
        _programs = programs;
        _sessions = sessions;

        _studentNoController.text = student.studentNo;
        _admissionDateController.text = student.admissionDate;
        _programId = student.programId;
        _sessionId = student.sessionId;
        _status = student.status;

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

  Future<void> _selectAdmissionDate() async {
    DateTime initialDate =
        DateTime.tryParse(_admissionDateController.text) ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      _admissionDateController.text =
      '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_programId == null || _sessionId == null) {
      _showMessage('Please select a program and academic session.');
      return;
    }

    setState(() => _saving = true);

    try {
      await StudentService.updateStudent(
        id: widget.studentId,
        studentNo: _studentNoController.text.trim(),
        programId: _programId!,
        sessionId: _sessionId!,
        admissionDate: _admissionDateController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('Student information updated successfully.');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeStatus(String? newStatus) async {
    if (newStatus == null || newStatus == _status) return;

    final oldStatus = _status;
    setState(() => _status = newStatus);

    try {
      await StudentService.updateStudentStatus(
        id: widget.studentId,
        status: newStatus,
      );

      if (!mounted) return;
      _showMessage('Student status updated.');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = oldStatus);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _student == null
          ? const Center(child: Text('Student not found.'))
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final student = _student!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to students',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Student Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFFE5D5),
                          child: Text(
                            student.fullName.isEmpty
                                ? '?'
                                : student.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(student.email),
                              Text('Student ID: ${student.studentNo}'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String>(
                            initialValue: _statuses.contains(_status)
                                ? _status
                                : 'active',
                            decoration: const InputDecoration(
                              labelText: 'Student status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _statuses.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(_formatStatus(status)),
                              );
                            }).toList(),
                            onChanged: _changeStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Academic Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _studentNoController,
                            decoration: const InputDecoration(
                              labelText: 'Student Number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Student number is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _programs.any(
                                  (item) => int.tryParse(
                                item['id'].toString(),
                              ) ==
                                  _programId,
                            )
                                ? _programId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Program',
                              border: OutlineInputBorder(),
                            ),
                            items: _programs.map((program) {
                              final id = int.parse(program['id'].toString());
                              final name = program['name']?.toString() ?? '';
                              final code = program['code']?.toString() ?? '';

                              return DropdownMenuItem(
                                value: id,
                                child: Text(
                                  code.isEmpty ? name : '$code - $name',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _programId = value);
                            },
                            validator: (value) =>
                            value == null ? 'Select a program.' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _sessions.any(
                                  (item) => int.tryParse(
                                item['id'].toString(),
                              ) ==
                                  _sessionId,
                            )
                                ? _sessionId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Academic Session',
                              border: OutlineInputBorder(),
                            ),
                            items: _sessions.map((session) {
                              final id = int.parse(session['id'].toString());
                              final name =
                                  session['name']?.toString() ?? 'Session $id';

                              return DropdownMenuItem(
                                value: id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _sessionId = value);
                            },
                            validator: (value) =>
                            value == null ? 'Select a session.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _admissionDateController,
                            readOnly: true,
                            onTap: _selectAdmissionDate,
                            decoration: const InputDecoration(
                              labelText: 'Admission Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  DateTime.tryParse(value) == null) {
                                return 'Select a valid admission date.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _saveChanges,
                              icon: _saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.save),
                              label: Text(
                                _saving ? 'Saving...' : 'Save Changes',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
