
class CourseResult {
  final int id;
  final int studentId;
  final int enrollmentId;
  final String studentNo;
  final String studentName;
  final String courseCode;
  final String courseName;
  final String sessionName;
  final double totalMarks;
  final double percentage;
  final double gradePoint;
  final String letterGrade;
  final String status;

  const CourseResult({
    required this.id,
    required this.studentId,
    required this.enrollmentId,
    required this.studentNo,
    required this.studentName,
    required this.courseCode,
    required this.courseName,
    required this.sessionName,
    required this.totalMarks,
    required this.percentage,
    required this.gradePoint,
    required this.letterGrade,
    required this.status,
  });

  factory CourseResult.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CourseResult(
      id: toInt(json['id']),
      studentId: toInt(json['student_id']),
      enrollmentId: toInt(json['enrollment_id']),
      studentNo: (json['student_no'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      courseCode: (json['course_code'] ?? '').toString(),
      courseName: (json['course_name'] ?? '').toString(),
      sessionName: (json['session_name'] ?? '').toString(),
      totalMarks: toDouble(json['total_marks']),
      percentage: toDouble(json['percentage']),
      gradePoint: toDouble(json['grade_point']),
      letterGrade: (json['letter_grade'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
    );
  }
}
