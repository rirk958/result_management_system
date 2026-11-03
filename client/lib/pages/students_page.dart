
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/student.dart';
import '../services/student_service.dart';
import '../widgets/student_form_dialog.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _sessions = [];

  bool _loading = true;
  String? _error;

  String _search = '';
  String _status = 'all';
  int? _programId;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StudentService.getStudents(),
        StudentService.getPrograms(),
        StudentService.getSessions(),
      ]);

      if (!mounted) return;

      setState(() {
        _students = results[0] as List<Student>;
        _programs = results[1] as List<Map<String, dynamic>>;
        _sessions = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _showAddStudentDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StudentFormDialog(
        programs: _programs,
        sessions: _sessions,
      ),
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  List<Student> get _filteredStudents {
    return _students.where((student) {
      final query = _search.toLowerCase().trim();

      final matchesSearch = query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.studentNo.toLowerCase().contains(query);

      final matchesStatus =
          _status == 'all' || student.status == _status;

      final matchesProgram =
          _programId == null || student.programId == _programId;

      final matchesSession =
          _sessionId == null || student.sessionId == _sessionId;

      return matchesSearch &&
          matchesStatus &&
          matchesProgram &&
          matchesSession;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'graduated':
        return Colors.blue;
      case 'suspended':
        return Colors.orange;
      case 'withdrawn':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statCard(
      String title,
      int value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final active = _students.where((s) => s.status == 'active').length;
    final graduated =
        _students.where((s) => s.status == 'graduated').length;
    final suspended =
        _students.where((s) => s.status == 'suspended').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final cards = [
          _statCard(
            'Total Students',
            _students.length,
            Icons.people_outline,
            Colors.deepOrange,
          ),
          _statCard(
            'Active',
            active,
            Icons.check_circle_outline,
            Colors.green,
          ),
          _statCard(
            'Graduated',
            graduated,
            Icons.school_outlined,
            Colors.blue,
          ),
          _statCard(
            'Suspended',
            suspended,
            Icons.pause_circle_outline,
            Colors.orange,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  cards[0],
                  const SizedBox(width: 10),
                  cards[1],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  cards[2],
                  const SizedBox(width: 10),
                  cards[3],
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 750;

        final searchField = TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            hintText: 'Search name, email or student ID...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              icon: const Icon(Icons.close),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        );

        final statusFilter = DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All statuses')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
            DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
            DropdownMenuItem(value: 'withdrawn', child: Text('Withdrawn')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        );

        final programFilter = DropdownButtonFormField<int?>(
          initialValue: _programId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Program',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All programs'),
            ),
            ..._programs.map((program) {
              return DropdownMenuItem<int?>(
                value: int.tryParse(program['id'].toString()),
                child: Text(
                  '${program['code']} - ${program['name']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _programId = value),
        );

        final sessionFilter = DropdownButtonFormField<int?>(
          initialValue: _sessionId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Academic session',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All sessions'),
            ),
            ..._sessions.map((session) {
              return DropdownMenuItem<int?>(
                value: int.tryParse(session['id'].toString()),
                child: Text(
                  session['name']?.toString() ?? 'Session',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) => setState(() => _sessionId = value),
        );

        if (compact) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: statusFilter),
                  const SizedBox(width: 10),
                  Expanded(child: programFilter),
                ],
              ),
              const SizedBox(height: 10),
              sessionFilter,
            ],
          );
        }

        return Column(
          children: [
            searchField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: statusFilter),
                const SizedBox(width: 12),
                Expanded(child: programFilter),
                const SizedBox(width: 12),
                Expanded(child: sessionFilter),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return InkWell(
      onTap: () => context.go('/students/${student.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepOrange.withValues(alpha: 0.10),
              child: Text(
                student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.studentNo,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.programCode} • ${student.sessionName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(student.status),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final students = _filteredStudents;

    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 45,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No students found',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Try changing your search or filters.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: students.map(_buildStudentCard).toList(),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Colors.grey.shade50,
              ),
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Student ID')),
                DataColumn(label: Text('Program')),
                DataColumn(label: Text('Session')),
                DataColumn(label: Text('Admission')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('')),
              ],
              rows: students.map((student) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              student.email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(student.studentNo)),
                    DataCell(
                      Text('${student.programCode} - ${student.programName}'),
                    ),
                    DataCell(Text(student.sessionName)),
                    DataCell(
                      Text(
                        student.admissionDate.length >= 10
                            ? student.admissionDate.substring(0, 10)
                            : student.admissionDate,
                      ),
                    ),
                    DataCell(_statusBadge(student.status)),
                    DataCell(
                      IconButton(
                        tooltip: 'View student',
                        onPressed: () {
                          context.go('/students/${student.id}');
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
              constraints.maxWidth < 600 ? 16.0 : 28.0;

              return ListView(
                padding: EdgeInsets.all(horizontalPadding),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage student records and academic information.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                      ),
                      FilledButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Student'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A00),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildStats(),
                  const SizedBox(height: 24),
                  const Text(
                    'Student Directory',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  Text(
                    '${_filteredStudents.length} students found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStudentList(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
