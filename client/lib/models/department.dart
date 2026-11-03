
class Department {
  final int id;
  final String code;
  final String name;
  final bool isActive;

  const Department({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _toInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] == true ||
          json['is_active']?.toString() == 'true',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
