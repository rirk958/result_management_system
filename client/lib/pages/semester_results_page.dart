
import 'package:flutter/material.dart';

import '../models/academic_session.dart';
import '../models/semester.dart';
import '../models/student.dart';
import '../models/semester_result.dart';
import '../services/academic_session_service.dart';
import '../services/semester_result_service.dart';
import '../services/semester_service.dart';
import '../services/student_service.dart';
import '../widgets/semester_result_calculation_dialog.dart';

class SemesterResultsPage extends StatefulWidget {
  const SemesterResultsPage({super.key});

  @override
  State<SemesterResultsPage> createState() => _SemesterResultsPageState();
}

class _SemesterResultsPageState extends State<SemesterResultsPage> {
  bool _loading = true;
  String? _error;

  List<SemesterResult> _results = [];
  List<Student> _students = [];
  List<Semester> _semesters = [];
  List<AcademicSession> _sessions = [];

  int? _studentFilter;
  int? _semesterFilter;
  int? _sessionFilter;
  String _statusFilter = 'all';
  String _search = '';

  static const Color _orange = Color(0xFFFF7900);
  static const Color _dark = Color(0xFF191919);
  static const Color _background = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final responses = await Future.wait([
        SemesterResultService.getSemesterResults(),
        StudentService.getStudents(),
        SemesterService.getSemesters(),
        AcademicSessionService.getSessions(),
      ]);

      if (!mounted) return;

      setState(() {
        _results = (responses[0] as List).cast<SemesterResult>();

        _students = (responses[1] as List).cast<Student>();
        _semesters = (responses[2] as List).cast<Semester>();
        _sessions = (responses[3] as List).cast<AcademicSession>();

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

  List<SemesterResult> get _filteredResults {
    final query = _search.trim().toLowerCase();

    return _results.where((result) {
      final studentId = result.studentId;
      final semesterId = result.semesterId;
      final sessionId = result.sessionId;
      final status = result.status.toLowerCase();

      final studentMatches =
          _studentFilter == null || studentId == _studentFilter;
      final semesterMatches =
          _semesterFilter == null || semesterId == _semesterFilter;
      final sessionMatches =
          _sessionFilter == null || sessionId == _sessionFilter;
      final statusMatches =
          _statusFilter == 'all' || status == _statusFilter;

      final studentName = result.studentName.toLowerCase();
      final studentNo = result.studentNo.toLowerCase();
      final semesterName = result.semesterName.toLowerCase();
      final sessionName = result.sessionName.toLowerCase();

      final searchMatches = query.isEmpty ||
          studentName.contains(query) ||
          studentNo.contains(query) ||
          semesterName.contains(query) ||
          sessionName.contains(query);

      return studentMatches &&
          semesterMatches &&
          sessionMatches &&
          statusMatches &&
          searchMatches;
    }).toList();
  }


  String _formatDate(DateTime? value) {
    if (value == null) return '—';

    final date = value;

    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  int get _draftCount =>
      _results.where((result) => result.status.toLowerCase() == 'draft').length;

  int get _publishedCount =>
      _results.where((result) => result.status.toLowerCase() == 'published').length;

  Future<void> _calculateResult() async {
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SemesterResultCalculationDialog(),
    );

    if (completed == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _showResultDetails(SemesterResult result) async {
    final id = result.id;
    if (id <= 0) return;

    try {
      final details = await SemesterResultService.getSemesterResultById(id);
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Semester Result Details'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _detailRow('Student', details.studentName.isNotEmpty
                        ? details.studentName
                        : result.studentName),
                    _detailRow('Student No.', details.studentNo.isNotEmpty
                        ? details.studentNo
                        : result.studentNo),
                    _detailRow('Semester', details.semesterName.isNotEmpty
                        ? details.semesterName
                        : result.semesterName),
                    _detailRow('Session', details.sessionName.isNotEmpty
                        ? details.sessionName
                        : result.sessionName),
                    _detailRow('GPA', details.gpa.toStringAsFixed(2)),
                    _detailRow('CGPA', details.cgpa.toStringAsFixed(2)),
                    _detailRow('Status', details.status),
                    _detailRow(
                      'Calculated At',
                      _formatDate(details.calculatedAt),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load result details: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAEAEA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 23,
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

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 230,
          child: TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Search student or session...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<int?>(
            initialValue: _studentFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Student',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All students'),
              ),
              ..._students.map(
                    (student) => DropdownMenuItem<int?>(
                  value: student.id,
                  child: Text(
                    '${student.studentNo} - ${student.fullName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _studentFilter = value),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<int?>(
            initialValue: _semesterFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All semesters'),
              ),
              ..._semesters.map(
                    (semester) => DropdownMenuItem<int?>(
                  value: semester.id,
                  child: Text(
                    '${semester.programCode} - ${semester.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _semesterFilter = value),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<int?>(
            initialValue: _sessionFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Session',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All sessions'),
              ),
              ..._sessions.map(
                    (session) => DropdownMenuItem<int?>(
                  value: session.id,
                  child: Text(
                    session.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _sessionFilter = value),
          ),
        ),
        SizedBox(
          width: 145,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All statuses')),
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(
                value: 'published',
                child: Text('Published'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _statusFilter = value);
              }
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _studentFilter = null;
              _semesterFilter = null;
              _sessionFilter = null;
              _statusFilter = 'all';
              _search = '';
            });
          },
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.black26),
              SizedBox(height: 12),
              Text(
                'No semester results found',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5),
              Text(
                'Calculate a semester result or change the filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF2E8)),
        columnSpacing: 26,
        columns: const [
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Semester')),
          DataColumn(label: Text('Session')),
          DataColumn(label: Text('GPA')),
          DataColumn(label: Text('CGPA')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Calculated')),
          DataColumn(label: Text('Actions')),
        ],
        rows: results.map((result) {
          final status = result.status;
          final normalizedStatus = status.toLowerCase();
          final statusColor = normalizedStatus == 'published'
              ? Colors.green
              : normalizedStatus == 'draft'
              ? _orange
              : Colors.blueGrey;

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 190,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.studentName.isEmpty ? 'Unknown student' : result.studentName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${result.studentNo.isEmpty ? '—' : result.studentNo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Text('${result.semesterName.isEmpty ? '—' : result.semesterName}'),
              ),
              DataCell(
                Text('${result.sessionName.isEmpty ? '—' : result.sessionName}'),
              ),
              DataCell(
                Text(
                  result.gpa.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  result.cgpa.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(_formatDate(result.calculatedAt))),
              DataCell(
                IconButton(
                  tooltip: 'View result details',
                  onPressed: () => _showResultDetails(result),
                  icon: const Icon(Icons.visibility_outlined),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCards() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: Text('No semester results found.')),
      );
    }

    return Column(
      children: results.map((result) {
        final status = result.status;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEAEAEA)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.studentName.isEmpty ? 'Unknown student' : result.studentName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${result.studentNo.isEmpty ? '—' : result.studentNo}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Divider(height: 22),
                _detailRow('Semester', '${result.semesterName.isEmpty ? '—' : result.semesterName}'),
                _detailRow('Session', '${result.sessionName.isEmpty ? '—' : result.sessionName}'),
                _detailRow(
                  'GPA / CGPA',
                  '${result.gpa.toStringAsFixed(2)} / '
                      '${result.cgpa.toStringAsFixed(2)}',
                ),
                _detailRow('Status', status.toUpperCase()),
                _detailRow('Calculated', _formatDate(result.calculatedAt)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showResultDetails(result),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 850;

              return ListView(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    spacing: 16,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Semester Results',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Calculate and review student GPA and CGPA.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                          FilledButton.icon(
                            onPressed: _calculateResult,
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 15,
                              ),
                            ),
                            icon: const Icon(Icons.calculate_outlined),
                            label: const Text('Calculate Result'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try again'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    GridView.count(
                      crossAxisCount: isMobile ? 1 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: isMobile ? 5.2 : 2.7,
                      children: [
                        _statCard(
                          'Total Results',
                          _results.length,
                          Icons.assessment_outlined,
                          _orange,
                        ),
                        _statCard(
                          'Draft Results',
                          _draftCount,
                          Icons.edit_note,
                          Colors.blueGrey,
                        ),
                        _statCard(
                          'Published Results',
                          _publishedCount,
                          Icons.verified_outlined,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEAEAEA)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFilters(),
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
                        side: const BorderSide(color: Color(0xFFEAEAEA)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 10 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Result Records',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_filteredResults.length} records',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (isMobile)
                              _buildMobileCards()
                            else
                              _buildTable(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}