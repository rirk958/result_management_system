
import pool from "../config/db.js";

// CREATE PROGRAM
export const createProgram = async (req, res) => {
  try {
    const {
      department_id,
      code,
      name,
      degree_name,
      total_semesters,
    } = req.body;

    if (!department_id || !code?.trim() || !name?.trim()) {
      return res.status(400).json({
        message: "Department, code and name are required",
      });
    }

    const semesters = Number(total_semesters ?? 8);

    if (!Number.isInteger(semesters) || semesters < 1) {
      return res.status(400).json({
        message: "Total semesters must be a positive integer",
      });
    }

    const result = await pool.query(
      `INSERT INTO programs
       (department_id, code, name, degree_name, total_semesters)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        department_id,
        code.trim(),
        name.trim(),
        degree_name?.trim() || "Bachelor",
        semesters,
      ]
    );

    return res.status(201).json({
      message: "Program created successfully",
      program: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "Program code or name already exists",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "The selected department does not exist",
      });
    }

    console.error(error);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

// GET ALL PROGRAMS
export const getPrograms = async (req, res) => {
  try {
    const { department_id } = req.query;

    let query = `
      SELECT
        p.*,
        d.name AS department_name,
        d.code AS department_code
      FROM programs p
      JOIN departments d ON d.id = p.department_id
      WHERE p.is_active = TRUE
    `;

    const values = [];

    if (department_id) {
      values.push(department_id);
      query += ` AND p.department_id = $${values.length}`;
    }

    query += " ORDER BY p.name";

    const result = await pool.query(query, values);

    return res.json(result.rows);
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

// GET ONE PROGRAM
export const getProgramById = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         p.*,
         d.name AS department_name,
         d.code AS department_code
       FROM programs p
       JOIN departments d ON d.id = p.department_id
       WHERE p.id = $1`,
      [req.params.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Program not found",
      });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

// UPDATE PROGRAM
export const updateProgram = async (req, res) => {
  try {
    const {
      department_id,
      code,
      name,
      degree_name,
      total_semesters,
    } = req.body;

    if (!department_id || !code?.trim() || !name?.trim()) {
      return res.status(400).json({
        message: "Department, code and name are required",
      });
    }

    const semesters = Number(total_semesters);

    if (!Number.isInteger(semesters) || semesters < 1) {
      return res.status(400).json({
        message: "Total semesters must be a positive integer",
      });
    }

    const result = await pool.query(
      `UPDATE programs
       SET department_id = $1,
           code = $2,
           name = $3,
           degree_name = $4,
           total_semesters = $5
       WHERE id = $6
       RETURNING *`,
      [
        department_id,
        code.trim(),
        name.trim(),
        degree_name?.trim() || "Bachelor",
        semesters,
        req.params.id,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Program not found",
      });
    }

    return res.json({
      message: "Program updated successfully",
      program: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "Program code or name already exists",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "The selected department does not exist",
      });
    }

    console.error(error);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

// DEACTIVATE PROGRAM
export const deactivateProgram = async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE programs
       SET is_active = FALSE
       WHERE id = $1
       RETURNING *`,
      [req.params.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Program not found",
      });
    }

    return res.json({
      message: "Program deactivated successfully",
      program: result.rows[0],
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};
