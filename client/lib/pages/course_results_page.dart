
import 'package:flutter/material.dart';

import '../models/course_result.dart';
import '../services/course_result_service.dart';

class CourseResultsPage extends StatefulWidget {
  const CourseResultsPage({super.key});

  @override
  State<CourseResultsPage> createState() => _CourseResultsPageState();
}

class _CourseResultsPageState extends State<CourseResultsPage> {
  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = 'all';

  List<CourseResult> _results = [];

  static const Color _orange = Color(0xFFFF7900);
  static const Color _background = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await CourseResultService.getCourseResults();

      if (!mounted) return;

      setState(() {
        _results = results;
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

  List<CourseResult> get _filteredResults {
    final query = _search.trim().toLowerCase();

    return _results.where((result) {
      final statusMatches = _statusFilter == 'all' ||
          result.status.toLowerCase() == _statusFilter;

      final searchMatches = query.isEmpty ||
          result.studentName.toLowerCase().contains(query) ||
          result.studentNo.toLowerCase().contains(query) ||
          result.courseCode.toLowerCase().contains(query) ||
          result.courseName.toLowerCase().contains(query) ||
          result.sessionName.toLowerCase().contains(query) ||
          result.letterGrade.toLowerCase().contains(query);

      return statusMatches && searchMatches;
    }).toList();
  }

  int get _draftCount => _results
      .where((r) => r.status.toLowerCase() == 'draft')
      .length;

  int get _publishedCount => _results
      .where((r) => r.status.toLowerCase() == 'published')
      .length;

  double _averagePercentage(List<CourseResult> results) {
    if (results.isEmpty) return 0;

    final total = results.fold<double>(
      0,
      (sum, result) => sum + result.percentage,
    );

    return total / results.length;
  }

  String _number(double value) => value.toStringAsFixed(2);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'draft':
        return _orange;
      case 'calculated':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
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

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDetails(CourseResult result) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Course Result Details'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Student', result.studentName),
                _detailRow('Student Number', result.studentNo),
                _detailRow('Course Code', result.courseCode),
                _detailRow('Course Name', result.courseName),
                _detailRow('Session', result.sessionName),
                _detailRow('Total Marks', _number(result.totalMarks)),
                _detailRow('Percentage', '${_number(result.percentage)}%'),
                _detailRow('Letter Grade', result.letterGrade),
                _detailRow('Grade Point', _number(result.gradePoint)),
                _detailRow('Status', result.status.toUpperCase()),
                _detailRow('Result ID', '${result.id}'),
                _detailRow('Enrollment ID', '${result.enrollmentId}'),
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
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 45,
                color: Colors.black26,
              ),
              SizedBox(height: 12),
              Text(
                'No course results found',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5),
              Text(
                'Try changing the search or status filter.',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFFFFF2E8),
        ),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Course')),
          DataColumn(label: Text('Session')),
          DataColumn(label: Text('Marks')),
          DataColumn(label: Text('Percentage')),
          DataColumn(label: Text('Grade')),
          DataColumn(label: Text('Grade Point')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Details')),
        ],
        rows: results.map((result) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 170,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.studentName.isEmpty
                            ? 'Unknown student'
                            : result.studentName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        result.studentNo.isEmpty
                            ? '—'
                            : result.studentNo,
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
                SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.courseCode.isEmpty
                            ? '—'
                            : result.courseCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result.courseName.isEmpty
                            ? 'Unknown course'
                            : result.courseName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(
                result.sessionName.isEmpty ? '—' : result.sessionName,
              )),
              DataCell(Text(_number(result.totalMarks))),
              DataCell(Text('${_number(result.percentage)}%')),
              DataCell(
                Text(
                  result.letterGrade.isEmpty ? '—' : result.letterGrade,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(_number(result.gradePoint))),
              DataCell(_statusBadge(result.status)),
              DataCell(
                IconButton(
                  tooltip: 'View details',
                  onPressed: () => _showDetails(result),
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
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No course results found.')),
      );
    }

    return Column(
      children: results.map((result) {
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
                  result.studentName.isEmpty
                      ? 'Unknown student'
                      : result.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  result.studentNo.isEmpty ? '—' : result.studentNo,
                  style: const TextStyle(color: Colors.black54),
                ),
                const Divider(height: 22),
                _detailRow('Course', result.courseCode),
                _detailRow('Course Name', result.courseName),
                _detailRow('Session', result.sessionName),
                _detailRow('Marks', _number(result.totalMarks)),
                _detailRow('Percentage', '${_number(result.percentage)}%'),
                _detailRow('Grade', result.letterGrade),
                _detailRow('Grade Point', _number(result.gradePoint)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showDetails(result),
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
          onRefresh: _loadResults,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 850;

              return ListView(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course Results',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191919),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Review grades and marks for individual courses.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loadResults,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
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
                              child: TextButton(
                                onPressed: _loadResults,
                                child: const Text('Try again'),
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
                          '${_results.length}',
                          Icons.assessment_outlined,
                          _orange,
                        ),
                        _statCard(
                          'Draft Results',
                          '$_draftCount',
                          Icons.edit_note,
                          Colors.blueGrey,
                        ),
                        _statCard(
                          'Average Percentage',
                          '${_number(_averagePercentage(_results))}%',
                          Icons.analytics_outlined,
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
                              'Search and Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() => _search = value);
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search student or course...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _statusFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All statuses'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'draft',
                                        child: Text('Draft'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'published',
                                        child: Text('Published'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'calculated',
                                        child: Text('Calculated'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _statusFilter = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _search = '';
                                      _statusFilter = 'all';
                                    });
                                  },
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Clear'),
                                ),
                              ],
                            ),
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
