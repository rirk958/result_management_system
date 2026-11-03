
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _dashboard;

  @override
  void initState() {
    super.initState();

    // The current backend dashboard endpoint is admin-only.
    if (authService.user?.isAdmin == true) {
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.get('/dashboard');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid dashboard response.');
        }

        if (!mounted) return;

        setState(() {
          _dashboard = decoded;
          _loading = false;
        });
      } else if (response.statusCode == 401) {
        authService.handleUnauthorized();
      } else if (response.statusCode == 403) {
        throw Exception(
          'Your account does not have permission to view dashboard statistics.',
        );
      } else {
        String message = 'Unable to load dashboard statistics.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.user;

    if (user == null) {
      return const Center(child: Text('No authenticated user found.'));
    }

    final width = MediaQuery.sizeOf(context).width;
    final sections = _sectionsFor(user);

    return RefreshIndicator(
      onRefresh: user.isAdmin ? _loadDashboard : () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(width < 600 ? 18 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomePanel(user: user),

                if (user.isAdmin) ...[
                  const SizedBox(height: 28),
                  _sectionHeading(
                    'System overview',
                    'Live statistics from your academic database.',
                    trailing: IconButton(
                      tooltip: 'Refresh dashboard',
                      onPressed: _loading ? null : _loadDashboard,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildStatistics(width),
                  if (_dashboard != null) ...[
                    const SizedBox(height: 28),
                    _buildBreakdowns(width),
                  ],
                ] else ...[
                  const SizedBox(height: 25),
                  _informationPanel(user),
                ],

                const SizedBox(height: 30),
                const Text(
                  'Quick access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose a module to continue.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 4
                        : constraints.maxWidth >= 750
                        ? 3
                        : constraints.maxWidth >= 500
                        ? 2
                        : 1;

                    final itemWidth =
                        (constraints.maxWidth - (columns - 1) * 14) /
                            columns;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: sections.map((item) {
                        return SizedBox(
                          width: itemWidth,
                          child: _ModuleCard(item: item),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(double width) {
    if (_loading && _dashboard == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _dashboard == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD0C2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Dashboard could not be loaded',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final overview =
        (_dashboard?['overview'] as Map?)?.cast<String, dynamic>() ?? {};

    final cards = <_StatItem>[
      _StatItem('Students', _number(overview['total_students']),
          Icons.people_alt_outlined, const Color(0xFFF97316)),
      _StatItem('Active students', _number(overview['active_students']),
          Icons.person_outline, const Color(0xFF16A34A)),
      _StatItem('Teachers', _number(overview['total_teachers']),
          Icons.co_present_outlined, const Color(0xFF2563EB)),
      _StatItem('Users', _number(overview['total_users']),
          Icons.manage_accounts_outlined, const Color(0xFF7C3AED)),
      _StatItem('Departments', _number(overview['total_departments']),
          Icons.account_tree_outlined, const Color(0xFF0891B2)),
      _StatItem('Programs', _number(overview['total_programs']),
          Icons.school_outlined, const Color(0xFFDB2777)),
      _StatItem('Sessions', _number(overview['total_sessions']),
          Icons.calendar_month_outlined, const Color(0xFF0D9488)),
      _StatItem('Semesters', _number(overview['total_semesters']),
          Icons.event_note_outlined, const Color(0xFFCA8A04)),
      _StatItem('Courses', _number(overview['total_courses']),
          Icons.menu_book_outlined, const Color(0xFF4F46E5)),
      _StatItem('Course offerings',
          _number(overview['total_course_offerings']),
          Icons.class_outlined, const Color(0xFFEA580C)),
      _StatItem('Enrollments', _number(overview['total_enrollments']),
          Icons.assignment_ind_outlined, const Color(0xFF0284C7)),
      _StatItem('Assessments', _number(overview['total_assessments']),
          Icons.fact_check_outlined, const Color(0xFF9333EA)),
      _StatItem('Marks entered', _number(overview['total_marks']),
          Icons.edit_note_outlined, const Color(0xFF059669)),
      _StatItem('Course results', _number(overview['total_course_results']),
          Icons.assignment_outlined, const Color(0xFF475569)),
      _StatItem('Published results',
          _number(overview['published_semester_results']),
          Icons.verified_outlined, const Color(0xFF16A34A)),
      _StatItem('Draft results',
          _number(overview['draft_semester_results']),
          Icons.pending_actions_outlined, const Color(0xFFEA580C)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Refresh failed: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 750
                ? 3
                : constraints.maxWidth >= 500
                ? 2
                : 1;

            final itemWidth =
                (constraints.maxWidth - (columns - 1) * 14) / columns;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: cards.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: _StatCard(item: item),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        _AverageCard(
          percentage: _dashboard?['average_course_percentage'],
        ),
      ],
    );
  }

  Widget _buildBreakdowns(double width) {
    final enrollmentStatuses =
        _dashboard?['enrollments_by_status'] as List? ?? [];

    final resultStatuses =
        _dashboard?['semester_results_by_status'] as List? ?? [];

    final grades = _dashboard?['grade_distribution'] as List? ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 850;

        final enrollmentCard = _BreakdownCard(
          title: 'Enrollments by status',
          icon: Icons.people_outline,
          children: enrollmentStatuses.map((item) {
            final row = item as Map;
            return _BreakdownRow(
              label: _capitalize(row['status']?.toString() ?? 'Unknown'),
              value: _number(row['total']),
              color: const Color(0xFFF97316),
            );
          }).toList(),
        );

        final resultsCard = _BreakdownCard(
          title: 'Semester results',
          icon: Icons.assessment_outlined,
          children: resultStatuses.map((item) {
            final row = item as Map;
            final status = row['status']?.toString() ?? 'Unknown';
            return _BreakdownRow(
              label: _capitalize(status),
              value: _number(row['total']),
              color: status.toLowerCase() == 'published'
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFEA580C),
            );
          }).toList(),
        );

        final gradeCard = _BreakdownCard(
          title: 'Grade distribution',
          icon: Icons.bar_chart_outlined,
          children: grades.map((item) {
            final row = item as Map;
            return _BreakdownRow(
              label: row['grade_letter']?.toString() ?? 'Unknown',
              value: _number(row['total']),
              color: const Color(0xFF2563EB),
            );
          }).toList(),
        );

        if (stacked) {
          return Column(
            children: [
              enrollmentCard,
              const SizedBox(height: 14),
              resultsCard,
              const SizedBox(height: 14),
              gradeCard,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: enrollmentCard),
                const SizedBox(width: 14),
                Expanded(child: resultsCard),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: gradeCard),
          ],
        );
      },
    );
  }

  Widget _sectionHeading(
      String title,
      String subtitle, {
        Widget? trailing,
      }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _informationPanel(AppUser user) {
    final message = user.isTeacher
        ? 'Your teaching modules are available below. Access to specific courses and student records must be controlled by the server.'
        : 'Your academic information and published results will appear in the student modules when those sections are connected to the API.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF97316)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  List<_Module> _sectionsFor(AppUser user) {
    final all = <_Module>[
      const _Module('Departments', 'Manage academic departments.',
          Icons.account_tree_outlined, '/departments'),
      const _Module('Programs', 'Manage academic programs.',
          Icons.school_outlined, '/programs'),
      const _Module('Sessions', 'Manage academic sessions.',
          Icons.calendar_month_outlined, '/sessions'),
      const _Module('Semesters', 'Manage semesters.',
          Icons.event_note_outlined, '/semesters'),
      const _Module('Students', 'Search and maintain student records.',
          Icons.people_alt_outlined, '/students'),
      const _Module('Teachers', 'Manage teacher information.',
          Icons.co_present_outlined, '/teachers'),
      const _Module('Courses', 'Browse course codes and credit details.',
          Icons.menu_book_outlined, '/courses'),
      const _Module('Course offerings', 'Manage semester course offerings.',
          Icons.class_outlined, '/course-offerings'),
      const _Module('Enrollments', 'Manage course registrations.',
          Icons.assignment_ind_outlined, '/enrollments'),
      const _Module('Assessments', 'Configure exams and assessments.',
          Icons.fact_check_outlined, '/assessments'),
      const _Module('Marks entry', 'Enter and review assessment marks.',
          Icons.edit_note_outlined, '/marks'),
      const _Module('Grading scales', 'Manage grade boundaries.',
          Icons.grade_outlined, '/grading-scales'),
      const _Module('Course results', 'Review course grades and totals.',
          Icons.assignment_outlined, '/course-results'),
      const _Module('Semester results', 'Review GPA and CGPA.',
          Icons.bar_chart_outlined, '/semester-results'),
      const _Module('Publishing', 'Publish semester results.',
          Icons.publish_outlined, '/publishing'),
      const _Module('Transcripts', 'View academic transcripts.',
          Icons.description_outlined, '/transcripts'),
      const _Module('Reports', 'Academic and administrative reports.',
          Icons.analytics_outlined, '/reports'),
      const _Module('Users', 'Manage system accounts and roles.',
          Icons.manage_accounts_outlined, '/users'),
      const _Module('Audit logs', 'Review system activity.',
          Icons.history_outlined, '/audit-logs'),
      const _Module('Settings', 'System configuration.',
          Icons.settings_outlined, '/settings'),
    ];

    if (user.isAdmin) return all;

    if (user.isTeacher) {
      return all.where((m) => {
        '/course-offerings',
        '/enrollments',
        '/assessments',
        '/marks',
        '/course-results',
      }.contains(m.path)).toList();
    }

    return all.where((m) => {
      '/courses',
      '/course-results',
      '/semester-results',
      '/transcripts',
    }.contains(m.path)).toList();
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _WelcomePanel extends StatelessWidget {
  final AppUser user;

  const _WelcomePanel({required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user.role.isEmpty
        ? 'User'
        : user.role[0].toUpperCase() + user.role.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171717), Color(0xFF302018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INSTITUTE OF SCIENCE AND TECHNOLOGY',
                style: TextStyle(
                  color: Color(0xFFFFB27D),
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome, ${user.fullName.isEmpty ? 'User' : user.fullName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are signed in as $role.',
                style: const TextStyle(
                  color: Color(0xFFE5E5E5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x55FFFFFF)),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatItem(this.title, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.value.toString(),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  final dynamic percentage;

  const _AverageCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final value = percentage == null
        ? null
        : double.tryParse(percentage.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDFC8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up,
              color: Color(0xFFF97316), size: 30),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average course percentage',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Across calculated course results',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            value == null ? 'N/A' : '${value.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _BreakdownCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF97316)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (children.isEmpty)
            Text(
              'No data available yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final String title;
  final String description;
  final IconData icon;
  final String path;

  const _Module(this.title, this.description, this.icon, this.path);
}

class _ModuleCard extends StatelessWidget {
  final _Module item;

  const _ModuleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(item.path),
        child: Container(
          constraints: const BoxConstraints(minHeight: 142),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E7E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: const Color(0xFFF97316), size: 25),
              const SizedBox(height: 13),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
