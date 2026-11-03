import pool from "../src/config/db.js";

async function generateRandomMarks() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const result = await client.query(`
      SELECT
        e.id AS enrollment_id,
        a.id AS assessment_id,
        a.max_marks
      FROM enrollments e
      JOIN assessments a
        ON a.course_offering_id = e.course_offering_id
      ORDER BY e.id, a.display_order
    `);

    if (result.rowCount === 0) {
      throw new Error("No enrollment assessments found");
    }

    let inserted = 0;
    let skipped = 0;

    for (const item of result.rows) {
      const maxMarks = Number(item.max_marks);

      // Random percentage between 35% and 98%
      const percentage = 35 + Math.random() * 63;

      const obtainedMarks = Math.min(
        maxMarks,
        Math.round(maxMarks * percentage) / 100
      );

      const insertResult = await client.query(
        `INSERT INTO marks
          (enrollment_id, assessment_id, obtained_marks)
         VALUES ($1, $2, $3)
         ON CONFLICT (enrollment_id, assessment_id)
         DO NOTHING
         RETURNING id`,
        [
          item.enrollment_id,
          item.assessment_id,
          obtainedMarks,
        ]
      );

      if (insertResult.rowCount > 0) {
        inserted++;
      } else {
        skipped++;
      }
    }

    await client.query("COMMIT");

    console.log("\nRandom marks generated successfully!");
    console.log("Assessment combinations:", result.rowCount);
    console.log("New marks inserted:", inserted);
    console.log("Existing marks skipped:", skipped);
    console.log("Total marks processed:", inserted + skipped);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Mark generation failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

generateRandomMarks();