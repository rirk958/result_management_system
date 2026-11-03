
class Assessment {
  final int id;
  final int courseOfferingId;
  final String name;
  final double maxMarks;
  final String courseCode;
  final String courseName;
  final String sessionName;
  final bool isActive;

  const Assessment({
    required this.id,
    required this.courseOfferingId,
    required this.name,
    required this.maxMarks,
    required this.courseCode,
    required this.courseName,
    required this.sessionName,
    required this.isActive,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(dynamic value) {
      if (value is bool) return value;
      return value?.toString().toLowerCase() == 'true';
    }

    return Assessment(
      id: toInt(json['id']),
      courseOfferingId: toInt(json['course_offering_id']),
      name: (json['name'] ?? '').toString(),
      maxMarks: toDouble(json['max_marks']),
      courseCode: (json['course_code'] ?? '').toString(),
      courseName: (json['course_name'] ?? '').toString(),
      sessionName: (json['session_name'] ?? '').toString(),
      isActive: toBool(json['is_active']),
    );
  }
}
