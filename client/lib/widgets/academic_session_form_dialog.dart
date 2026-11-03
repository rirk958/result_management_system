
import 'package:flutter/material.dart';

import '../models/academic_session.dart';
import '../services/academic_session_service.dart';

class AcademicSessionFormDialog extends StatefulWidget {
  final AcademicSession? session;

  const AcademicSessionFormDialog({
    super.key,
    this.session,
  });

  @override
  State<AcademicSessionFormDialog> createState() =>
      _AcademicSessionFormDialogState();
}

class _AcademicSessionFormDialogState
    extends State<AcademicSessionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late DateTime _startDate;
  late DateTime _endDate;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();

    final session = widget.session;

    _nameController = TextEditingController(
      text: session?.name ?? '',
    );

    _startDate = session?.startDate ?? DateTime(DateTime.now().year, 1, 1);
    _endDate = session?.endDate ?? DateTime(DateTime.now().year, 12, 31);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final selectedDate = isStartDate ? _startDate : _endDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStartDate ? 'Select start date' : 'Select end date',
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = pickedDate;

        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = pickedDate;
      }

      _errorMessage = null;
    });
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _errorMessage = 'End date cannot be before the start date.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await AcademicSessionService.updateSession(
          id: widget.session!.id,
          name: _nameController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await AcademicSessionService.createSession(
          name: _nameController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Academic Session' : 'Add Academic Session',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Session Name',
                    hintText: 'e.g. 2026-2027',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a session name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Start Date',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _selectDate(isStartDate: true),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_formatDate(_startDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'End Date',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => _selectDate(isStartDate: false),
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(_formatDate(_endDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
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
          onPressed:
          _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveSession,
          icon: _isSaving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : 'Save Session'),
        ),
      ],
    );
  }
}
