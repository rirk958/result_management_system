
import 'package:flutter/material.dart';

import '../services/student_service.dart';

class StudentFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> sessions;

  const StudentFormDialog({
    super.key,
    required this.programs,
    required this.sessions,
  });

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentNoController = TextEditingController();

  int? _programId;
  int? _sessionId;
  DateTime? _admissionDate = DateTime.now();

  int? _createdUserId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentNoController.dispose();
    super.dispose();
  }

  String _dateString(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickAdmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _admissionDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_programId == null || _sessionId == null || _admissionDate == null) {
      setState(() => _error = 'Please select a program, session, and admission date.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create the user account only once.
      // If profile creation fails, a later submission retries the profile
      // using the already-created account instead of creating another account.
      if (_createdUserId == null) {
        _createdUserId = await StudentService.createStudentAccount(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      await StudentService.createStudentProfile(
        userId: _createdUserId!,
        studentNo: _studentNoController.text.trim(),
        programId: _programId!,
        sessionId: _sessionId!,
        admissionDate: _dateString(_admissionDate!),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _createdUserId == null
            ? e.toString().replaceFirst('Exception: ', '')
            : 'User account was created (ID: $_createdUserId), '
            'but the student profile was not created.\n'
            '${e.toString().replaceFirst('Exception: ', '')}\n'
            'Correct the information if needed and submit again. '
            'The existing account will be reused.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _admissionDate == null
        ? 'Select admission date'
        : _dateString(_admissionDate!);

    return AlertDialog(
      title: const Text('Register New Student'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_loading && _createdUserId == null,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the student name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  enabled: !_loading && _createdUserId == null,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an email address';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_loading && _createdUserId == null,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _studentNoController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Student number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the student number'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _programId,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: widget.programs.map((program) {
                    final id = int.parse(program['id'].toString());
                    final name = program['name']?.toString() ?? 'Program';
                    final code = program['code']?.toString() ?? '';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        code.isEmpty ? name : '$name ($code)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _programId = value),
                  validator: (value) =>
                  value == null ? 'Select a program' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _sessionId,
                  decoration: const InputDecoration(
                    labelText: 'Academic session',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: widget.sessions.map((session) {
                    final id = int.parse(session['id'].toString());
                    final name = session['name']?.toString() ?? 'Session';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _sessionId = value),
                  validator: (value) =>
                  value == null ? 'Select a session' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _loading ? null : _pickAdmissionDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Admission date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(dateText),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_createdUserId == null ? 'Create Student' : 'Retry Profile'),
        ),
      ],
    );
  }
}
