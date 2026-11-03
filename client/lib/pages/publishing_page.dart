
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';

class PublishingPage extends StatefulWidget {
  const PublishingPage({super.key});

  @override
  State<PublishingPage> createState() => _PublishingPageState();
}

class _PublishingPageState extends State<PublishingPage> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color _orange = Color(0xFFF47721);
  static const Color _ink = Color(0xFF202124);

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      for (final key in ['data', 'results', 'items', 'records']) {
        if (decoded[key] is List) {
          return decoded[key] as List;
        }
      }
    }

    return [];
  }

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.get('/semester-results');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseMessage(response.body, 'Could not load semester results.'),
        );
      }

      final decoded = jsonDecode(response.body);
      final rows = _extractList(decoded);

      if (!mounted) return;

      setState(() {
        _results = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
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
        return (decoded['message'] ??
                decoded['error'] ??
                decoded['detail'] ??
                fallback)
            .toString();
      }
    } catch (_) {
      // Use the fallback for non-JSON responses.
    }

    return fallback;
  }

  int _id(Map<String, dynamic> row) {
    final value = row['id'] ?? row['semester_result_id'];
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  String _status(Map<String, dynamic> row) {
    return _value(row, ['status', 'publication_status'],
            fallback: 'draft')
        .toLowerCase()
        .trim();
  }

  bool _isPublished(Map<String, dynamic> row) {
    return ['published', 'public', 'released'].contains(_status(row));
  }

  List<Map<String, dynamic>> get _filteredResults {
    final query = _search.trim().toLowerCase();

    return _results.where((row) {
      final published = _isPublished(row);

      if (_filter == 'Published' && !published) return false;
      if (_filter == 'Draft' && published) return false;

      if (query.isEmpty) return true;

      final searchable = [
        _value(row, ['student_no', 'student_number']),
        _value(row, ['student_name', 'full_name', 'name']),
        _value(row, ['semester_name', 'semester']),
        _value(row, ['session_name', 'session']),
        _status(row),
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _changePublication(
    Map<String, dynamic> row,
    bool publish,
  ) async {
    final id = _id(row);

    if (id <= 0) {
      _showMessage('This result does not have a valid ID.', isError: true);
      return;
    }

    final action = publish ? 'publish' : 'unpublish';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(publish ? 'Publish result?' : 'Unpublish result?'),
        content: Text(
          publish
              ? 'This will mark the selected semester result as published. '
                  'Students may be able to view it if the backend exposes published results.'
              : 'This will return the selected result to draft status, '
                  'if supported by the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(publish ? 'Publish' : 'Unpublish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Expected backend endpoint:
      // PUT /api/publishing/:id/publish
      // PUT /api/publishing/:id/unpublish
      final response = await ApiClient.put(
        '/publishing/$id/$action',
        body:<String, dynamic>{},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _responseMessage(
            response.body,
            'Could not $action this result. Check the backend publishing route.',
          ),
        );
      }

      if (!mounted) return;

      _showMessage(
        publish ? 'Result published successfully.' : 'Result unpublished.',
      );

      await _loadResults();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _statCard(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
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
                  '$value',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool published) {
    final color = published ? Colors.green.shade700 : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> row) {
    final published = _isPublished(row);
    final studentName =
        _value(row, ['student_name', 'full_name', 'name']);
    final studentNo = _value(row, ['student_no', 'student_number']);
    final semester = _value(row, ['semester_name', 'semester']);
    final session = _value(row, ['session_name', 'session']);
    final gpa = _value(row, ['gpa', 'semester_gpa']);
    final cgpa = _value(row, ['cgpa', 'cumulative_gpa']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9E9E9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      studentNo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(published),
            ],
          ),
          const Divider(height: 25),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _detail('Semester', semester),
              _detail('Session', session),
              _detail('GPA', gpa),
              _detail('CGPA', cgpa),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _changePublication(row, !published),
              icon: Icon(
                published ? Icons.unpublished_outlined : Icons.publish,
                size: 18,
              ),
              label: Text(published ? 'Unpublish' : 'Publish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: published ? Colors.red.shade700 : _orange,
                side: BorderSide(
                  color: published ? Colors.red.shade200 : _orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return SizedBox(
      width: 135,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final publishedCount = _results.where(_isPublished).length;
    final draftCount = _results.length - publishedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadResults,
          child: ListView(
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
                      Icons.publish_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Result Publishing',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Review and manage semester result publication.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadResults,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_loading)
                const LinearProgressIndicator(color: _orange)
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 850
                        ? 3
                        : constraints.maxWidth >= 520
                            ? 2
                            : 1;
                    const gap = 12.0;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Total Results',
                            _results.length,
                            Icons.assessment_outlined,
                            _ink,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Published',
                            publishedCount,
                            Icons.check_circle_outline,
                            Colors.green.shade700,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _statCard(
                            'Drafts',
                            draftCount,
                            Icons.pending_actions_outlined,
                            _orange,
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
                    hintText: 'Search student, semester or session...',
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Draft', 'Published'].map((filter) {
                    return ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      selectedColor: _orange.withValues(alpha: 0.17),
                      onSelected: (_) => setState(() => _filter = filter),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
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
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadResults,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                if (_filteredResults.isEmpty && _error == null)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 42,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Calculate semester results first, or change your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ..._filteredResults.map(_buildResultCard),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
