
import pool from "../config/db.js";

// Calculate and save a student's result for one course enrollment
export const calculateCourseResult = async (req, res) => {
  const client = await pool.connect();

  try {
    const { enrollment_id } = req.params;

    if (!/^\d+$/.test(enrollment_id) || Number(enrollment_id) < 1) {
      return res.status(400).json({ message: "Invalid enrollment ID" });
    }

    await client.query("BEGIN");

    // Get enrollment, program, course credit, and offering details.
    const enrollmentResult = await client.query(
      `SELECT
         e.id AS enrollment_id,
         e.status AS enrollment_status,
         co.status AS offering_status,
         co.program_id,
         c.credit
       FROM enrollments e
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       WHERE e.id = $1
       FOR UPDATE OF e`,
      [enrollment_id]
    );

    if (enrollmentResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Enrollment not found" });
    }

    const enrollment = enrollmentResult.rows[0];

    if (
      enrollment.enrollment_status !== "enrolled" &&
      enrollment.enrollment_status !== "completed"
    ) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Results can only be calculated for enrolled or completed students",
      });
    }

    if (enrollment.offering_status !== "open" &&
        enrollment.offering_status !== "completed") {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "The course offering must be active or completed",
      });
    }

    // Get every active assessment for this course offering and any marks entered.
    const assessmentResult = await client.query(
      `SELECT
         a.id AS assessment_id,
         a.name AS assessment_name,
         a.max_marks,
         a.weight_percent,
         m.obtained_marks
       FROM assessments a
       LEFT JOIN marks m
         ON m.assessment_id = a.id
        AND m.enrollment_id = $1
       JOIN enrollments e ON e.id = $1
       WHERE a.course_offering_id = e.course_offering_id
         AND a.is_active = TRUE
       ORDER BY a.display_order, a.id`,
      [enrollment_id]
    );

    const assessments = assessmentResult.rows;

    if (assessments.length === 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "No active assessments exist for this course offering",
      });
    }

    const missingMarks = assessments.filter(
      (assessment) => assessment.obtained_marks == null
    );

    if (missingMarks.length > 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Some assessments do not have marks entered yet",
        missing_assessments: missingMarks.map((a) => ({
          assessment_id: a.assessment_id,
          assessment_name: a.assessment_name,
        })),
      });
    }

    const totalWeight = assessments.reduce(
      (sum, assessment) => sum + Number(assessment.weight_percent),
      0
    );

    if (Math.abs(totalWeight - 100) > 0.01) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: `Active assessment weights must total 100%. Current total: ${totalWeight}%`,
      });
    }

    // Calculate raw total marks and the weighted final percentage.
    let totalMarks = 0;
    let percentage = 0;

    for (const assessment of assessments) {
      const obtained = Number(assessment.obtained_marks);
      const maximum = Number(assessment.max_marks);
      const weight = Number(assessment.weight_percent);

      if (
        !Number.isFinite(obtained) ||
        !Number.isFinite(maximum) ||
        maximum <= 0 ||
        obtained < 0 ||
        obtained > maximum
      ) {
        await client.query("ROLLBACK");
        return res.status(400).json({
          message: `Invalid marks or maximum marks for assessment ${assessment.assessment_id}`,
        });
      }

      totalMarks += obtained;
      percentage += (obtained / maximum) * weight;
    }

    percentage = Math.round((percentage + Number.EPSILON) * 100) / 100;

    // Find the matching grade for the student's program.
    const gradeResult = await client.query(
      `SELECT grade_letter, grade_point
       FROM grading_scales
       WHERE program_id = $1
         AND $2 >= min_percent
         AND $2 <= max_percent
       ORDER BY min_percent DESC
       LIMIT 1`,
      [enrollment.program_id, percentage]
    );

    if (gradeResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: `No grading scale matches ${percentage}% for this program`,
      });
    }

    const { grade_letter, grade_point } = gradeResult.rows[0];
    const qualityPoints =
      Math.round(
        (Number(enrollment.credit) * Number(grade_point) + Number.EPSILON) *
          100
      ) / 100;

    // Update an existing result, or insert one if this is the first calculation.
    const existingResult = await client.query(
      "SELECT id FROM course_results WHERE enrollment_id = $1",
      [enrollment_id]
    );

    let savedResult;

    if (existingResult.rows.length > 0) {
      savedResult = await client.query(
        `UPDATE course_results
         SET total_marks = $1,
             percentage = $2,
             grade_letter = $3,
             grade_point = $4,
             quality_points = $5,
             calculated_at = CURRENT_TIMESTAMP
         WHERE enrollment_id = $6
         RETURNING *`,
        [
          totalMarks,
          percentage,
          grade_letter,
          grade_point,
          qualityPoints,
          enrollment_id,
        ]
      );
    } else {
      savedResult = await client.query(
        `INSERT INTO course_results
           (enrollment_id, total_marks, percentage, grade_letter,
            grade_point, quality_points, calculated_at)
         VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
         RETURNING *`,
        [
          enrollment_id,
          totalMarks,
          percentage,
          grade_letter,
          grade_point,
          qualityPoints,
        ]
      );
    }

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Course result calculated successfully",
      result: savedResult.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Calculate course result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Get all course results, optionally filtered by enrollment
export const getCourseResults = async (req, res) => {
  try {
    const { enrollment_id } = req.query;

    if (
      enrollment_id != null &&
      (!/^\d+$/.test(String(enrollment_id)) || Number(enrollment_id) < 1)
    ) {
      return res.status(400).json({ message: "Invalid enrollment ID" });
    }

    const result = await pool.query(
      `SELECT
         cr.*,
         e.student_id,
         s.student_no,
         u.full_name AS student_name,
         co.course_id,
         c.code AS course_code,
         c.title AS course_title,
         c.credit,
         sem.name AS semester_name,
         acs.name AS session_name
       FROM course_results cr
       JOIN enrollments e ON e.id = cr.enrollment_id
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       JOIN semesters sem ON sem.id = co.semester_id
       JOIN academic_sessions acs ON acs.id = co.session_id
       WHERE ($1::bigint IS NULL OR cr.enrollment_id = $1)
       ORDER BY s.student_no, c.code`,
      [enrollment_id || null]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get course results error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get one course result by result ID
export const getCourseResultById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid course result ID" });
    }

    const result = await pool.query(
      `SELECT
         cr.*,
         e.student_id,
         s.student_no,
         u.full_name AS student_name,
         co.course_id,
         c.code AS course_code,
         c.title AS course_title,
         c.credit,
         sem.name AS semester_name,
         acs.name AS session_name
       FROM course_results cr
       JOIN enrollments e ON e.id = cr.enrollment_id
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       JOIN semesters sem ON sem.id = co.semester_id
       JOIN academic_sessions acs ON acs.id = co.session_id
       WHERE cr.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Course result not found" });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get course result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
