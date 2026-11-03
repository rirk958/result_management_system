
class CourseOffering {
  final int id;
  final int courseId;
  final int sessionId;
  final String courseCode;
  final String courseName;
  final String sessionName;
  final bool isActive;

  const CourseOffering({
    required this.id,
    required this.courseId,
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.sessionName,
    required this.isActive,
  });

  factory CourseOffering.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CourseOffering(
      id: toInt(json['id']),
      courseId: toInt(json['course_id']),
      sessionId: toInt(json['session_id']),
      courseCode: (json['course_code'] ?? '').toString(),
      courseName: (json['course_title'] ?? '').toString(),
      sessionName: (json['session_name'] ?? '').toString(),
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == 'true',
    );
  }
}
