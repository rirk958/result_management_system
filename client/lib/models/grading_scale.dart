

class GradingScale {
  final int id;
  final int programId;
  final double minMarks;
  final double maxMarks;
  final String letterGrade;
  final double gradePoint;
  final String description;

  const GradingScale({
    required this.id,
    required this.programId,
    required this.minMarks,
    required this.maxMarks,
    required this.letterGrade,
    required this.gradePoint,
    required this.description,
  });

  factory GradingScale.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return GradingScale(
      id: toInt(json['id']),
      programId: toInt(json['program_id']),
      minMarks: toDouble(json['min_percent']),
      maxMarks: toDouble(json['max_percent']),
      letterGrade: (json['grade_letter'] ?? '').toString(),
      gradePoint: toDouble(json['grade_point']),
      description: (json['description'] ?? '').toString(),
    );
  }
}
