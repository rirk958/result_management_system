class Semester {
  final int id;
  final int programId;
  final int semesterNumber;
  final String name;
  final String programCode;
  final String programName;
  final bool isActive;

  const Semester({
    required this.id,
    required this.programId,
    required this.semesterNumber,
    required this.name,
    required this.programCode,
    required this.programName,
    required this.isActive,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: _toInt(json['id']),
      programId: _toInt(json['program_id']),
      semesterNumber: _toInt(json['semester_number']),
      name: json['name']?.toString() ?? '',
      programCode: json['program_code']?.toString() ?? '',
      programName: json['program_name']?.toString() ?? '',
      isActive: json['is_active'] == true ||
          json['is_active']?.toString() == 'true',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}