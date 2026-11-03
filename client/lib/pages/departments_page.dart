
import 'package:flutter/material.dart';

import '../models/department.dart';
import '../services/department_service.dart';
import '../widgets/department_form_dialog.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Department> _departments = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final departments = await DepartmentService.getDepartments();

      if (!mounted) return;

      setState(() {
        _departments = departments;
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

  List<Department> get _filteredDepartments {
    final query = _searchController.text.trim().toLowerCase();

    return _departments.where((department) {
      final matchesSearch = department.name.toLowerCase().contains(query) ||
          department.code.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && department.isActive) ||
          (_statusFilter == 'inactive' && !department.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openForm({Department? department}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DepartmentFormDialog(
        department: department,
      ),
    );

    if (result == true) {
      await _loadDepartments();
      if (!mounted) return;
      _showMessage(
        department == null
            ? 'Department created successfully.'
            : 'Department updated successfully.',
      );
    }
  }

  Future<void> _toggleStatus(Department department) async {
    final newStatus = !department.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus ? 'Activate Department?' : 'Deactivate Department?',
        ),
        content: Text(
          'Are you sure you want to ${newStatus ? 'activate' : 'deactivate'} '
              '${department.name} (${department.code})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DepartmentService.updateDepartmentStatus(
        id: department.id,
        isActive: newStatus,
      );

      await _loadDepartments();

      if (!mounted) return;
      _showMessage(
        newStatus
            ? 'Department activated.'
            : 'Department deactivated.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    count.toString(),
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

  @override
  Widget build(BuildContext context) {
    final activeCount =
        _departments.where((department) => department.isActive).length;
    final inactiveCount = _departments.length - activeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departments',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Manage academic departments of IST.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _loadDepartments,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Department'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 800 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 8,
                    childAspectRatio: columns == 3 ? 2.8 : 4.5,
                    children: [
                      _statCard(
                        title: 'Total Departments',
                        count: _departments.length,
                        icon: Icons.account_balance,
                        color: Colors.blue,
                      ),
                      _statCard(
                        title: 'Active Departments',
                        count: activeCount,
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _statCard(
                        title: 'Inactive Departments',
                        count: inactiveCount,
                        icon: Icons.pause_circle_outline,
                        color: Colors.red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by department name or code...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.clear),
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _filterChip('All', 'all'),
                            _filterChip('Active', 'active'),
                            _filterChip('Inactive', 'inactive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: _buildDepartmentList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (_) {
        setState(() => _statusFilter = value);
      },
    );
  }

  Widget _buildDepartmentList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadDepartments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final departments = _filteredDepartments;

    if (departments.isEmpty) {
      return const Center(
        child: Text('No departments found.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return ListView.separated(
            itemCount: departments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final department = departments[index];
              return _departmentTile(department);
            },
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              color: const Color(0xFFF0F0F0),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text('CODE')),
                  Expanded(flex: 3, child: Text('DEPARTMENT NAME')),
                  Expanded(flex: 1, child: Text('STATUS')),
                  SizedBox(width: 110, child: Text('ACTIONS')),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: departments.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final department = departments[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            department.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(department.name),
                        ),
                        Expanded(
                          flex: 1,
                          child: _statusLabel(department.isActive),
                        ),
                        SizedBox(
                          width: 110,
                          child: _actions(department),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _departmentTile(Department department) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFE5D5),
        child: Text(
          department.code.isEmpty ? '?' : department.code[0],
          style: const TextStyle(
            color: Color(0xFFE65100),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        department.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${department.code} • ${department.isActive ? 'Active' : 'Inactive'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _openForm(department: department);
          } else if (value == 'status') {
            _toggleStatus(department);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          PopupMenuItem(
            value: 'status',
            child: Text(
              department.isActive ? 'Deactivate' : 'Activate',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusLabel(bool isActive) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withValues(alpha: 0.10)
              : Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _actions(Department department) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Edit department',
          onPressed: () => _openForm(department: department),
          icon: const Icon(Icons.edit_outlined, size: 19),
        ),
        IconButton(
          tooltip: department.isActive ? 'Deactivate' : 'Activate',
          onPressed: () => _toggleStatus(department),
          icon: Icon(
            department.isActive
                ? Icons.toggle_on_outlined
                : Icons.toggle_off_outlined,
            size: 22,
            color: department.isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
