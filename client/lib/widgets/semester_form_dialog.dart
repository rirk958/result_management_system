
import 'package:flutter/material.dart';

import '../models/program.dart';
import '../models/semester.dart';
import '../services/program_service.dart';
import '../services/semester_service.dart';

class SemesterFormDialog extends StatefulWidget {
  final Semester? semester;

  const SemesterFormDialog({
    super.key,
    this.semester,
  });

  @override
  State<SemesterFormDialog> createState() => _SemesterFormDialogState();
}

class _SemesterFormDialogState extends State<SemesterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<Program> _programs = [];
  int? _selectedProgramId;
  int? _selectedSemesterNumber;
  bool _loadingPrograms = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.semester != null;

  Program? get _selectedProgram {
    for (final program in _programs) {
      if (program.id == _selectedProgramId) return program;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    final semester = widget.semester;
    if (semester != null) {
      _nameController.text = semester.name;
      _selectedProgramId = semester.programId;
      _selectedSemesterNumber = semester.semesterNumber;
    }

    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await ProgramService.getPrograms();

      if (!mounted) return;

      setState(() {
        _programs = programs;
        _loadingPrograms = false;

        if (_selectedProgramId == null && programs.isNotEmpty) {
          _selectedProgramId = programs.first.id;
        }

        final selected = _selectedProgram;
        if (selected != null &&
            (_selectedSemesterNumber == null ||
                _selectedSemesterNumber! > selected.totalSemesters)) {
          _selectedSemesterNumber = 1;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPrograms = false;
        _error = 'Failed to load programs: $e';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProgramId == null ||
        _selectedSemesterNumber == null) {
      setState(() => _error = 'Please select a program and semester number.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        await SemesterService.updateSemester(
          id: widget.semester!.id,
          programId: _selectedProgramId!,
          semesterNumber: _selectedSemesterNumber!,
          name: _nameController.text.trim(),
        );
      } else {
        await SemesterService.createSemester(
          programId: _selectedProgramId!,
          semesterNumber: _selectedSemesterNumber!,
          name: _nameController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProgram = _selectedProgram;
    final maxSemesters = selectedProgram?.totalSemesters ?? 0;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Semester' : 'Add Semester'),
      content: SizedBox(
        width: 460,
        child: _loadingPrograms
            ? const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_programs.isEmpty)
                  const Text(
                    'No active programs found. Create an active program first.',
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    initialValue: _programs.any(
                          (program) => program.id == _selectedProgramId,
                    )
                        ? _selectedProgramId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Program',
                      border: OutlineInputBorder(),
                    ),
                    items: _programs.map((program) {
                      return DropdownMenuItem<int>(
                        value: program.id,
                        child: Text(
                          '${program.code} — ${program.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return _programs.map((program) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${program.code} — ${program.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    onChanged: _saving
                        ? null
                        : (value) {
                      setState(() {
                        _selectedProgramId = value;
                        _selectedSemesterNumber = 1;
                        _error = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a program';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedSemesterNumber != null &&
                        _selectedSemesterNumber! <= maxSemesters &&
                        _selectedSemesterNumber! >= 1
                        ? _selectedSemesterNumber
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Semester Number',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      maxSemesters,
                          (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('Semester ${index + 1}'),
                      ),
                    ),
                    onChanged: _saving
                        ? null
                        : (value) {
                      setState(() {
                        _selectedSemesterNumber = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a semester number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Semester Name',
                      hintText: 'e.g. First Semester',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Semester name is required';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ||
              _loadingPrograms ||
              _programs.isEmpty
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_isEditing ? 'Save Changes' : 'Create Semester'),
        ),
      ],
    );
  }
}
