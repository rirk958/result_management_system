
import pool from "../config/db.js";

// Calculate and save a semester result
export const calculateSemesterResult = async (req, res) => {
  const client = await pool.connect();

  try {
    const { student_id, semester_id, session_id } = req.body;

    if (
      student_id == null ||
      semester_id == null ||
      session_id == null ||
      !/^\d+$/.test(String(student_id)) ||
      !/^\d+$/.test(String(semester_id)) ||
      !/^\d+$/.test(String(session_id)) ||
      Number(student_id) < 1 ||
      Number(semester_id) < 1 ||
      Number(session_id) < 1
    ) {
      return res.status(400).json({
        message: "Valid student_id, semester_id, and session_id are required",
      });
    }

    await client.query("BEGIN");

    // Confirm the student, semester, and session combination is valid.
    const context = await client.query(
      `SELECT s.id, s.program_id
       FROM students s
       JOIN semesters sem ON sem.id = $2
       JOIN academic_sessions acs ON acs.id = $3
       WHERE s.id = $1
         AND sem.program_id = s.program_id`,
      [student_id, semester_id, session_id]
    );

    if (context.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Student, semester, or session is invalid for this program",
      });
    }

    // Get all enrollments for this student in this semester and session.
    const courses = await client.query(
      `SELECT
         e.id AS enrollment_id,
         c.credit,
         cr.id AS course_result_id,
         cr.quality_points,
         cr.grade_point
       FROM enrollments e
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       LEFT JOIN course_results cr ON cr.enrollment_id = e.id
       WHERE e.student_id = $1
         AND co.semester_id = $2
         AND co.session_id = $3
         AND e.status IN ('enrolled', 'completed')
       ORDER BY e.id`,
      [student_id, semester_id, session_id]
    );

    if (courses.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "No eligible enrollments found for this semester",
      });
    }

    const missingResults = courses.rows.filter(
      (course) => course.course_result_id == null
    );

    if (missingResults.length > 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Calculate all course results before calculating semester GPA",
        missing_enrollment_ids: missingResults.map(
          (course) => course.enrollment_id
        ),
      });
    }

    const totalCredits = courses.rows.reduce(
      (sum, course) => sum + Number(course.credit),
      0
    );

    const totalQualityPoints = courses.rows.reduce(
      (sum, course) => sum + Number(course.quality_points),
      0
    );

    if (totalCredits <= 0) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Total course credits must be greater than zero",
      });
    }

    const gpa = Math.round(
      (totalQualityPoints / totalCredits + Number.EPSILON) * 100
    ) / 100;

    // Calculate CGPA from all course results available for this student.
    const cumulative = await client.query(
      `SELECT
         COALESCE(SUM(c.credit), 0) AS total_credits,
         COALESCE(SUM(cr.quality_points), 0) AS total_quality_points
       FROM enrollments e
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       JOIN course_results cr ON cr.enrollment_id = e.id
       WHERE e.student_id = $1
         AND e.status IN ('enrolled', 'completed')`,
      [student_id]
    );

    const cumulativeCredits = Number(
      cumulative.rows[0].total_credits
    );
    const cumulativeQualityPoints = Number(
      cumulative.rows[0].total_quality_points
    );

    const cgpa =
      cumulativeCredits > 0
        ? Math.round(
            (cumulativeQualityPoints / cumulativeCredits +
              Number.EPSILON) *
              100
          ) / 100
        : 0;

    // Update the existing result or create one.
    const existing = await client.query(
      `SELECT id
       FROM semester_results
       WHERE student_id = $1
         AND semester_id = $2
         AND session_id = $3
       FOR UPDATE`,
      [student_id, semester_id, session_id]
    );

    let saved;

    if (existing.rows.length > 0) {
      saved = await client.query(
        `UPDATE semester_results
         SET gpa = $1,
             cgpa = $2,
             calculated_at = CURRENT_TIMESTAMP
         WHERE id = $3
         RETURNING *`,
        [gpa, cgpa, existing.rows[0].id]
      );
    } else {
      saved = await client.query(
        `INSERT INTO semester_results
           (student_id, semester_id, session_id, gpa, cgpa,
            status, calculated_at)
         VALUES ($1, $2, $3, $4, $5, 'draft', CURRENT_TIMESTAMP)
         RETURNING *`,
        [student_id, semester_id, session_id, gpa, cgpa]
      );
    }

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Semester result calculated successfully",
      result: saved.rows[0],
      calculation: {
        semester_credits: totalCredits,
        semester_quality_points: totalQualityPoints,
        cumulative_credits: cumulativeCredits,
        cumulative_quality_points: cumulativeQualityPoints,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");

    if (error.code === "23503") {
      return res.status(400).json({
        message: "A referenced student, semester, or session does not exist",
      });
    }

    console.error("Calculate semester result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Get semester results, optionally filtered
export const getSemesterResults = async (req, res) => {
  try {
    const { student_id, semester_id, session_id, status } = req.query;

    const result = await pool.query(
      `SELECT
         sr.*,
         s.student_no,
         u.full_name AS student_name,
         sem.name AS semester_name,
         acs.name AS session_name
       FROM semester_results sr
       JOIN students s ON s.id = sr.student_id
       JOIN users u ON u.id = s.user_id
       JOIN semesters sem ON sem.id = sr.semester_id
       JOIN academic_sessions acs ON acs.id = sr.session_id
       WHERE ($1::bigint IS NULL OR sr.student_id = $1)
         AND ($2::bigint IS NULL OR sr.semester_id = $2)
         AND ($3::bigint IS NULL OR sr.session_id = $3)
         AND ($4::text IS NULL OR sr.status = $4)
       ORDER BY acs.start_date DESC, s.student_no, sem.semester_number`,
      [
        student_id || null,
        semester_id || null,
        session_id || null,
        status || null,
      ]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get semester results error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get one semester result by ID
export const getSemesterResultById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid semester result ID" });
    }

    const result = await pool.query(
      `SELECT
         sr.*,
         s.student_no,
         u.full_name AS student_name,
         sem.name AS semester_name,
         acs.name AS session_name
       FROM semester_results sr
       JOIN students s ON s.id = sr.student_id
       JOIN users u ON u.id = s.user_id
       JOIN semesters sem ON sem.id = sr.semester_id
       JOIN academic_sessions acs ON acs.id = sr.session_id
       WHERE sr.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Semester result not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get semester result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
