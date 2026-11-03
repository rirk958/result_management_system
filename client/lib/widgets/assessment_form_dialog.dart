
import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/course_offering_service.dart';

class AssessmentFormDialog extends StatefulWidget {
  final Assessment? assessment;

  const AssessmentFormDialog({
    super.key,
    this.assessment,
  });

  @override
  State<AssessmentFormDialog> createState() => _AssessmentFormDialogState();
}

class _AssessmentFormDialogState extends State<AssessmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxMarksController = TextEditingController();

  List<Map<String, dynamic>> _offerings = [];
  int? _offeringId;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const Color _orange = Color(0xFFFF7900);

  @override
  void initState() {
    super.initState();

    final assessment = widget.assessment;
    if (assessment != null) {
      _nameController.text = assessment.name;
      _maxMarksController.text = assessment.maxMarks.toString();
      _offeringId = assessment.courseOfferingId;
    } else {
      _maxMarksController.text = '100';
    }

    _loadOfferings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadOfferings() async {
    try {
      final response = await CourseOfferingService.getCourseOfferings();

      if (!mounted) return;

      final offerings = response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      setState(() {
        _offerings = offerings;
        _loading = false;

        if (_offeringId == null && offerings.isNotEmpty) {
          _offeringId = _toInt(offerings.first['id']);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_offeringId == null) {
      setState(() => _error = 'Please select a course offering.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final maxMarks = double.parse(_maxMarksController.text.trim());

      if (widget.assessment == null) {
        await AssessmentService.createAssessment(
          courseOfferingId: _offeringId!,
          name: name,
          maxMarks: maxMarks,
        );
      } else {
        await AssessmentService.updateAssessment(
          id: widget.assessment!.id,
          courseOfferingId: _offeringId!,
          name: name,
          maxMarks: maxMarks,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.assessment == null ? 'Create Assessment' : 'Edit Assessment',
      ),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 130,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      DropdownButtonFormField<int>(
                        initialValue: _offerings.any(
                          (item) => _toInt(item['id']) == _offeringId,
                        )
                            ? _offeringId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course Offering',
                          border: OutlineInputBorder(),
                        ),
                        items: _offerings.map((item) {
                          final id = _toInt(item['id']);
                          final courseCode =
                              item['course_code'] ?? 'Course';
                          final courseName =
                              item['course_name'] ?? '';
                          final sessionName =
                              item['session_name'] ?? '';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$courseCode $courseName ($sessionName)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                  _offeringId = value;
                                }),
                        validator: (value) =>
                            value == null ? 'Select a course offering' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Assessment Name',
                          hintText: 'e.g. Midterm Examination',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter an assessment name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxMarksController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Maximum Marks',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final marks = double.tryParse(value?.trim() ?? '');

                          if (marks == null || marks <= 0) {
                            return 'Enter a number greater than zero';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading || _saving || _offerings.isEmpty ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
          ),
          child: Text(_saving ? 'Saving...' : 'Save Assessment'),
        ),
      ],
    );
  }
}
