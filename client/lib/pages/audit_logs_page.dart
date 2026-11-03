
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  static const Color _orange = Color(0xFFF47721);
  static const Color _ink = Color(0xFF202124);

  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _actionFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      for (final key in ['data', 'logs', 'items', 'records', 'results']) {
        if (decoded[key] is List) {
          return decoded[key] as List;
        }
      }
    }

    return [];
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.get('/audit-logs');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseMessage(response.body, 'Could not load audit logs.'),
        );
      }

      final decoded = jsonDecode(response.body);
      final rows = _extractList(decoded);

      if (!mounted) return;

      setState(() {
        _logs = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        _logs.sort((a, b) {
          final aDate = _dateValue(a);
          final bDate = _dateValue(b);
          return bDate.compareTo(aDate);
        });

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _responseMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return (decoded['message'] ?? decoded['error'] ?? fallback)
            .toString();
      }
    } catch (_) {
      // Keep the fallback for non-JSON responses.
    }

    return fallback;
  }

  String _value(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '—',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  DateTime _dateValue(Map<String, dynamic> row) {
    final raw = _value(
      row,
      ['created_at', 'createdAt', 'timestamp', 'date', 'logged_at'],
      fallback: '',
    );

    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(Map<String, dynamic> row) {
    final date = _dateValue(row);

    if (date.millisecondsSinceEpoch == 0) return '—';

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _action(Map<String, dynamic> row) {
    return _value(
      row,
      ['action', 'event_type', 'activity', 'operation'],
      fallback: 'Activity',
    );
  }

  String _actor(Map<String, dynamic> row) {
    return _value(
      row,
      ['user_name', 'full_name', 'username', 'email', 'actor_name'],
      fallback: _value(row, ['user_id', 'actor_id'], fallback: 'System'),
    );
  }

  String _description(Map<String, dynamic> row) {
    return _value(
      row,
      ['description', 'details', 'message', 'remarks', 'entity_name'],
      fallback: 'No description available',
    );
  }

  String _category(Map<String, dynamic> row) {
    return _value(
      row,
      ['module', 'entity_type', 'resource', 'category'],
      fallback: 'General',
    );
  }

  List<String> get _actions {
    final values = _logs.map(_action).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['All', ...values.where((value) => value != '—')];
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final query = _search.trim().toLowerCase();

    return _logs.where((row) {
      if (_actionFilter != 'All' && _action(row) != _actionFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchable = [
        _action(row),
        _actor(row),
        _description(row),
        _category(row),
        _formatDate(row),
        _value(row, ['ip_address', 'ip', 'remote_address']),
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Color _actionColor(String action) {
    final value = action.toLowerCase();

    if (value.contains('delete') || value.contains('remove')) {
      return Colors.red.shade700;
    }

    if (value.contains('create') ||
        value.contains('insert') ||
        value.contains('add')) {
      return Colors.green.shade700;
    }

    if (value.contains('login') || value.contains('logout')) {
      return Colors.blue.shade700;
    }

    if (value.contains('update') || value.contains('edit')) {
      return Colors.orange.shade800;
    }

    return _ink;
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> row) {
    final action = _action(row);
    final color = _actionColor(action);
    final ip = _value(row, ['ip_address', 'ip', 'remote_address']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.history_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _description(row),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _category(row),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _metadata(Icons.person_outline, _actor(row)),
              _metadata(Icons.access_time, _formatDate(row)),
              if (ip != '—') _metadata(Icons.lan_outlined, ip),
              if (_value(row, ['user_id', 'actor_id']) != '—')
                _metadata(
                  Icons.badge_outlined,
                  'User ID: ${_value(row, ['user_id', 'actor_id'])}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metadata(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;
    final uniqueActions = _logs.map(_action).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _orange),
              )
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audit Logs',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review recorded system activities and changes.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh logs',
                        onPressed: _loadLogs,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 23),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                          TextButton.icon(
                            onPressed: _loadLogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 850 ? 3 : 1;
                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: _statCard(
                              label: 'Total Activities',
                              value: '${_logs.length}',
                              icon: Icons.receipt_long_outlined,
                              color: _ink,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _statCard(
                              label: 'Action Types',
                              value: '$uniqueActions',
                              icon: Icons.category_outlined,
                              color: _orange,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _statCard(
                              label: 'Matching Records',
                              value: '${filtered.length}',
                              icon: Icons.filter_alt_outlined,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'Search user, action, details or IP address...',
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
                        borderSide:
                            const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  DropdownButtonFormField<String>(
                    value: _actionFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Filter by action',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _actions.map((action) {
                      return DropdownMenuItem<String>(
                        value: action,
                        child: Text(action),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _actionFilter = value);
                      }
                    },
                  ),
                  const SizedBox(height: 19),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Activity History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ),
                      Text(
                        '${filtered.length} records',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.history_toggle_off,
                            size: 43,
                            color: Colors.black38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error == null
                                ? 'No audit records found'
                                : 'Audit logs could not be loaded',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Try refreshing or changing your filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(_logCard),
                  const SizedBox(height: 10),
                  const Text(
                    'Audit logs are read-only on this page. Records are not '
                    'created or modified from the frontend.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
