
import 'package:flutter/material.dart';

import '../models/grading_scale.dart';
import '../services/grading_scale_service.dart';

class GradingScalesPage extends StatefulWidget {
  const GradingScalesPage({super.key});

  @override
  State<GradingScalesPage> createState() => _GradingScalesPageState();
}

class _GradingScalesPageState extends State<GradingScalesPage> {
  static const Color _orange = Color(0xFFF97316);
  static const Color _background = Color(0xFFF7F7F8);

  final TextEditingController _searchController = TextEditingController();

  List<GradingScale> _scales = [];
  String _search = '';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final scales = await GradingScaleService.getGradingScales();

      if (!mounted) return;

      setState(() {
        _scales = scales;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<GradingScale> get _filtered {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _scales;

    return _scales.where((scale) {
      return scale.letterGrade.toLowerCase().contains(query) ||
          scale.description.toLowerCase().contains(query) ||
          scale.minMarks.toString().contains(query) ||
          scale.maxMarks.toString().contains(query) ||
          scale.gradePoint.toString().contains(query);
    }).toList();
  }

  Future<void> _openForm({GradingScale? scale}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _GradingScaleDialog(scale: scale),
    );

    if (saved == true && mounted) {
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scale == null
                ? 'Grading scale created successfully.'
                : 'Grading scale updated successfully.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _delete(GradingScale scale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete grading scale?'),
        content: Text(
          'Delete grade ${scale.letterGrade} '
          '(${scale.minMarks}–${scale.maxMarks})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await GradingScaleService.deleteGradingScale(scale.id);

      if (!mounted) return;

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grading scale deleted.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete grading scale: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 5),
                Text(
                  value,
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
    );
  }

  Widget _gradeBadge(String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        grade,
        style: const TextStyle(
          color: _orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _gradeCard(GradingScale scale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _gradeBadge(scale.letterGrade),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scale.description.isEmpty
                      ? 'Grade details'
                      : scale.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _openForm(scale: scale);
                  if (value == 'delete') _delete(scale);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _info(
                  'Minimum marks',
                  '${scale.minMarks}%',
                ),
              ),
              Expanded(
                child: _info(
                  'Maximum marks',
                  '${scale.maxMarks}%',
                ),
              ),
              Expanded(
                child: _info(
                  'Grade point',
                  scale.gradePoint.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scales = _filtered;
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.grade_outlined,
                      color: _orange,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grading Scales',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure marks, letter grades and grade points.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_loading && _error == null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _statCard(
                        'Total grades',
                        '${_scales.length}',
                        Icons.grade_outlined,
                        _orange,
                      ),
                      _statCard(
                        'Highest grade point',
                        _scales.isEmpty
                            ? '—'
                            : _scales
                                .map((s) => s.gradePoint)
                                .reduce((a, b) => a > b ? a : b)
                                .toStringAsFixed(2),
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ];

                    if (constraints.maxWidth >= 650) {
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                      ],
                    );
                  },
                ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Search grade, marks or description...',
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Grade'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Could not load grading scales.'),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (scales.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      children: [
                        const Icon(Icons.grade_outlined, size: 44),
                        const SizedBox(height: 12),
                        const Text(
                          'No grading scales found',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_search.isEmpty)
                          FilledButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create grading scale'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (wide)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Grade')),
                        DataColumn(label: Text('Minimum %')),
                        DataColumn(label: Text('Maximum %')),
                        DataColumn(label: Text('Grade Point')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: scales.map((scale) {
                        return DataRow(
                          cells: [
                            DataCell(_gradeBadge(scale.letterGrade)),
                            DataCell(Text('${scale.minMarks}')),
                            DataCell(Text('${scale.maxMarks}')),
                            DataCell(
                              Text(scale.gradePoint.toStringAsFixed(2)),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  scale.description.isEmpty
                                      ? '—'
                                      : scale.description,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => _openForm(scale: scale),
                                    icon: const Icon(Icons.edit_outlined),
                                    color: _orange,
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => _delete(scale),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                ...scales.map(_gradeCard),
              const SizedBox(height: 20),
              if (!_loading && _error == null && scales.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Showing ${scales.length} of ${_scales.length} grading scales',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradingScaleDialog extends StatefulWidget {
  final GradingScale? scale;

  const _GradingScaleDialog({this.scale});

  @override
  State<_GradingScaleDialog> createState() => _GradingScaleDialogState();
}

class _GradingScaleDialogState extends State<_GradingScaleDialog> {
  static const Color orange = Color(0xFFF97316);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _gradeController;
  late final TextEditingController _pointController;
  late final TextEditingController _descriptionController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final scale = widget.scale;
    _minController = TextEditingController(
      text: scale?.minMarks.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: scale?.maxMarks.toString() ?? '',
    );
    _gradeController = TextEditingController(
      text: scale?.letterGrade ?? '',
    );
    _pointController = TextEditingController(
      text: scale?.gradePoint.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: scale?.description ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _gradeController.dispose();
    _pointController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value, String label) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null) return 'Enter a valid $label.';
    if (!number.isFinite) return 'Enter a finite $label.';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final min = double.parse(_minController.text.trim());
    final max = double.parse(_maxController.text.trim());
    final point = double.parse(_pointController.text.trim());
    final grade = _gradeController.text.trim().toUpperCase();

    if (min < 0 || max > 100 || min > max) {
      setState(() {
        _error = 'Marks must be between 0 and 100, with minimum ≤ maximum.';
      });
      return;
    }

    if (point < 0) {
      setState(() => _error = 'Grade point cannot be negative.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final scale = widget.scale;

      if (scale == null) {
        await GradingScaleService.createGradingScale(
          minMarks: min,
          maxMarks: max,
          letterGrade: grade,
          gradePoint: point,
          description: _descriptionController.text.trim(),
        );
      } else {
        await GradingScaleService.updateGradingScale(
          id: scale.id,
          minMarks: min,
          maxMarks: max,
          letterGrade: grade,
          gradePoint: point,
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String numberLabel,
    bool numeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }

        if (numeric) {
          return _validateNumber(value, numberLabel);
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.scale == null ? 'Create Grading Scale' : 'Edit Grading Scale',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  controller: _gradeController,
                  label: 'Letter Grade',
                  numberLabel: '',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _minController,
                        label: 'Minimum Marks (%)',
                        numberLabel: 'minimum marks',
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _maxController,
                        label: 'Maximum Marks (%)',
                        numberLabel: 'maximum marks',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _pointController,
                  label: 'Grade Point',
                  numberLabel: 'grade point',
                  numeric: true,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: orange),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
