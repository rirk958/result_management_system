import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";

const gradingScales = [
  { grade: "A+", min: 80, max: 100, point: 4.00 },
  { grade: "A",  min: 75, max: 79,  point: 3.75 },
  { grade: "A-", min: 70, max: 74,  point: 3.50 },
  { grade: "B+", min: 65, max: 69,  point: 3.25 },
  { grade: "B",  min: 60, max: 64,  point: 3.00 },
  { grade: "B-", min: 55, max: 59,  point: 2.75 },
  { grade: "C+", min: 50, max: 54,  point: 2.50 },
  { grade: "C",  min: 45, max: 49,  point: 2.25 },
  { grade: "D",  min: 40, max: 44,  point: 2.00 },
  { grade: "F",  min: 0,  max: 39,  point: 0.00 },
];

async function setupGradingScales() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const programResult = await client.query(
      `SELECT id FROM programs WHERE code = $1`,
      [PROGRAM_CODE]
    );

    if (programResult.rowCount === 0) {
      throw new Error(`Program ${PROGRAM_CODE} not found`);
    }

    const programId = programResult.rows[0].id;

    for (const item of gradingScales) {
      await client.query(
        `INSERT INTO grading_scales
          (program_id, grade_letter, min_percent, max_percent, grade_point)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (program_id, grade_letter) DO NOTHING`,
        [
          programId,
          item.grade,
          item.min,
          item.max,
          item.point,
        ]
      );
    }

    await client.query("COMMIT");

    console.log("Grading scales configured successfully!");

    const result = await client.query(
      `SELECT grade_letter, min_percent, max_percent, grade_point
       FROM grading_scales
       WHERE program_id = $1
       ORDER BY min_percent DESC`,
      [programId]
    );

    console.table(result.rows);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Grading scale setup failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

setupGradingScales();