import 'package:flutter/material.dart';

import '../models/program.dart';
import '../services/program_service.dart';
import '../widgets/program_form_dialog.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  List<Program> _programs = [];

  bool _loading = true;
  String? _error;

  String _search = '';
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final programs = await ProgramService.getPrograms();

      if (!mounted) return;

      setState(() {
        _programs = programs;
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

  List<Program> get _filteredPrograms {
    final query = _search.trim().toLowerCase();

    return _programs.where((program) {
      final matchesSearch = query.isEmpty ||
          program.code.toLowerCase().contains(query) ||
          program.name.toLowerCase().contains(query) ||
          program.departmentName.toLowerCase().contains(query) ||
          program.degreeName.toLowerCase().contains(query);

      final matchesDepartment = _selectedDepartmentId == null ||
          program.departmentId == _selectedDepartmentId;

      return matchesSearch && matchesDepartment;
    }).toList();
  }

  List<Map<String, dynamic>> get _departments {
    final unique = <int, Map<String, dynamic>>{};

    for (final program in _programs) {
      unique[program.departmentId] = {
        'id': program.departmentId,
        'name': program.departmentName,
        'code': program.departmentCode,
      };
    }

    final result = unique.values.toList();
    result.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
    );

    return result;
  }

  Future<void> _openProgramForm({Program? program}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProgramFormDialog(program: program),
    );

    if (result == true) {
      await _loadPrograms();
    }
  }

  Future<void> _deactivateProgram(Program program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate Program'),
        content: Text(
          'Are you sure you want to deactivate "${program.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ProgramService.deactivateProgram(program.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program deactivated successfully.'),
        ),
      );

      await _loadPrograms();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
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
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          width: 300,
          child: TextField(
            onChanged: (value) {
              setState(() => _search = value);
            },
            decoration: InputDecoration(
              hintText: 'Search programs...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: _selectedDepartmentId,
            decoration: InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            selectedItemBuilder: (context) {
              return [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All Departments',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                ..._departments.map(
                      (department) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${department['code']} - ${department['name']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ];
            },
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Departments'),
              ),
              ..._departments.map(
                    (department) => DropdownMenuItem<int?>(
                  value: department['id'] as int,
                  child: SizedBox(
                    width: 200,
                    child: Text(
                      '${department['code']} - ${department['name']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedDepartmentId = value);
            },
          )
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final programs = _filteredPrograms;

    if (programs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No programs found.')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 850),
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
            Colors.grey.withValues(alpha: 0.08),
          ),
          columns: const [
            DataColumn(label: Text('PROGRAM')),
            DataColumn(label: Text('DEPARTMENT')),
            DataColumn(label: Text('DEGREE')),
            DataColumn(label: Text('SEMESTERS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: programs.map((program) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          program.code,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      '${program.departmentCode} - ${program.departmentName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(program.degreeName)),
                DataCell(Text('${program.totalSemesters}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit program',
                        onPressed: () => _openProgramForm(program: program),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Deactivate program',
                        onPressed: () => _deactivateProgram(program),
                        icon: const Icon(
                          Icons.block,
                          color: Colors.red,
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

  Widget _buildMobileList() {
    final programs = _filteredPrograms;

    if (programs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No programs found.')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: programs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final program = programs[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          title: Text(
            program.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${program.code} • ${program.departmentName}\n'
                  '${program.degreeName} • ${program.totalSemesters} semesters',
            ),
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openProgramForm(program: program);
              } else if (value == 'deactivate') {
                _deactivateProgram(program);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'deactivate',
                child: Text('Deactivate'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPrograms,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Programs',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Manage academic programs and degree structures.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openProgramForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Program'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_loading && _error == null)
                isWide
                    ? Row(
                  children: [
                    _buildStatCard(
                      title: 'Active Programs',
                      value: _programs.length,
                      icon: Icons.menu_book_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 14),
                    _buildStatCard(
                      title: 'Departments',
                      value: _departments.length,
                      icon: Icons.account_balance_outlined,
                      color: Colors.blue,
                    ),
                  ],
                )
                    : Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          title: 'Active Programs',
                          value: _programs.length,
                          icon: Icons.menu_book_outlined,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          title: 'Departments',
                          value: _departments.length,
                          icon: Icons.account_balance_outlined,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.18),
                  ),
                ),
                child: _loading
                    ? const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : _error != null
                    ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadPrograms,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : isWide
                    ? _buildDesktopTable()
                    : _buildMobileList(),
              ),
              const SizedBox(height: 20),
              if (!_loading && _error == null)
                Text(
                  'Showing ${_filteredPrograms.length} of ${_programs.length} active programs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}