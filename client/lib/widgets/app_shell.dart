import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

class AppShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const AppShell({super.key, required this.currentPath, required this.child});

  static const Color _black = Color(0xFF171717);
  static const Color _orange = Color(0xFFF97316);

  static const List<_NavItem> _items = [
    _NavItem('Dashboard', '/dashboard', Icons.dashboard_outlined, {'admin', 'teacher', 'student'}),
    _NavItem('Departments', '/departments', Icons.account_balance_outlined, {'admin'}),
    _NavItem('Programs', '/programs', Icons.school_outlined, {'admin'}),
    _NavItem('Sessions', '/sessions', Icons.calendar_month_outlined, {'admin'}),
    _NavItem('Semesters', '/semesters', Icons.date_range_outlined, {'admin'}),
    _NavItem('Users', '/users', Icons.manage_accounts_outlined, {'admin'}),
    _NavItem('Students', '/students', Icons.people_outline, {'admin'}),
    _NavItem('Teachers', '/teachers', Icons.person_outline, {'admin'}),
    _NavItem('Courses', '/courses', Icons.menu_book_outlined, {'admin', 'student'}),
    _NavItem('Course Offerings', '/course-offerings', Icons.class_outlined, {'admin', 'teacher'}),
    _NavItem('Enrollments', '/enrollments', Icons.assignment_ind_outlined, {'admin', 'teacher'}),
    _NavItem('Assessments', '/assessments', Icons.fact_check_outlined, {'admin', 'teacher'}),
    _NavItem('Marks Entry', '/marks', Icons.edit_note_outlined, {'admin', 'teacher'}),
    _NavItem('Grading Scales', '/grading-scales', Icons.grade_outlined, {'admin'}),
    _NavItem('Course Results', '/course-results', Icons.assignment_outlined, {'admin', 'teacher', 'student'}),
    _NavItem('Semester Results', '/semester-results', Icons.bar_chart_outlined, {'admin', 'student'}),
    _NavItem('Publishing', '/publishing', Icons.publish_outlined, {'admin'}),
    _NavItem('Transcripts', '/transcripts', Icons.description_outlined, {'admin', 'student'}),
    _NavItem('Reports', '/reports', Icons.analytics_outlined, {'admin'}),
    _NavItem('Audit Logs', '/audit-logs', Icons.history_outlined, {'admin'}),
    _NavItem('Settings', '/settings', Icons.settings_outlined, {'admin'}),
  ];

  String get _title {
    for (final item in _items) {
      if (currentPath == item.path ||
          (item.path == '/students' && currentPath.startsWith('/students/'))) {
        return item.title;
      }
    }
    return 'IST Result Management';
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.user!;
    final role = user.role;
    final visibleItems = _items.where((item) => item.roles.contains(role)).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      appBar: AppBar(
        leading: isWide ? null : Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: PopupMenuButton<String>(
              tooltip: 'Account menu',
              onSelected: (value) async {
                if (value == 'logout') {
                  await authService.logout();
                  if (context.mounted) context.go('/login');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: SizedBox(
                    width: 190,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(role.toUpperCase(), style: const TextStyle(fontSize: 10, color: _orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Row(
                  children: [Icon(Icons.logout, size: 18), SizedBox(width: 10), Text('Sign out')],
                )),
              ],
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFFFE7D6),
                child: Icon(Icons.person_outline, color: _black, size: 20),
              ),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(
        child: SafeArea(child: _buildSidebar(context, visibleItems, inDrawer: true)),
      ),
      body: isWide
          ? Row(children: [
              SizedBox(width: 250, child: _buildSidebar(context, visibleItems)),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: child),
            ])
          : child,
    );
  }

  Widget _buildSidebar(BuildContext context, List<_NavItem> items, {bool inDrawer = false}) {
    return Container(
      color: _black,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 22),
          child: Row(children: [
            const Icon(Icons.school_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IST', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Institute of Science\\nand Technology', style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 11, height: 1.4)),
              ],
            )),
            if (inDrawer) IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ]),
        ),
        const Divider(color: Color(0xFF3A3A3A), height: 1),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: items.map((item) {
            final selected = currentPath == item.path ||
                (item.path == '/students' && currentPath.startsWith('/students/'));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: ListTile(
                selected: selected,
                selectedTileColor: const Color(0xFF3A2418),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: Icon(item.icon, color: selected ? _orange : const Color(0xFFBDBDBD), size: 21),
                title: Text(item.title, style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFDCE5F1),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                onTap: () {
                  if (inDrawer) Navigator.pop(context);
                  context.go(item.path);
                },
              ),
            );
          }).toList(),
        )),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('RESULT MANAGEMENT SYSTEM', style: TextStyle(
            color: Color(0xFF9A9A9A), fontSize: 9, letterSpacing: 1.1,
          )),
        ),
      ]),
    );
  }
}

class _NavItem {
  final String title;
  final String path;
  final IconData icon;
  final Set<String> roles;
  const _NavItem(this.title, this.path, this.icon, this.roles);
}
