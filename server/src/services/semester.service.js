
import pool from "../config/db.js";

// Create semester
export const createSemester = async (req, res) => {
  try {
    const { program_id, semester_number, name } = req.body;

    if (!program_id || !semester_number || !name?.trim()) {
      return res.status(400).json({
        message: "Program ID, semester number and name are required",
      });
    }

    if (
      !Number.isInteger(Number(program_id)) ||
      Number(program_id) < 1 ||
      !Number.isInteger(Number(semester_number)) ||
      Number(semester_number) < 1
    ) {
      return res.status(400).json({
        message: "Program ID and semester number must be positive integers",
      });
    }

    // Check whether the program exists and is active
    const program = await pool.query(
      `SELECT id, total_semesters
       FROM programs
       WHERE id = $1 AND is_active = TRUE`,
      [program_id]
    );

    if (program.rowCount === 0) {
      return res.status(404).json({
        message: "Active program not found",
      });
    }

    if (Number(semester_number) > program.rows[0].total_semesters) {
      return res.status(400).json({
        message: `This program has only ${program.rows[0].total_semesters} semesters`,
      });
    }

    const result = await pool.query(
      `INSERT INTO semesters (program_id, semester_number, name)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [program_id, semester_number, name.trim()]
    );

    return res.status(201).json({
      message: "Semester created successfully",
      semester: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "This semester number or name already exists for this program",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "The selected program does not exist",
      });
    }

    console.error("Create semester error:", error);
    return res.status(500).json({
      message: "Failed to create semester",
    });
  }
};

// Get all semesters, optionally filtered by program
export const getSemesters = async (req, res) => {
  try {
    const { program_id } = req.query;

    if (
      program_id !== undefined &&
      (!/^[1-9]\d*$/.test(program_id))
    ) {
      return res.status(400).json({
        message: "Invalid program ID",
      });
    }

    const result = await pool.query(
      `SELECT
         s.*,
         p.code AS program_code,
         p.name AS program_name
       FROM semesters s
       JOIN programs p ON p.id = s.program_id
       WHERE ($1::integer IS NULL OR s.program_id = $1)
       ORDER BY p.name, s.semester_number`,
      [program_id || null]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get semesters error:", error);
    return res.status(500).json({
      message: "Failed to fetch semesters",
    });
  }
};

// Get one semester
export const getSemesterById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid semester ID",
      });
    }

    const result = await pool.query(
      `SELECT
         s.*,
         p.code AS program_code,
         p.name AS program_name
       FROM semesters s
       JOIN programs p ON p.id = s.program_id
       WHERE s.id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Semester not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get semester error:", error);
    return res.status(500).json({
      message: "Failed to fetch semester",
    });
  }
};

// Update semester
export const updateSemester = async (req, res) => {
  try {
    const { id } = req.params;
    const { program_id, semester_number, name } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid semester ID",
      });
    }

    if (
      !program_id ||
      !Number.isInteger(Number(program_id)) ||
      Number(program_id) < 1 ||
      !Number.isInteger(Number(semester_number)) ||
      Number(semester_number) < 1 ||
      !name?.trim()
    ) {
      return res.status(400).json({
        message: "Valid program ID, semester number and name are required",
      });
    }

    const program = await pool.query(
      `SELECT id, total_semesters
       FROM programs
       WHERE id = $1 AND is_active = TRUE`,
      [program_id]
    );

    if (program.rowCount === 0) {
      return res.status(404).json({
        message: "Active program not found",
      });
    }

    if (Number(semester_number) > program.rows[0].total_semesters) {
      return res.status(400).json({
        message: `This program has only ${program.rows[0].total_semesters} semesters`,
      });
    }

    const result = await pool.query(
      `UPDATE semesters
       SET program_id = $1,
           semester_number = $2,
           name = $3
       WHERE id = $4
       RETURNING *`,
      [program_id, semester_number, name.trim(), id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Semester not found",
      });
    }

    return res.status(200).json({
      message: "Semester updated successfully",
      semester: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "This semester number or name already exists for this program",
      });
    }

    console.error("Update semester error:", error);
    return res.status(500).json({
      message: "Failed to update semester",
    });
  }
};

// Activate or deactivate semester
export const updateSemesterStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid semester ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE semesters
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [is_active, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Semester not found",
      });
    }

    return res.status(200).json({
      message: `Semester ${is_active ? "activated" : "deactivated"} successfully`,
      semester: result.rows[0],
    });
  } catch (error) {
    console.error("Update semester status error:", error);
    return res.status(500).json({
      message: "Failed to update semester status",
    });
  }
};
