
import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const SEMESTER_NUMBER = 1;
const SECTION_NAME = "A";

const courses = [
  ["510201", "Structured Programming Language (C language)", 3.0],
  ["510202", "Structured Programming Language Lab", 1.5],
  ["510203", "Electrical and Electronic Circuit", 3.0],
  ["510204", "Electrical and Electronic Circuit Lab", 1.5],
  ["510205", "Calculus (Differential and Integral)", 3.0],
  ["510207", "Physics", 3.0],
  ["510209", "English (Communication Skills)", 3.0],
];

async function setupFirstSemester() {
  const client = await pool.connect();

  let coursesCreated = 0;
  let offeringsCreated = 0;

  try {
    await client.query("BEGIN");

    // Find program
    const programResult = await client.query(
      "SELECT id, department_id FROM programs WHERE code = $1",
      [PROGRAM_CODE]
    );

    if (programResult.rowCount !== 1) {
      throw new Error(`Program ${PROGRAM_CODE} not found.`);
    }

    const program = programResult.rows[0];

    // Find academic session
    const sessionResult = await client.query(
      "SELECT id FROM academic_sessions WHERE name = $1",
      [SESSION_NAME]
    );

    if (sessionResult.rowCount !== 1) {
      throw new Error(`Session ${SESSION_NAME} not found.`);
    }

    const sessionId = sessionResult.rows[0].id;

    // Find first semester
    const semesterResult = await client.query(
      `SELECT id FROM semesters
       WHERE program_id = $1 AND semester_number = $2`,
      [program.id, SEMESTER_NUMBER]
    );

    if (semesterResult.rowCount !== 1) {
      throw new Error("First semester not found.");
    }

    const semesterId = semesterResult.rows[0].id;

    for (const [code, title, credit] of courses) {
      // Find or create course
      let courseResult = await client.query(
        "SELECT id FROM courses WHERE code = $1",
        [code]
      );

      let courseId;

      if (courseResult.rowCount > 0) {
        courseId = courseResult.rows[0].id;
      } else {
        courseResult = await client.query(
          `INSERT INTO courses
            (department_id, code, title, credit)
           VALUES ($1, $2, $3, $4)
           RETURNING id`,
          [program.department_id, code, title, credit]
        );

        courseId = courseResult.rows[0].id;
        coursesCreated++;
      }

      // Find or create course offering
      const offeringResult = await client.query(
        `SELECT id FROM course_offerings
         WHERE course_id = $1
           AND program_id = $2
           AND session_id = $3
           AND semester_id = $4
           AND section_name = $5`,
        [
          courseId,
          program.id,
          sessionId,
          semesterId,
          SECTION_NAME,
        ]
      );

      if (offeringResult.rowCount === 0) {
        await client.query(
          `INSERT INTO course_offerings
            (course_id, program_id, session_id, semester_id, section_name)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            courseId,
            program.id,
            sessionId,
            semesterId,
            SECTION_NAME,
          ]
        );

        offeringsCreated++;
      }

      console.log(`Processed: ${code} - ${title}`);
    }

    await client.query("COMMIT");

    console.log("\n========== SETUP SUMMARY ==========");
    console.log("Courses in list:", courses.length);
    console.log("New courses:", coursesCreated);
    console.log("New course offerings:", offeringsCreated);
    console.log("Program:", PROGRAM_CODE);
    console.log("Session:", SESSION_NAME);
    console.log("Semester: First Semester");
    console.log("Section:", SECTION_NAME);
    console.log("===================================");

  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Setup failed. All changes rolled back.");
    console.error(error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

setupFirstSemester();
