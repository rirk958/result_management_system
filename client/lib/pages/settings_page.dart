
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _orange = Color(0xFFF97316);

  final _institutionController = TextEditingController();
  final _academicYearController = TextEditingController();

  String _defaultResultStatus = 'Draft';
  String _defaultSemester = '1';
  bool _requireConfirmation = true;
  bool _showGpa = true;
  bool _showCgpa = true;

  @override
  void dispose() {
    _institutionController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'These settings are currently temporary. '
          'Database saving has not been connected yet.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _institutionController.clear();
      _academicYearController.clear();
      _defaultResultStatus = 'Draft';
      _defaultSemester = '1';
      _requireConfirmation = true;
      _showGpa = true;
      _showCgpa = true;
    });
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: _orange,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(compact ? 16 : 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: _orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Settings',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure academic and result display preferences.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _section(
              title: 'Institution Information',
              subtitle: 'Basic details for your institution.',
              icon: Icons.account_balance_outlined,
              children: [
                _textField(
                  label: 'Institution name',
                  hint: 'Enter institution name',
                  controller: _institutionController,
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 16),
                _textField(
                  label: 'Current academic year',
                  hint: 'e.g. 2026-2027',
                  controller: _academicYearController,
                  icon: Icons.calendar_month_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),

            _section(
              title: 'Academic Defaults',
              subtitle: 'Initial values used when preparing results.',
              icon: Icons.menu_book_outlined,
              children: [
                _dropdown(
                  label: 'Default semester number',
                  value: _defaultSemester,
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: '${index + 1}',
                      child: Text('Semester ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _defaultSemester = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _dropdown(
                  label: 'Initial result status',
                  value: _defaultResultStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'Draft',
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem(
                      value: 'Pending Review',
                      child: Text('Pending Review'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _defaultResultStatus = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            _section(
              title: 'Result Display',
              subtitle: 'Choose which result information to display.',
              icon: Icons.assessment_outlined,
              children: [
                _toggle(
                  title: 'Display GPA',
                  subtitle: 'Show grade point average in result views.',
                  value: _showGpa,
                  onChanged: (value) {
                    setState(() => _showGpa = value);
                  },
                ),
                const Divider(height: 1),
                _toggle(
                  title: 'Display CGPA',
                  subtitle: 'Show cumulative grade point average.',
                  value: _showCgpa,
                  onChanged: (value) {
                    setState(() => _showCgpa = value);
                  },
                ),
                const Divider(height: 1),
                _toggle(
                  title: 'Confirm before publishing',
                  subtitle:
                      'Keep confirmation enabled before result publication.',
                  value: _requireConfirmation,
                  onChanged: (value) {
                    setState(() => _requireConfirmation = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            _section(
              title: 'Application Information',
              subtitle: 'Information about this system.',
              icon: Icons.info_outline,
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.apps_outlined),
                  title: Text('Application'),
                  subtitle: Text('Result Management System'),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.layers_outlined),
                  title: Text('Frontend'),
                  subtitle: Text('Flutter Web'),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Database'),
                  subtitle: Text('PostgreSQL'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetSettings,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
                FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Settings'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
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
}
