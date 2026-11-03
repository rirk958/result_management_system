
class SemesterResult {
  final int id;
  final int studentId;
  final int semesterId;
  final int sessionId;
  final String studentNo;
  final String studentName;
  final String semesterName;
  final String sessionName;
  final double gpa;
  final double cgpa;
  final String status;
  final DateTime? calculatedAt;

  const SemesterResult({
    required this.id,
    required this.studentId,
    required this.semesterId,
    required this.sessionId,
    required this.studentNo,
    required this.studentName,
    required this.semesterName,
    required this.sessionName,
    required this.gpa,
    required this.cgpa,
    required this.status,
    required this.calculatedAt,
  });

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    return SemesterResult(
      id: _toInt(json['id']),
      studentId: _toInt(json['student_id']),
      semesterId: _toInt(json['semester_id']),
      sessionId: _toInt(json['session_id']),
      studentNo: json['student_no']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      semesterName: json['semester_name']?.toString() ?? '',
      sessionName: json['session_name']?.toString() ?? '',
      gpa: _toDouble(json['gpa']),
      cgpa: _toDouble(json['cgpa']),
      status: json['status']?.toString() ?? 'draft',
      calculatedAt: _toDate(json['calculated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
