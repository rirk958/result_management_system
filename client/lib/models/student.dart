class Student {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String studentNo;
  final int programId;
  final String programName;
  final String programCode;
  final int sessionId;
  final String sessionName;
  final String admissionDate;
  final String status;

  Student({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.studentNo,
    required this.programId,
    required this.programName,
    required this.programCode,
    required this.sessionId,
    required this.sessionName,
    required this.admissionDate,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      studentNo: json['student_no']?.toString() ?? '',
      programId: _toInt(json['program_id']),
      programName: json['program_name']?.toString() ?? '',
      programCode: json['program_code']?.toString() ?? '',
      sessionId: _toInt(json['session_id']),
      sessionName: json['session_name']?.toString() ?? '',
      admissionDate: json['admission_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}