import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const SEMESTER_NUMBER = 1;

const theoryAssessments = [
  ["Assignment", 10, 10],
  ["Class Test", 10, 10],
  ["Midterm", 30, 30],
  ["Final Exam", 50, 50],
];

const labAssessments = [
  ["Lab Assignment / Report", 20, 20],
  ["Lab Performance", 20, 20],
  ["Midterm Practical", 20, 20],
  ["Final Practical", 40, 40],
];

async function setupAssessments() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const program = await client.query(
      `SELECT id FROM programs WHERE code = $1`,
      [PROGRAM_CODE]
    );

    if (!program.rowCount) {
      throw new Error("Program not found");
    }

    const session = await client.query(
      `SELECT id FROM academic_sessions WHERE name = $1`,
      [SESSION_NAME]
    );

    if (!session.rowCount) {
      throw new Error("Academic session not found");
    }

    const semester = await client.query(
      `SELECT id FROM semesters
       WHERE program_id = $1 AND semester_number = $2`,
      [program.rows[0].id, SEMESTER_NUMBER]
    );

    if (!semester.rowCount) {
      throw new Error("Semester not found");
    }

    const offerings = await client.query(
      `SELECT co.id, c.title
       FROM course_offerings co
       JOIN courses c ON c.id = co.course_id
       WHERE co.program_id = $1
         AND co.session_id = $2
         AND co.semester_id = $3`,
      [
        program.rows[0].id,
        session.rows[0].id,
        semester.rows[0].id,
      ]
    );

    if (!offerings.rowCount) {
      throw new Error(
        "No course offerings found. Run setup_first_semester.js first."
      );
    }

    let created = 0;

    for (const offering of offerings.rows) {
      const isLab = offering.title.toLowerCase().includes("lab");

      const assessments = isLab
        ? labAssessments
        : theoryAssessments;

      for (let i = 0; i < assessments.length; i++) {
        const [name, maxMarks, weight] = assessments[i];

        const result = await client.query(
          `INSERT INTO assessments
            (course_offering_id, name, max_marks, weight_percent, display_order)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (course_offering_id, name) DO NOTHING`,
          [offering.id, name, maxMarks, weight, i + 1]
        );

        created += result.rowCount;
      }

      console.log(
        `${offering.title}: ${assessments.length} assessments configured`
      );
    }

    await client.query("COMMIT");

    console.log(`\nAssessment setup completed. ${created} new records created.`);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Assessment setup failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

setupAssessments();