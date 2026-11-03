import 'package:flutter/material.dart';

import '../models/program.dart';
import '../models/department.dart';
import '../services/program_service.dart';
import '../services/department_service.dart';

class ProgramFormDialog extends StatefulWidget {
  final Program? program;

  const ProgramFormDialog({
    super.key,
    this.program,
  });

  @override
  State<ProgramFormDialog> createState() => _ProgramFormDialogState();
}

class _ProgramFormDialogState extends State<ProgramFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _degreeController = TextEditingController();

  List<Department> _departments = [];
  int? _selectedDepartmentId;
  int _totalSemesters = 8;

  bool _loadingDepartments = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.program != null;

  @override
  void initState() {
    super.initState();

    final program = widget.program;

    if (program != null) {
      _codeController.text = program.code;
      _nameController.text = program.name;
      _degreeController.text = program.degreeName;
      _selectedDepartmentId = program.departmentId;
      _totalSemesters = program.totalSemesters;
    } else {
      _degreeController.text = 'Bachelor';
    }

    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await DepartmentService.getDepartments();

      if (!mounted) return;

      setState(() {
        _departments = departments;
        _loadingDepartments = false;

        if (_selectedDepartmentId == null && departments.isNotEmpty) {
          _selectedDepartmentId = departments.first.id;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingDepartments = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartmentId == null) {
      setState(() => _error = 'Please select a department.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await ProgramService.updateProgram(
          id: widget.program!.id,
          departmentId: _selectedDepartmentId!,
          code: _codeController.text,
          name: _nameController.text,
          degreeName: _degreeController.text,
          totalSemesters: _totalSemesters,
        );
      } else {
        await ProgramService.createProgram(
          departmentId: _selectedDepartmentId!,
          code: _codeController.text,
          name: _nameController.text,
          degreeName: _degreeController.text,
          totalSemesters: _totalSemesters,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Program' : 'Add Program'),
      content: SizedBox(
        width: 480,
        child: _loadingDepartments
            ? const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        )
            : _departments.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No departments found. Create a department first.',
          ),
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedDepartmentId,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _departments
                      .map(
                        (department) => DropdownMenuItem<int>(
                      value: department.id,
                      child: Text(
                        '${department.code} - ${department.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Select a department' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Program Code',
                    hintText: 'e.g. CSE',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Program code is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Program Name',
                    hintText: 'e.g. Computer Science and Engineering',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Program name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(
                    labelText: 'Degree Name',
                    hintText: 'e.g. Bachelor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Degree name is required'
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  'Total Semesters',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: _saving || _totalSemesters <= 1
                          ? null
                          : () => setState(() {
                        _totalSemesters--;
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 55,
                      child: Center(
                        child: Text(
                          '$_totalSemesters',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                        _totalSemesters++;
                      }),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ||
              _loadingDepartments ||
              _departments.isEmpty
              ? null
              : _saveProgram,
          child: _saving
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_isEditing ? 'Save Changes' : 'Create Program'),
        ),
      ],
    );
  }
}