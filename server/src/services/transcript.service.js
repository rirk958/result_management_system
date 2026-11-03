
import pool from "../config/db.js";

// GET /api/students/:student_id/transcript
export const getStudentTranscript = async (req, res) => {
  try {
    const studentId = Number(req.params.student_id);

    if (!Number.isSafeInteger(studentId) || studentId <= 0) {
      return res.status(400).json({
        message: "Invalid student ID",
      });
    }

    // Get student information
    const studentResult = await pool.query(
      `SELECT
         s.id AS student_id,
         s.student_no,
         s.admission_date,
         s.status AS student_status,
         u.full_name,
         u.email,
         p.id AS program_id,
         p.code AS program_code,
         p.name AS program_name,
         p.degree_name,
         d.name AS department_name
       FROM students s
       JOIN users u ON u.id = s.user_id
       JOIN programs p ON p.id = s.program_id
       JOIN departments d ON d.id = p.department_id
       WHERE s.id = $1`,
      [studentId]
    );

    if (studentResult.rows.length === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    const student = studentResult.rows[0];

    // Get only published semester results
    const semesterResult = await pool.query(
      `SELECT
         sr.id AS semester_result_id,
         sr.semester_id,
         sr.session_id,
         sr.gpa,
         sr.cgpa,
         sr.published_at,
         sem.semester_number,
         sem.name AS semester_name,
         ses.name AS session_name,
         ses.start_date,
         ses.end_date
       FROM semester_results sr
       JOIN semesters sem ON sem.id = sr.semester_id
       JOIN academic_sessions ses ON ses.id = sr.session_id
       WHERE sr.student_id = $1
         AND sr.status = 'published'
       ORDER BY
         ses.start_date ASC,
         sem.semester_number ASC,
         sr.id ASC`,
      [studentId]
    );

    // Get courses belonging to published semester results only
    const courseResult = await pool.query(
      `SELECT
         sr.id AS semester_result_id,
         c.id AS course_id,
         c.code AS course_code,
         c.title AS course_title,
         c.credit,
         cr.total_marks,
         cr.percentage,
         cr.grade_letter,
         cr.grade_point,
         cr.quality_points
       FROM semester_results sr
       JOIN enrollments e ON e.student_id = sr.student_id
       JOIN course_offerings co
         ON co.id = e.course_offering_id
        AND co.semester_id = sr.semester_id
        AND co.session_id = sr.session_id
       JOIN courses c ON c.id = co.course_id
       JOIN course_results cr ON cr.enrollment_id = e.id
       WHERE sr.student_id = $1
         AND sr.status = 'published'
       ORDER BY c.code ASC`,
      [studentId]
    );

    // Group courses under their corresponding semester result
    const semesters = semesterResult.rows.map((semester) => ({
      semester_result_id: semester.semester_result_id,
      semester_id: semester.semester_id,
      semester_number: semester.semester_number,
      semester_name: semester.semester_name,
      session_id: semester.session_id,
      session_name: semester.session_name,
      session_start_date: semester.start_date,
      session_end_date: semester.end_date,
      gpa: semester.gpa,
      cgpa: semester.cgpa,
      published_at: semester.published_at,
      courses: courseResult.rows
        .filter(
          (course) =>
            course.semester_result_id === semester.semester_result_id
        )
        .map((course) => ({
          course_id: course.course_id,
          course_code: course.course_code,
          course_title: course.course_title,
          credit: course.credit,
          total_marks: course.total_marks,
          percentage: course.percentage,
          grade_letter: course.grade_letter,
          grade_point: course.grade_point,
          quality_points: course.quality_points,
        })),
    }));

    return res.status(200).json({
      student,
      transcript: {
        semesters,
        total_published_semesters: semesters.length,
      },
    });
  } catch (error) {
    console.error("Get student transcript error:", error);

    return res.status(500).json({
      message: "Failed to retrieve student transcript",
    });
  }
};
