
import pool from "../config/db.js";

// Validate grading scale fields
function validateScale(program_id, grade_letter, min_percent, max_percent, grade_point) {
  if (
    program_id == null ||
    typeof grade_letter !== "string" ||
    !grade_letter.trim() ||
    min_percent == null ||
    max_percent == null ||
    grade_point == null
  ) {
    return "program_id, grade_letter, min_percent, max_percent, and grade_point are required";
  }

  const min = Number(min_percent);
  const max = Number(max_percent);
  const point = Number(grade_point);

  if (
    !Number.isFinite(min) ||
    !Number.isFinite(max) ||
    min < 0 ||
    max > 100 ||
    min > max
  ) {
    return "Percentage range must be between 0 and 100, with min_percent <= max_percent";
  }

  if (!Number.isFinite(point) || point < 0) {
    return "grade_point must be a valid non-negative number";
  }

  return null;
}

// Create a grading scale
export const createGradingScale = async (req, res) => {
  try {
    const {
      program_id,
      grade_letter,
      min_percent,
      max_percent,
      grade_point,
    } = req.body;

    const validationError = validateScale(
      program_id,
      grade_letter,
      min_percent,
      max_percent,
      grade_point
    );

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const program = await pool.query(
      "SELECT id FROM programs WHERE id = $1 AND is_active = TRUE",
      [program_id]
    );

    if (program.rows.length === 0) {
      return res.status(400).json({
        message: "Program not found or inactive",
      });
    }

    // Prevent overlapping percentage ranges within the same program.
    const overlap = await pool.query(
      `SELECT id
       FROM grading_scales
       WHERE program_id = $1
         AND min_percent <= $2
         AND max_percent >= $3`,
      [program_id, Number(max_percent), Number(min_percent)]
    );

    if (overlap.rows.length > 0) {
      return res.status(409).json({
        message: "This percentage range overlaps an existing grading scale",
      });
    }

    const result = await pool.query(
      `INSERT INTO grading_scales
         (program_id, grade_letter, min_percent, max_percent, grade_point)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        program_id,
        grade_letter.trim(),
        Number(min_percent),
        Number(max_percent),
        Number(grade_point),
      ]
    );

    return res.status(201).json({
      message: "Grading scale created successfully",
      grading_scale: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "A grading scale with these unique values already exists",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({ message: "Invalid program ID" });
    }

    console.error("Create grading scale error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get all grading scales; optionally filter by program
export const getGradingScales = async (req, res) => {
  try {
    const { program_id } = req.query;

    const result = await pool.query(
      `SELECT
         gs.*,
         p.code AS program_code,
         p.name AS program_name
       FROM grading_scales gs
       JOIN programs p ON p.id = gs.program_id
       WHERE ($1::bigint IS NULL OR gs.program_id = $1)
       ORDER BY gs.program_id, gs.min_percent DESC`,
      [program_id || null]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get grading scales error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get one grading scale
export const getGradingScaleById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid grading scale ID" });
    }

    const result = await pool.query(
      `SELECT
         gs.*,
         p.code AS program_code,
         p.name AS program_name
       FROM grading_scales gs
       JOIN programs p ON p.id = gs.program_id
       WHERE gs.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Grading scale not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get grading scale error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Update a grading scale
export const updateGradingScale = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      program_id,
      grade_letter,
      min_percent,
      max_percent,
      grade_point,
    } = req.body;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid grading scale ID" });
    }

    const validationError = validateScale(
      program_id,
      grade_letter,
      min_percent,
      max_percent,
      grade_point
    );

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const existing = await pool.query(
      "SELECT id FROM grading_scales WHERE id = $1",
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        message: "Grading scale not found",
      });
    }

    const program = await pool.query(
      "SELECT id FROM programs WHERE id = $1 AND is_active = TRUE",
      [program_id]
    );

    if (program.rows.length === 0) {
      return res.status(400).json({
        message: "Program not found or inactive",
      });
    }

    const overlap = await pool.query(
      `SELECT id
       FROM grading_scales
       WHERE program_id = $1
         AND id <> $2
         AND min_percent <= $3
         AND max_percent >= $4`,
      [program_id, id, Number(max_percent), Number(min_percent)]
    );

    if (overlap.rows.length > 0) {
      return res.status(409).json({
        message: "This percentage range overlaps another grading scale",
      });
    }

    const result = await pool.query(
      `UPDATE grading_scales
       SET program_id = $1,
           grade_letter = $2,
           min_percent = $3,
           max_percent = $4,
           grade_point = $5
       WHERE id = $6
       RETURNING *`,
      [
        program_id,
        grade_letter.trim(),
        Number(min_percent),
        Number(max_percent),
        Number(grade_point),
        id,
      ]
    );

    return res.status(200).json({
      message: "Grading scale updated successfully",
      grading_scale: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "A grading scale with these unique values already exists",
      });
    }

    console.error("Update grading scale error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Delete a grading scale
export const deleteGradingScale = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid grading scale ID" });
    }

    const result = await pool.query(
      "DELETE FROM grading_scales WHERE id = $1 RETURNING *",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Grading scale not found",
      });
    }

    return res.status(200).json({
      message: "Grading scale deleted successfully",
      grading_scale: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23503") {
      return res.status(409).json({
        message: "Cannot delete this grading scale because another record references it",
      });
    }

    console.error("Delete grading scale error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
