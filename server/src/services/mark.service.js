
import pool from "../config/db.js";

// Create marks
export const createMark = async (req, res) => {
  try {
    const { enrollment_id, assessment_id, obtained_marks, entered_by } = req.body;

    if (
      enrollment_id == null ||
      assessment_id == null ||
      obtained_marks == null ||
      entered_by == null
    ) {
      return res.status(400).json({
        message:
          "enrollment_id, assessment_id, obtained_marks, and entered_by are required",
      });
    }

    const mark = Number(obtained_marks);

    if (!Number.isFinite(mark) || mark < 0) {
      return res.status(400).json({
        message: "obtained_marks must be a valid non-negative number",
      });
    }

    // Confirm that the enrollment and assessment belong to the same offering.
    const validation = await pool.query(
      `SELECT a.max_marks
       FROM enrollments e
       JOIN assessments a
         ON a.course_offering_id = e.course_offering_id
       WHERE e.id = $1
         AND a.id = $2
         AND a.is_active = TRUE`,
      [enrollment_id, assessment_id]
    );

    if (validation.rows.length === 0) {
      return res.status(400).json({
        message:
          "Invalid enrollment or assessment, or the assessment is inactive",
      });
    }

    if (mark > Number(validation.rows[0].max_marks)) {
      return res.status(400).json({
        message: `Marks cannot exceed ${validation.rows[0].max_marks}`,
      });
    }

    const result = await pool.query(
      `INSERT INTO marks
         (enrollment_id, assessment_id, obtained_marks, entered_by)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [enrollment_id, assessment_id, mark, entered_by]
    );

    return res.status(201).json({
      message: "Marks entered successfully",
      mark: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "Marks already exist for this enrollment and assessment",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "Invalid enrollment, assessment, or user ID",
      });
    }

    console.error("Create mark error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get all marks, with optional filters
export const getMarks = async (req, res) => {
  try {
    const { enrollment_id, assessment_id } = req.query;

    const result = await pool.query(
      `SELECT
         m.*,
         s.student_no,
         u.full_name AS student_name,
         a.name AS assessment_name,
         a.max_marks,
         c.title AS course_title
       FROM marks m
       JOIN enrollments e ON e.id = m.enrollment_id
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       JOIN assessments a ON a.id = m.assessment_id
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       WHERE ($1::bigint IS NULL OR m.enrollment_id = $1)
         AND ($2::bigint IS NULL OR m.assessment_id = $2)
       ORDER BY m.id DESC`,
      [enrollment_id || null, assessment_id || null]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get marks error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get one mark record
export const getMarkById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid mark ID" });
    }

    const result = await pool.query(
      `SELECT
         m.*,
         s.student_no,
         u.full_name AS student_name,
         a.name AS assessment_name,
         a.max_marks,
         c.title AS course_title
       FROM marks m
       JOIN enrollments e ON e.id = m.enrollment_id
       JOIN students s ON s.id = e.student_id
       JOIN users u ON u.id = s.user_id
       JOIN assessments a ON a.id = m.assessment_id
       JOIN course_offerings co ON co.id = e.course_offering_id
       JOIN courses c ON c.id = co.course_id
       WHERE m.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Mark record not found" });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get mark error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Update an existing mark
export const updateMark = async (req, res) => {
  try {
    const { id } = req.params;
    const { obtained_marks, entered_by } = req.body;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid mark ID" });
    }

    if (obtained_marks == null || entered_by == null) {
      return res.status(400).json({
        message: "obtained_marks and entered_by are required",
      });
    }

    const mark = Number(obtained_marks);

    if (!Number.isFinite(mark) || mark < 0) {
      return res.status(400).json({
        message: "obtained_marks must be a valid non-negative number",
      });
    }

    const existing = await pool.query(
      `SELECT m.id, a.max_marks
       FROM marks m
       JOIN assessments a ON a.id = m.assessment_id
       WHERE m.id = $1`,
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({ message: "Mark record not found" });
    }

    if (mark > Number(existing.rows[0].max_marks)) {
      return res.status(400).json({
        message: `Marks cannot exceed ${existing.rows[0].max_marks}`,
      });
    }

    const result = await pool.query(
      `UPDATE marks
       SET obtained_marks = $1,
           entered_by = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [mark, entered_by, id]
    );

    return res.status(200).json({
      message: "Marks updated successfully",
      mark: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23503") {
      return res.status(400).json({
        message: "Invalid user ID for entered_by",
      });
    }

    console.error("Update mark error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get all students and marks for an assessment
export const getMarksByAssessment = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT
          e.id AS enrollment_id,
          s.id AS student_id,
          s.student_no,
          u.full_name AS student_name,
          m.id AS mark_id,
          m.obtained_marks,
          a.id AS assessment_id,
          a.name AS assessment_name,
          a.max_marks,
          a.weight_percent,
          c.code AS course_code,
          c.title AS course_title
       FROM assessments a
       JOIN course_offerings co
         ON co.id = a.course_offering_id
       JOIN enrollments e
         ON e.course_offering_id = co.id
       JOIN students s
         ON s.id = e.student_id
       JOIN users u
         ON u.id = s.user_id
       JOIN courses c
         ON c.id = co.course_id
       LEFT JOIN marks m
         ON m.enrollment_id = e.id
         AND m.assessment_id = a.id
       WHERE a.id = $1
         AND e.status IN ('enrolled', 'completed')
       ORDER BY s.student_no`,
      [id]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get assessment marks error:", error);

    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

// Save multiple marks for an assessment
export const saveAssessmentMarks = async (req, res) => {
  const client = await pool.connect();

  try {
    const { id } = req.params;
    const { marks } = req.body;

    if (!Array.isArray(marks)) {
      return res.status(400).json({
        message: "Marks must be provided as an array",
      });
    }

    await client.query("BEGIN");

    // Find assessment
    const assessmentResult = await client.query(
      `SELECT id, course_offering_id, max_marks, is_active
       FROM assessments
       WHERE id = $1`,
      [id]
    );

    if (assessmentResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        message: "Assessment not found",
      });
    }

    const assessment = assessmentResult.rows[0];

    if (!assessment.is_active) {
      await client.query("ROLLBACK");

      return res.status(400).json({
        message: "This assessment is inactive",
      });
    }

    const maxMarks = Number(assessment.max_marks);

    for (const item of marks) {
      const enrollmentId = item.enrollment_id;
      const obtainedMarks = item.obtained_marks;

      // Validate enrollment
      const enrollmentResult = await client.query(
        `SELECT id
         FROM enrollments
         WHERE id = $1
           AND course_offering_id = $2
           AND status IN ('enrolled', 'completed')`,
        [enrollmentId, assessment.course_offering_id]
      );

      if (enrollmentResult.rows.length === 0) {
        throw new Error(
          `Invalid enrollment ID: ${enrollmentId}`
        );
      }

      // Null or empty means remove an existing mark
      if (obtainedMarks === null || obtainedMarks === "") {
        await client.query(
          `DELETE FROM marks
           WHERE enrollment_id = $1
             AND assessment_id = $2`,
          [enrollmentId, id]
        );

        continue;
      }

      const value = Number(obtainedMarks);

      if (!Number.isFinite(value) || value < 0 || value > maxMarks) {
        throw new Error(
          `Marks must be between 0 and ${maxMarks}`
        );
      }

      // Insert or update mark
      await client.query(
        `INSERT INTO marks
          (enrollment_id, assessment_id, obtained_marks, entered_by)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (enrollment_id, assessment_id)
         DO UPDATE SET
           obtained_marks = EXCLUDED.obtained_marks,
           entered_by = EXCLUDED.entered_by,
           updated_at = CURRENT_TIMESTAMP`,
        [
          enrollmentId,
          id,
          value,
          req.user.id,
        ]
      );
    }

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Marks saved successfully",
      total: marks.length,
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Save assessment marks error:", error);

    return res.status(400).json({
      message: error.message || "Failed to save marks",
    });
  } finally {
    client.release();
  }
};