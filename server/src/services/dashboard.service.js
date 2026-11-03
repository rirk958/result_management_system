
import pool from "../config/db.js";

// GET /api/dashboard
export const getDashboard = async (req, res) => {
  try {
    // 1. Main system statistics
    const overviewResult = await pool.query(`
      SELECT
        (SELECT COUNT(*) FROM departments) AS total_departments,
        (SELECT COUNT(*) FROM programs) AS total_programs,
        (SELECT COUNT(*) FROM academic_sessions) AS total_sessions,
        (SELECT COUNT(*) FROM semesters) AS total_semesters,
        (SELECT COUNT(*) FROM courses) AS total_courses,

        (SELECT COUNT(*) FROM students) AS total_students,
        (SELECT COUNT(*) FROM students
         WHERE status = 'active') AS active_students,

        (SELECT COUNT(*) FROM teachers) AS total_teachers,
        (SELECT COUNT(*) FROM teachers
         WHERE is_active = TRUE) AS active_teachers,

        (SELECT COUNT(*) FROM users) AS total_users,
        (SELECT COUNT(*) FROM users
         WHERE is_active = TRUE) AS active_users,

        (SELECT COUNT(*) FROM course_offerings)
          AS total_course_offerings,
        (SELECT COUNT(*) FROM course_offerings
         WHERE status = 'active') AS active_course_offerings,

        (SELECT COUNT(*) FROM enrollments) AS total_enrollments,
        (SELECT COUNT(*) FROM assessments) AS total_assessments,
        (SELECT COUNT(*) FROM marks) AS total_marks,
        (SELECT COUNT(*) FROM course_results) AS total_course_results,

        (SELECT COUNT(*) FROM semester_results
         WHERE status = 'published') AS published_semester_results,

        (SELECT COUNT(*) FROM semester_results
         WHERE status = 'draft') AS draft_semester_results
    `);

    // PostgreSQL COUNT values are commonly returned as strings.
    const overview = Object.fromEntries(
      Object.entries(overviewResult.rows[0]).map(([key, value]) => [
        key,
        Number(value),
      ])
    );

    // 2. Enrollment breakdown by status
    const enrollmentResult = await pool.query(`
      SELECT status, COUNT(*) AS total
      FROM enrollments
      GROUP BY status
      ORDER BY status
    `);

    const enrollmentsByStatus = enrollmentResult.rows.map((row) => ({
      status: row.status,
      total: Number(row.total),
    }));

    // 3. Published versus draft semester results
    const resultStatusResult = await pool.query(`
      SELECT status, COUNT(*) AS total
      FROM semester_results
      GROUP BY status
      ORDER BY status
    `);

    const semesterResultsByStatus = resultStatusResult.rows.map((row) => ({
      status: row.status,
      total: Number(row.total),
    }));

    // 4. Grade distribution from calculated course results
    const gradeResult = await pool.query(`
      SELECT
        grade_letter,
        COUNT(*) AS total
      FROM course_results
      GROUP BY grade_letter
      ORDER BY grade_letter
    `);

    const gradeDistribution = gradeResult.rows.map((row) => ({
      grade_letter: row.grade_letter,
      total: Number(row.total),
    }));

    // 5. Average percentage across calculated course results
    const averageResult = await pool.query(`
      SELECT ROUND(AVG(percentage), 2) AS average_percentage
      FROM course_results
    `);

    const averagePercentage =
      averageResult.rows[0].average_percentage === null
        ? null
        : Number(averageResult.rows[0].average_percentage);

    return res.status(200).json({
      message: "Dashboard statistics retrieved successfully",
      overview,
      enrollments_by_status: enrollmentsByStatus,
      semester_results_by_status: semesterResultsByStatus,
      grade_distribution: gradeDistribution,
      average_course_percentage: averagePercentage,
    });
  } catch (error) {
    console.error("Get dashboard error:", error);

    return res.status(500).json({
      message: "Failed to retrieve dashboard statistics",
    });
  }
};
