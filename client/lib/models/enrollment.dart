
class Enrollment {
  final int id;
  final int studentId;
  final int courseOfferingId;
  final String studentNo;
  final String studentName;
  final String courseCode;
  final String courseName;
  final String sessionName;
  final String status;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseOfferingId,
    required this.studentNo,
    required this.studentName,
    required this.courseCode,
    required this.courseName,
    required this.sessionName,
    required this.status,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Enrollment(
      id: toInt(json['id']),
      studentId: toInt(json['student_id']),
      courseOfferingId: toInt(json['course_offering_id']),
      studentNo: (json['student_no'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      courseCode: (json['course_code'] ?? '').toString(),
      courseName: (json['course_title'] ?? '').toString(),
      sessionName: (json['session_name'] ?? '').toString(),
      status: (json['status'] ?? 'enrolled').toString(),
    );
  }
}
