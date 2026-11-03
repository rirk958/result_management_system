import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const SEMESTER_NUMBER = 1;

async function calculateSemesterResults() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // Find program, session, and semester.
    const setupResult = await client.query(
      `SELECT
         p.id AS program_id,
         s.id AS session_id,
         sem.id AS semester_id
       FROM programs p
       JOIN academic_sessions s ON s.name = $2
       JOIN semesters sem
         ON sem.program_id = p.id
        AND sem.semester_number = $3
       WHERE p.code = $1`,
      [PROGRAM_CODE, SESSION_NAME, SEMESTER_NUMBER]
    );

    if (setupResult.rowCount !== 1) {
      throw new Error("Program, session, or semester not found");
    }

    const { program_id, session_id, semester_id } =
      setupResult.rows[0];

    // Find all course offerings.
    const offeringResult = await client.query(
      `SELECT id
       FROM course_offerings
       WHERE program_id = $1
         AND session_id = $2
         AND semester_id = $3`,
      [program_id, session_id, semester_id]
    );

    const expectedCourses = offeringResult.rowCount;

    if (expectedCourses === 0) {
      throw new Error("No course offerings found");
    }

    // Find all students in this program and session.
    const studentsResult = await client.query(
      `SELECT id
       FROM students
       WHERE program_id = $1
         AND session_id = $2
       ORDER BY id`,
      [program_id, session_id]
    );

    let inserted = 0;
    let updated = 0;

    for (const student of studentsResult.rows) {
      // Calculate GPA from the student's course results.
      const result = await client.query(
        `SELECT
           COUNT(DISTINCT e.id) AS total_courses,
           COUNT(DISTINCT cr.enrollment_id) AS completed_results,
           COALESCE(SUM(c.credit), 0) AS total_credits,
           COALESCE(SUM(cr.quality_points), 0) AS total_quality_points
         FROM enrollments e
         JOIN course_offerings co
           ON co.id = e.course_offering_id
         JOIN courses c
           ON c.id = co.course_id
         LEFT JOIN course_results cr
           ON cr.enrollment_id = e.id
         WHERE e.student_id = $1
           AND co.program_id = $2
           AND co.session_id = $3
           AND co.semester_id = $4
           AND co.status IN ('open', 'completed')
           AND e.status IN ('enrolled', 'completed')`,
        [student.id, program_id, session_id, semester_id]
      );

      const data = result.rows[0];

      const totalCourses = Number(data.total_courses);
      const completedResults = Number(data.completed_results);
      const totalCredits = Number(data.total_credits);
      const totalQualityPoints = Number(data.total_quality_points);

      if (totalCourses !== expectedCourses) {
        throw new Error(
          `Student ${student.id} has ${totalCourses} enrollments; expected ${expectedCourses}`
        );
      }

      if (completedResults !== expectedCourses) {
        throw new Error(
          `Student ${student.id} has incomplete course results: ${completedResults}/${expectedCourses}`
        );
      }

      if (totalCredits <= 0) {
        throw new Error(
          `Invalid total credits for student ${student.id}`
        );
      }

      const gpa = Math.round(
        (totalQualityPoints / totalCredits + Number.EPSILON) * 100
      ) / 100;

      // First semester: CGPA equals GPA.
      const cgpa = gpa;

      // Check whether a published result already exists.
      const existing = await client.query(
        `SELECT id, status
         FROM semester_results
         WHERE student_id = $1
           AND semester_id = $2
           AND session_id = $3`,
        [student.id, semester_id, session_id]
      );

      if (
        existing.rowCount > 0 &&
        existing.rows[0].status === "published"
      ) {
        throw new Error(
          `Student ${student.id} already has a published result. Aborting to protect it.`
        );
      }

      // Insert or update draft result.
      const saved = await client.query(
        `INSERT INTO semester_results
          (student_id, semester_id, session_id, gpa, cgpa, status)
         VALUES ($1, $2, $3, $4, $5, 'draft')
         ON CONFLICT (student_id, semester_id, session_id)
         DO UPDATE SET
           gpa = EXCLUDED.gpa,
           cgpa = EXCLUDED.cgpa,
           calculated_at = CURRENT_TIMESTAMP
         RETURNING (xmax = 0) AS inserted`,
        [
          student.id,
          semester_id,
          session_id,
          gpa,
          cgpa,
        ]
      );

      if (saved.rows[0].inserted) {
        inserted++;
      } else {
        updated++;
      }
    }

    await client.query("COMMIT");

    console.log("\nSemester result calculation completed!");
    console.log("Students processed:", studentsResult.rowCount);
    console.log("Courses per student:", expectedCourses);
    console.log("New semester results:", inserted);
    console.log("Updated draft results:", updated);
    console.log("Total semester results:", inserted + updated);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Semester calculation failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

calculateSemesterResults();