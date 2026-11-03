
import 'package:flutter/material.dart';

import '../models/program.dart';
import '../models/semester.dart';
import '../services/program_service.dart';
import '../services/semester_service.dart';
import '../widgets/semester_form_dialog.dart';

class SemestersPage extends StatefulWidget {
  const SemestersPage({super.key});

  @override
  State<SemestersPage> createState() => _SemestersPageState();
}

class _SemestersPageState extends State<SemestersPage> {
  List<Semester> _semesters = [];
  List<Program> _programs = [];

  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = 'all';
  int? _programFilter;

  static const _orange = Color(0xFFF58220);
  static const _ink = Color(0xFF171717);
  static const _surface = Color(0xFFF7F7F8);

  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        SemesterService.getSemesters(),
        ProgramService.getPrograms(),
      ]);

      if (!mounted) return;

      setState(() {
        _semesters = results[0] as List<Semester>;
        _programs = results[1] as List<Program>;
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


  List<Semester> get _filteredSemesters {
    final query = _search.trim().toLowerCase();

    return _semesters.where((semester) {
      final matchesSearch = query.isEmpty ||
          semester.name.toLowerCase().contains(query) ||
          semester.programName.toLowerCase().contains(query) ||
          semester.programCode.toLowerCase().contains(query) ||
          semester.semesterNumber.toString().contains(query);

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && semester.isActive) ||
          (_statusFilter == 'inactive' && !semester.isActive);

      final matchesProgram =
          _programFilter == null || semester.programId == _programFilter;

      return matchesSearch && matchesStatus && matchesProgram;
    }).toList();
  }

  int get _activeCount =>
      _semesters.where((semester) => semester.isActive).length;

  Future<void> _openForm({Semester? semester}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SemesterFormDialog(semester: semester),
    );

    if (saved == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _toggleStatus(Semester semester) async {
    final activate = !semester.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activate ? 'Activate Semester' : 'Deactivate Semester'),
        content: Text(
          'Are you sure you want to ${activate ? 'activate' : 'deactivate'} '
              '"${semester.name}"?',
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
      await SemesterService.updateSemesterStatus(
        id: semester.id,
        isActive: activate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? 'Semester activated.' : 'Semester deactivated.',
          ),
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semesters = _filteredSemesters;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildError()
              : LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              return ListView(
                padding: EdgeInsets.all(compact ? 16 : 28),
                children: [
                  _buildHeader(compact),
                  const SizedBox(height: 24),
                  _buildStats(compact),
                  const SizedBox(height: 24),
                  _buildFilters(compact),
                  const SizedBox(height: 16),
                  _buildResultsHeader(semesters.length),
                  const SizedBox(height: 12),
                  if (semesters.isEmpty)
                    _buildEmpty()
                  else if (compact)
                    ...semesters.map(_buildMobileCard)
                  else
                    _buildTable(semesters),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 14,
      spacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semesters',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Manage program semesters and their status.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: _programs.isEmpty ? null : () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Semester'),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool compact) {
    final total = _semesters.length;
    final inactive = total - _activeCount;

    final cards = [
      _StatData('Total Semesters', total, Icons.school_outlined, _ink),
      _StatData('Active', _activeCount, Icons.check_circle_outline,
          Colors.green.shade700),
      _StatData('Inactive', inactive, Icons.pause_circle_outline,
          Colors.red.shade700),
      _StatData('Programs', _programs.length, Icons.account_tree_outlined,
          _orange),
    ];

    return GridView.count(
      crossAxisCount: compact ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: compact ? 1.65 : 1.8,
      children: cards.map((card) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(card.icon, color: card.color, size: 23),
              Text(
                '${card.value}',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                card.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilters(bool compact) {
    final searchField = TextField(
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: 'Search semester or program...',
        prefixIcon: const Icon(Icons.search),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );

    final programDropdown = DropdownButtonFormField<int?>(
      initialValue: _programFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Program',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All programs'),
        ),
        ..._programs.map(
              (program) => DropdownMenuItem<int?>(
            value: program.id,
            child: Text(
              '${program.code} — ${program.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      selectedItemBuilder: (context) => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('All programs'),
        ),
        ..._programs.map(
              (program) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${program.code} — ${program.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _programFilter = value),
    );

    final statusDropdown = DropdownButtonFormField<String>(
      initialValue: _statusFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All statuses')),
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _statusFilter = value);
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: compact
          ? Column(
        children: [
          searchField,
          const SizedBox(height: 12),
          programDropdown,
          const SizedBox(height: 12),
          statusDropdown,
        ],
      )
          : Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 12),
          Expanded(child: programDropdown),
          const SizedBox(width: 12),
          SizedBox(width: 170, child: statusDropdown),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Semester Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count result${count == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildTable(List<Semester> semesters) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFF1F1F2),
          ),
          columns: const [
            DataColumn(label: Text('Semester')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Number')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: semesters.map((semester) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      semester.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Text(
                      '${semester.programCode} — ${semester.programName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text('${semester.semesterNumber}')),
                DataCell(_statusBadge(semester.isActive)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit semester',
                        onPressed: () => _openForm(semester: semester),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: semester.isActive ? 'Deactivate' : 'Activate',
                        onPressed: () => _toggleStatus(semester),
                        icon: Icon(
                          semester.isActive
                              ? Icons.pause_circle_outline
                              : Icons.check_circle_outline,
                          color: semester.isActive
                              ? Colors.red.shade700
                              : Colors.green.shade700,
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
    );
  }

  Widget _buildMobileCard(Semester semester) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    semester.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusBadge(semester.isActive),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${semester.programCode} — ${semester.programName}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text('Semester number: ${semester.semesterNumber}'),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openForm(semester: semester),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleStatus(semester),
                    icon: Icon(
                      semester.isActive
                          ? Icons.pause_circle_outline
                          : Icons.check_circle_outline,
                    ),
                    label: Text(semester.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.school_outlined, size: 46, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No semesters found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing the search or filters, or add a semester.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Unable to load semesters',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}
