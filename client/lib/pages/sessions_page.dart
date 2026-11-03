
import 'package:flutter/material.dart';

import '../models/academic_session.dart';
import '../services/academic_session_service.dart';
import '../widgets/academic_session_form_dialog.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<AcademicSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _searchController.addListener(_refreshView);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshView);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshView() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessions = await AcademicSessionService.getSessions();

      if (!mounted) return;

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<AcademicSession> get _filteredSessions {
    final query = _searchController.text.trim().toLowerCase();

    return _sessions.where((session) {
      final matchesSearch = session.name.toLowerCase().contains(query);

      final matchesStatus = switch (_statusFilter) {
        'active' => session.isActive,
        'inactive' => !session.isActive,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openSessionForm({AcademicSession? session}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AcademicSessionFormDialog(session: session),
    );

    if (result == true && mounted) {
      await _loadSessions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session == null
                ? 'Academic session created successfully.'
                : 'Academic session updated successfully.',
          ),
        ),
      );
    }
  }

  Future<void> _changeSessionStatus(AcademicSession session) async {
    final activate = !session.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          activate ? 'Activate Session?' : 'Deactivate Session?',
        ),
        content: Text(
          activate
              ? 'Do you want to activate "${session.name}"?'
              : 'Do you want to deactivate "${session.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AcademicSessionService.updateSessionStatus(
        id: session.id,
        isActive: activate,
      );

      if (!mounted) return;

      await _loadSessions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Session activated successfully.'
                : 'Session deactivated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
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

  Widget _buildStatusBadge(bool isActive) {
    final theme = Theme.of(context);
    final color = isActive ? Colors.green : theme.colorScheme.outline;

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
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSessionCard(AcademicSession session) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(session.isActive),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDate(session.startDate)}  –  '
                        '${_formatDate(session.endDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openSessionForm(session: session),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _changeSessionStatus(session),
                  child: Text(
                    session.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: session.isActive
                          ? theme.colorScheme.error
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<AcademicSession> sessions) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 800,
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Session')),
              DataColumn(label: Text('Start Date')),
              DataColumn(label: Text('End Date')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: sessions.map((session) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      session.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(_formatDate(session.startDate))),
                  DataCell(Text(_formatDate(session.endDate))),
                  DataCell(_buildStatusBadge(session.isActive)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit session',
                          onPressed: () =>
                              _openSessionForm(session: session),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: session.isActive
                              ? 'Deactivate session'
                              : 'Activate session',
                          onPressed: () => _changeSessionStatus(session),
                          icon: Icon(
                            session.isActive
                                ? Icons.toggle_on_outlined
                                : Icons.toggle_off_outlined,
                            color: session.isActive
                                ? Colors.green
                                : null,
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = _filteredSessions;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    final activeCount = _sessions.where((s) => s.isActive).length;
    final inactiveCount = _sessions.length - activeCount;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Sessions',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage academic years and their date ranges.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openSessionForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Session'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 700
                      ? (constraints.maxWidth - 24) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          title: 'Total Sessions',
                          count: _sessions.length,
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          title: 'Active Sessions',
                          count: activeCount,
                          icon: Icons.event_available_outlined,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          title: 'Inactive Sessions',
                          count: inactiveCount,
                          icon: Icons.event_busy_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final searchField = TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search session name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  );

                  final filterField = DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Sessions'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _statusFilter = value);
                      }
                    },
                  );

                  if (constraints.maxWidth >= 650) {
                    return Row(
                      children: [
                        Expanded(flex: 3, child: searchField),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: filterField),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      filterField,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadSessions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (sessions.isEmpty)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _sessions.isEmpty
                                ? 'No academic sessions yet'
                                : 'No sessions match your search',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _sessions.isEmpty
                                ? 'Add your first academic session to get started.'
                                : 'Try changing the search or status filter.',
                            textAlign: TextAlign.center,
                          ),
                          if (_sessions.isEmpty) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _openSessionForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Session'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (isDesktop)
                    _buildDesktopTable(sessions)
                  else
                    ...sessions.map(
                          (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSessionCard(session),
                      ),
                    ),
              const SizedBox(height: 16),
              if (!_isLoading && _errorMessage == null && sessions.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Showing ${sessions.length} of ${_sessions.length} sessions',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
