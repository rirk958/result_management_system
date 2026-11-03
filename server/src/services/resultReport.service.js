
import pool from "../config/db.js";

const isValidId = (value) =>
  Number.isSafeInteger(Number(value)) && Number(value) > 0;

// GET /api/reports/semester-results?semester_id=1&session_id=1
export const getSemesterResultReport = async (req, res) => {
  try {
    const { semester_id, session_id } = req.query;

    if (!isValidId(semester_id) || !isValidId(session_id)) {
      return res.status(400).json({
        message: "Valid semester_id and session_id are required",
      });
    }

    const result = await pool.query(
      `SELECT
         sr.id AS semester_result_id,
         s.id AS student_id,
         s.student_no,
         u.full_name AS student_name,
         p.code AS program_code,
         sem.name AS semester_name,
         sem.semester_number,
         ses.name AS session_name,
         sr.gpa,
         sr.cgpa,
         sr.status,
         sr.published_at
       FROM semester_results sr
       JOIN students s ON s.id = sr.student_id
       JOIN users u ON u.id = s.user_id
       JOIN semesters sem ON sem.id = sr.semester_id
       JOIN academic_sessions ses ON ses.id = sr.session_id
       JOIN programs p ON p.id = sem.program_id
       WHERE sr.semester_id = $1
         AND sr.session_id = $2
         AND sr.status = 'published'
       ORDER BY s.student_no ASC`,
      [Number(semester_id), Number(session_id)]
    );

    return res.status(200).json({
      message: "Semester result report retrieved successfully",
      total_students: result.rows.length,
      results: result.rows,
    });
  } catch (error) {
    console.error("Semester result report error:", error);

    return res.status(500).json({
      message: "Failed to retrieve semester result report",
    });
  }
};

// GET /api/reports/course-results?course_offering_id=1
export const getCourseResultReport = async (req, res) => {
  try {
    const { course_offering_id } = req.query;

    if (!isValidId(course_offering_id)) {
      return res.status(400).json({
        message: "A valid course_offering_id is required",
      });
    }

    const offeringResult = await pool.query(
      `SELECT
         co.id AS course_offering_id,
         c.code AS course_code,
         c.title AS course_title,
         c.credit,
         co.section_name,
         co.status AS offering_status,
         p.name AS program_name,
         sem.name AS semester_name,
         ses.name AS session_name
       FROM course_offerings co
       JOIN courses c ON c.id = co.course_id
       JOIN programs p ON p.id = co.program_id
       JOIN semesters sem ON sem.id = co.semester_id
       JOIN academic_sessions ses ON ses.id = co.session_id
       WHERE co.id = $1`,
      [Number(course_offering_id)]
    );

    if (offeringResult.rows.length === 0) {
      return res.status(404).json({
        message: "Course offering not found",
      });
    }

    const result = await pool.query(
      `SELECT
         e.id AS enrollment_id,
         s.id AS student_id,
         s.student_no,
         u.full_name AS student_name,
         e.status AS enrollment_status,
         cr.total_marks,
         cr.percentage,
         cr.grade_letter,
         cr.grade_point,
         COALESCE(
           json_agg(
             json_build_object(
               'assessment_id', a.id,
               'assessment_name', a.name,
               'max_marks', a.max_marks,
               'obtained_marks', m.obtained_marks
             )
             ORDER BY a.display_order, a.id
           ) FILTER (WHERE a.id IS NOT NULL),
           '[]'::json
         ) AS assessments
       FROM enrollments e
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       LEFT JOIN course_results cr ON cr.enrollment_id = e.id
       LEFT JOIN assessments a
         ON a.course_offering_id = $1
        AND a.is_active = TRUE
       LEFT JOIN marks m
         ON m.enrollment_id = e.id
        AND m.assessment_id = a.id
       WHERE e.course_offering_id = $1
       GROUP BY
         e.id,
         s.id,
         s.student_no,
         u.full_name,
         e.status,
         cr.total_marks,
         cr.percentage,
         cr.grade_letter,
         cr.grade_point
       ORDER BY s.student_no ASC`,
      [Number(course_offering_id)]
    );

    return res.status(200).json({
      message: "Course result report retrieved successfully",
      course: offeringResult.rows[0],
      total_students: result.rows.length,
      results: result.rows,
    });
  } catch (error) {
    console.error("Course result report error:", error);

    return res.status(500).json({
      message: "Failed to retrieve course result report",
    });
  }
};
