import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const SEMESTER_NUMBER = 1;
const SECTION_NAME = "A";

async function calculateAllResults() {
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
       JOIN academic_sessions s
         ON s.name = $2
       JOIN semesters sem
         ON sem.program_id = p.id
        AND sem.semester_number = $3
       WHERE p.code = $1`,
      [PROGRAM_CODE, SESSION_NAME, SEMESTER_NUMBER]
    );

    if (setupResult.rowCount === 0) {
      throw new Error("Program, session, or semester not found");
    }

    const { program_id, session_id, semester_id } =
      setupResult.rows[0];

    // Get all enrollments and their course information.
    const enrollmentsResult = await client.query(
      `SELECT
         e.id AS enrollment_id,
         e.status AS enrollment_status,
         co.status AS offering_status,
         co.program_id,
         c.credit
       FROM enrollments e
       JOIN course_offerings co
         ON co.id = e.course_offering_id
       JOIN courses c
         ON c.id = co.course_id
       WHERE co.program_id = $1
         AND co.session_id = $2
         AND co.semester_id = $3
         AND co.section_name = $4
       ORDER BY e.id`,
      [program_id, session_id, semester_id, SECTION_NAME]
    );

    let inserted = 0;
    let updated = 0;

    for (const enrollment of enrollmentsResult.rows) {
      if (
        !["enrolled", "completed"].includes(
          enrollment.enrollment_status
        )
      ) {
        throw new Error(
          `Enrollment ${enrollment.enrollment_id} has invalid status`
        );
      }

      if (
        !["open", "completed"].includes(
          enrollment.offering_status
        )
      ) {
        throw new Error(
          `Course offering for enrollment ${enrollment.enrollment_id} is not open or completed`
        );
      }

      // Get active assessments and marks.
      const assessmentsResult = await client.query(
        `SELECT
           a.id AS assessment_id,
           a.name AS assessment_name,
           a.max_marks,
           a.weight_percent,
           m.obtained_marks
         FROM assessments a
         JOIN enrollments e
           ON e.id = $1
         LEFT JOIN marks m
           ON m.assessment_id = a.id
          AND m.enrollment_id = e.id
         WHERE a.course_offering_id = e.course_offering_id
           AND a.is_active = TRUE
         ORDER BY a.display_order, a.id`,
        [enrollment.enrollment_id]
      );

      const assessments = assessmentsResult.rows;

      if (assessments.length === 0) {
        throw new Error(
          `No active assessments for enrollment ${enrollment.enrollment_id}`
        );
      }

      const missing = assessments.find(
        (a) => a.obtained_marks == null
      );

      if (missing) {
        throw new Error(
          `Missing marks: ${missing.assessment_name}, enrollment ${enrollment.enrollment_id}`
        );
      }

      const totalWeight = assessments.reduce(
        (sum, a) => sum + Number(a.weight_percent),
        0
      );

      if (Math.abs(totalWeight - 100) > 0.01) {
        throw new Error(
          `Assessment weights must total 100 for enrollment ${enrollment.enrollment_id}`
        );
      }

      let totalMarks = 0;
      let percentage = 0;

      for (const assessment of assessments) {
        const obtained = Number(assessment.obtained_marks);
        const maximum = Number(assessment.max_marks);
        const weight = Number(assessment.weight_percent);

        if (
          !Number.isFinite(obtained) ||
          !Number.isFinite(maximum) ||
          maximum <= 0 ||
          obtained < 0 ||
          obtained > maximum
        ) {
          throw new Error(
            `Invalid marks in assessment ${assessment.assessment_id}`
          );
        }

        totalMarks += obtained;
        percentage += (obtained / maximum) * weight;
      }

      percentage =
        Math.round((percentage + Number.EPSILON) * 100) / 100;

      // Find grade.
      const gradeResult = await client.query(
        `SELECT grade_letter, grade_point
         FROM grading_scales
         WHERE program_id = $1
           AND $2 >= min_percent
           AND $2 <= max_percent
         ORDER BY min_percent DESC
         LIMIT 1`,
        [enrollment.program_id, percentage]
      );

      if (gradeResult.rowCount === 0) {
        throw new Error(
          `No grade found for ${percentage}%`
        );
      }

      const { grade_letter, grade_point } =
        gradeResult.rows[0];

      const qualityPoints =
        Math.round(
          (
            Number(enrollment.credit) *
            Number(grade_point) +
            Number.EPSILON
          ) * 100
        ) / 100;

      // Insert or update course result.
      const savedResult = await client.query(
        `INSERT INTO course_results
          (enrollment_id, total_marks, percentage,
           grade_letter, grade_point, quality_points)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (enrollment_id)
         DO UPDATE SET
           total_marks = EXCLUDED.total_marks,
           percentage = EXCLUDED.percentage,
           grade_letter = EXCLUDED.grade_letter,
           grade_point = EXCLUDED.grade_point,
           quality_points = EXCLUDED.quality_points,
           calculated_at = CURRENT_TIMESTAMP
         RETURNING (xmax = 0) AS inserted`,
        [
          enrollment.enrollment_id,
          totalMarks,
          percentage,
          grade_letter,
          grade_point,
          qualityPoints,
        ]
      );

      if (savedResult.rows[0].inserted) {
        inserted++;
      } else {
        updated++;
      }
    }

    await client.query("COMMIT");

    console.log("\nCourse result calculation completed!");
    console.log("Enrollments processed:", enrollmentsResult.rowCount);
    console.log("New results:", inserted);
    console.log("Updated results:", updated);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Calculation failed:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

calculateAllResults();