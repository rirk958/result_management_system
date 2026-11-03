
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/enrollment.dart';
import '../services/enrollment_service.dart';

class EnrollmentsPage extends StatefulWidget {
  const EnrollmentsPage({super.key});

  @override
  State<EnrollmentsPage> createState() => _EnrollmentsPageState();
}

class _EnrollmentsPageState extends State<EnrollmentsPage> {
  static const Color orange = Color(0xFFF97316);
  static const Color background = Color(0xFFF7F7F8);

  final _searchController = TextEditingController();
  List<Enrollment> _items = [];
  String _search = '';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await EnrollmentService.getEnrollments();
      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Enrollment> get _filtered {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _items;

    return _items.where((item) {
      return item.studentNo.toLowerCase().contains(query) ||
          item.studentName.toLowerCase().contains(query) ||
          item.courseCode.toLowerCase().contains(query) ||
          item.courseName.toLowerCase().contains(query) ||
          item.sessionName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openForm({Enrollment? enrollment}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EnrollmentFormDialog(enrollment: enrollment),
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(Enrollment enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove enrollment?'),
        content: Text(
          'Remove ${enrollment.studentName} from '
          '${enrollment.courseCode}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await EnrollmentService.deleteEnrollment(enrollment.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment removed successfully.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _status(String status) {
    final active = status.toLowerCase() == 'enrolled' ||
        status.toLowerCase() == 'active';

    final color = active ? Colors.green.shade700 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Enrolled' : status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _card(Enrollment item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openForm(enrollment: item);
                  if (value == 'delete') _delete(item);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
            ],
          ),
          Text(
            item.studentNo,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          Text(
            '${item.courseCode} — ${item.courseName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(item.sessionName),
          const SizedBox(height: 12),
          _status(item.status),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const Icon(Icons.how_to_reg_outlined, color: orange, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enrollments',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Assign students to course offerings.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total enrollments',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_items.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matching records',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Search student, course or session...',
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Could not load enrollments.\n$_error'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      children: [
                        const Icon(Icons.how_to_reg_outlined, size: 44),
                        const SizedBox(height: 12),
                        const Text('No enrollments found'),
                        const SizedBox(height: 12),
                        if (_search.isEmpty)
                          FilledButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create enrollment'),
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (!wide)
                ...items.map(_card)
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Student No.')),
                        DataColumn(label: Text('Student')),
                        DataColumn(label: Text('Course')),
                        DataColumn(label: Text('Session')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: items.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item.studentNo)),
                            DataCell(Text(item.studentName)),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  '${item.courseCode} — ${item.courseName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(item.sessionName)),
                            DataCell(_status(item.status)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => _openForm(enrollment: item),
                                    icon: const Icon(Icons.edit_outlined),
                                    color: orange,
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: () => _delete(item),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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

class _EnrollmentFormDialog extends StatefulWidget {
  final Enrollment? enrollment;

  const _EnrollmentFormDialog({this.enrollment});

  @override
  State<_EnrollmentFormDialog> createState() => _EnrollmentFormDialogState();
}

class _EnrollmentFormDialogState extends State<_EnrollmentFormDialog> {
  static const Color orange = Color(0xFFF97316);

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _offerings = [];
  int? _studentId;
  int? _offeringId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _studentId = widget.enrollment?.studentId;
    _offeringId = widget.enrollment?.courseOfferingId;
    _loadOptions();
  }

  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    final response = await ApiClient.get(endpoint);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load $endpoint: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    }

    throw Exception('Unexpected response from $endpoint.');
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _fetchList('/students'),
        _fetchList('/course-offerings'),
      ]);

      if (!mounted) return;

      setState(() {
        _students = results[0];
        _offerings = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _studentLabel(Map<String, dynamic> student) {
    final number = (student['student_no'] ?? '').toString();
    final name = (student['full_name'] ??
            student['student_name'] ??
            student['name'] ??
            '')
        .toString();

    return number.isEmpty ? name : '$number — $name';
  }

  String _offeringLabel(Map<String, dynamic> offering) {
    final code = (offering['course_code'] ?? '').toString();
    final name = (offering['course_name'] ?? '').toString();
    final session = (offering['session_name'] ?? '').toString();

    return '$code — $name${session.isEmpty ? '' : ' ($session)'}';
  }

  Future<void> _save() async {
    if (_studentId == null || _offeringId == null) {
      setState(() => _error = 'Select a student and a course offering.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (widget.enrollment == null) {
        await EnrollmentService.createEnrollment(
          studentId: _studentId!,
          courseOfferingId: _offeringId!,
        );
      } else {
        await EnrollmentService.updateEnrollment(
          id: widget.enrollment!.id,
          studentId: _studentId!,
          courseOfferingId: _offeringId!,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.enrollment == null ? 'Enroll Student' : 'Edit Enrollment',
      ),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null && _students.isEmpty && _offerings.isEmpty
                ? Text(_error!)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _studentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Student',
                          border: OutlineInputBorder(),
                        ),
                        items: _students.map((student) {
                          final id = _intValue(student['id']);

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              _studentLabel(student),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _studentId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _offeringId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Course Offering',
                          border: OutlineInputBorder(),
                        ),
                        items: _offerings.map((offering) {
                          final id = _intValue(offering['id']);

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              _offeringLabel(offering),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _offeringId = value),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading || _saving ||
                  _students.isEmpty || _offerings.isEmpty
              ? null
              : _save,
          style: FilledButton.styleFrom(backgroundColor: orange),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
