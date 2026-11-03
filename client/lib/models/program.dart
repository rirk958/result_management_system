class Program {
  final int id;
  final int departmentId;
  final String departmentName;
  final String departmentCode;
  final String code;
  final String name;
  final String degreeName;
  final int totalSemesters;
  final bool isActive;

  const Program({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    required this.code,
    required this.name,
    required this.degreeName,
    required this.totalSemesters,
    required this.isActive,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: _toInt(json['id']),
      departmentId: _toInt(json['department_id']),
      departmentName: json['department_name']?.toString() ?? '',
      departmentCode: json['department_code']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      degreeName: json['degree_name']?.toString() ?? 'Bachelor',
      totalSemesters: _toInt(json['total_semesters']),
      isActive: json['is_active'] == true ||
          json['is_active']?.toString() == 'true',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}