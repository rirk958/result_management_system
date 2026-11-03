import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const SEMESTER_NUMBER = 1;
const SECTION_NAME = "A";

async function enrollStudents() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // Find program
    const programResult = await client.query(
      `SELECT id FROM programs WHERE code = $1`,
      [PROGRAM_CODE]
    );

    if (programResult.rowCount === 0) {
      throw new Error(`Program ${PROGRAM_CODE} not found`);
    }

    const programId = programResult.rows[0].id;

    // Find academic session
    const sessionResult = await client.query(
      `SELECT id FROM academic_sessions WHERE name = $1`,
      [SESSION_NAME]
    );

    if (sessionResult.rowCount === 0) {
      throw new Error(`Session ${SESSION_NAME} not found`);
    }

    const sessionId = sessionResult.rows[0].id;

    // Find first semester
    const semesterResult = await client.query(
      `SELECT id FROM semesters
       WHERE program_id = $1 AND semester_number = $2`,
      [programId, SEMESTER_NUMBER]
    );

    if (semesterResult.rowCount === 0) {
      throw new Error("First semester not found");
    }

    const semesterId = semesterResult.rows[0].id;

    // Find all active students in this program and session
    const studentsResult = await client.query(
      `SELECT s.id
       FROM students s
       JOIN users u ON u.id = s.user_id
       WHERE s.program_id = $1
         AND s.session_id = $2
         AND s.status = 'active'
         AND u.is_active = TRUE`,
      [programId, sessionId]
    );

    // Find all course offerings for this semester
    const offeringsResult = await client.query(
      `SELECT id
       FROM course_offerings
       WHERE program_id = $1
         AND session_id = $2
         AND semester_id = $3
         AND section_name = $4`,
      [programId, sessionId, semesterId, SECTION_NAME]
    );

    if (studentsResult.rowCount === 0) {
      throw new Error("No active students found");
    }

    if (offeringsResult.rowCount === 0) {
      throw new Error("No course offerings found");
    }

    let inserted = 0;
    let skipped = 0;

    for (const student of studentsResult.rows) {
      for (const offering of offeringsResult.rows) {
        const result = await client.query(
          `INSERT INTO enrollments
            (student_id, course_offering_id)
           VALUES ($1, $2)
           ON CONFLICT (student_id, course_offering_id)
           DO NOTHING
           RETURNING id`,
          [student.id, offering.id]
        );

        if (result.rowCount > 0) {
          inserted++;
        } else {
          skipped++;
        }
      }
    }

    await client.query("COMMIT");

    console.log("Enrollment completed successfully!");
    console.log("Students:", studentsResult.rowCount);
    console.log("Course offerings:", offeringsResult.rowCount);
    console.log("New enrollments:", inserted);
    console.log("Already enrolled:", skipped);
    console.log(
      "Expected total enrollments:",
      studentsResult.rowCount * offeringsResult.rowCount
    );
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Enrollment failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

enrollStudents();