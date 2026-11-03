class AcademicSession {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const AcademicSession({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory AcademicSession.fromJson(Map<String, dynamic> json) {
    return AcademicSession(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      isActive: json['is_active'] == true ||
          json['is_active']?.toString() == 'true',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}