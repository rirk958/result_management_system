import pool from "../config/db.js";

// Publish a semester result
export const publishSemesterResult = async (req, res) => {
  const client = await pool.connect();

  try {
    const { id } = req.params;
    const { published_by } = req.body;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid semester result ID" });
    }

    if (
      published_by == null ||
      !/^\d+$/.test(String(published_by)) ||
      Number(published_by) < 1
    ) {
      return res.status(400).json({
        message: "A valid published_by user ID is required",
      });
    }

    await client.query("BEGIN");

    // Check the publishing user is an active administrator.
    const admin = await client.query(
      `SELECT id
       FROM users
       WHERE id = $1
         AND role = 'admin'
         AND is_active = TRUE`,
      [published_by]
    );

    if (admin.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(403).json({
        message: "Only an active administrator can publish results",
      });
    }

    const existing = await client.query(
      `SELECT id, status, gpa, cgpa
       FROM semester_results
       WHERE id = $1
       FOR UPDATE`,
      [id]
    );

    if (existing.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        message: "Semester result not found",
      });
    }

    const result = existing.rows[0];

    if (result.status === "published") {
      await client.query("ROLLBACK");
      return res.status(409).json({
        message: "This semester result is already published",
      });
    }

    if (result.gpa == null || result.cgpa == null) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        message: "Calculate the semester result before publishing it",
      });
    }

    const updated = await client.query(
      `UPDATE semester_results
       SET status = 'published',
           published_by = $1,
           published_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [published_by, id]
    );

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Semester result published successfully",
      result: updated.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");

    if (error.code === "23503") {
      return res.status(400).json({
        message: "Invalid user ID or referenced record",
      });
    }

    console.error("Publish semester result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Return a published result to draft status
export const unpublishSemesterResult = async (req, res) => {
  const client = await pool.connect();

  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid semester result ID" });
    }

    await client.query("BEGIN");

    const existing = await client.query(
      `SELECT id, status
       FROM semester_results
       WHERE id = $1
       FOR UPDATE`,
      [id]
    );

    if (existing.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        message: "Semester result not found",
      });
    }

    if (existing.rows[0].status !== "published") {
      await client.query("ROLLBACK");
      return res.status(409).json({
        message: "Only published results can be returned to draft",
      });
    }

    const updated = await client.query(
      `UPDATE semester_results
       SET status = 'draft',
           published_by = NULL,
           published_at = NULL
       WHERE id = $1
       RETURNING *`,
      [id]
    );

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Semester result returned to draft",
      result: updated.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");

    console.error("Unpublish semester result error:", error);
    return res.status(500).json({ message: "Internal server error" });
  } finally {
    client.release();
  }
};

// Students can retrieve only their own published results
export const getPublishedResultsForStudent = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT
         sr.id,
         sr.student_id,
         sr.semester_id,
         sr.session_id,
         sr.gpa,
         sr.cgpa,
         sr.published_at,
         s.student_no,
         u.full_name AS student_name,
         sem.name AS semester_name,
         acs.name AS session_name
       FROM students s
       JOIN users u ON u.id = s.user_id
       JOIN semester_results sr ON sr.student_id = s.id
       JOIN semesters sem ON sem.id = sr.semester_id
       JOIN academic_sessions acs ON acs.id = sr.session_id
       WHERE s.user_id = $1
         AND sr.status = 'published'
       ORDER BY acs.start_date DESC, sem.semester_number`,
      [userId]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get published results error:", error);
    return res.status(500).json({
      message: "Internal server error"
    });
  }
};