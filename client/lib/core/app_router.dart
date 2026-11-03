import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../pages/dashboard_page.dart';
import '../pages/login_page.dart';
import '../pages/placeholder_page.dart';
import '../services/auth_service.dart';
import '../widgets/app_shell.dart';
import '../pages/students_page.dart';
import '../pages/student_details_page.dart';
import '../pages/departments_page.dart';
import '../pages/programs_page.dart';
import '../pages/sessions_page.dart';
import '../pages/semesters_page.dart';
import '../pages/semester_results_page.dart';
import '../pages/course_results_page.dart';
import '../pages/marks_page.dart';
import '../pages/assessments_page.dart';
import '../pages/course_offerings_page.dart';
import '../pages/enrollments_page.dart';
import '../pages/grading_scales_page.dart';
import '../pages/publishing_page.dart';
import '../pages/transcripts_page.dart';
import '../pages/reports_page.dart';
import '../pages/audit_logs_page.dart';
import '../pages/settings_page.dart';
import '../pages/my_results_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: authService,
  redirect: (context, state) {
    final path = state.uri.path;
    if (!authService.isInitialized) return null;

    final loggedIn = authService.isAuthenticated;
    final user = authService.user;

    if (!loggedIn) return path == '/login' ? null : '/login';
    if (path == '/login' || path == '/') return '/dashboard';
    if (user == null || !_canAccess(user.role, path)) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => AppShell(
        currentPath: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
        GoRoute(
          path: '/departments',
          builder: (context, state) => const DepartmentsPage(),
        ),
        GoRoute(
          path: '/programs',
          builder: (context, state) => const ProgramsPage(),
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionsPage(),
        ),
        GoRoute(
          path: '/students',
          builder: (context, state) => const StudentsPage(),
        ),
        GoRoute(
          path: '/students/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid student ID')),
              );
            }

            return StudentDetailsPage(studentId: id);
          },
        ),
        GoRoute(
          path: '/semesters',
          builder: (context, state) => const SemestersPage(),
        ),

        GoRoute(
          path: '/semester-results',
          builder: (context, state) => const SemesterResultsPage(),
        ),

        GoRoute(
          path: '/course-results',
          builder: (context, state) => const CourseResultsPage(),
        ),

        GoRoute(
          path: '/my-results',
          builder: (context, state) => const MyResultsPage(),
        ),

        GoRoute(
          path: '/marks',
          builder: (context, state) => const MarksPage(),
        ),

        GoRoute(
          path: '/assessments',
          builder: (context, state) => const AssessmentsPage(),
        ),

        GoRoute(
          path: '/course-offerings',
          builder: (context, state) => const CourseOfferingsPage(),
        ),
        GoRoute(
          path: '/enrollments',
          builder: (context, state) => const EnrollmentsPage(),
        ),

        GoRoute(
          path: '/grading-scales',
          builder: (context, state) => const GradingScalesPage(),
        ),

        GoRoute(
          path: '/publishing',
          builder: (context, state) => const PublishingPage(),
        ),

        GoRoute(
          path: '/transcripts',
          builder: (context, state) => const TranscriptsPage(),
        ),

        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),

        GoRoute(
          path: '/audit-logs',
          builder: (context, state) => const AuditLogsPage(),
        ),

        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),

        _page('/users', 'Users', 'Manage user accounts and roles.'),
        _page('/teachers', 'Teachers', 'Manage teacher records.'),
        _page('/courses', 'Courses', 'Manage course codes, titles, and credits.'),

      ],
    ),
  ],
);

bool _canAccess(String role, String path) {
  if (role == 'admin') return true;
  const teacherRoutes = {
    '/dashboard', '/course-offerings', '/enrollments',
    '/assessments', '/marks', '/course-results',
  };
  const studentRoutes = {
    '/dashboard', '/courses', '/course-results',
    '/semester-results', '/transcripts',
  };
  if (role == 'teacher') {
    return teacherRoutes.contains(path) || path.startsWith('/students/');
  }
  if (role == 'student') return studentRoutes.contains(path);
  return false;
}

GoRoute _page(String path, String title, String description) => GoRoute(
  path: path,
  builder: (context, state) => PlaceholderPage(
    title: title,
    description: description,
  ),
);
