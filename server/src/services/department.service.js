
import pool from "../config/db.js";

// CREATE DEPARTMENT
export const createDepartment = async (req, res) => {
  try {
    const { code, name } = req.body;

    if (!code?.trim() || !name?.trim()) {
      return res.status(400).json({
        message: "Department code and name are required",
      });
    }

    const result = await pool.query(
      `INSERT INTO departments (code, name)
       VALUES ($1, $2)
       RETURNING *`,
      [code.trim().toUpperCase(), name.trim()]
    );

    return res.status(201).json({
      message: "Department created successfully",
      department: result.rows[0],
    });
  } catch (error) {
    console.error("Create department error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "Department code already exists",
      });
    }

    return res.status(500).json({
      message: "Failed to create department",
    });
  }
};


// GET ALL DEPARTMENTS
export const getDepartments = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT *
       FROM departments
       ORDER BY name ASC`
    );

    return res.status(200).json({
      count: result.rows.length,
      departments: result.rows,
    });
  } catch (error) {
    console.error("Get departments error:", error);

    return res.status(500).json({
      message: "Failed to retrieve departments",
    });
  }
};


// GET DEPARTMENT BY ID
export const getDepartmentById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid department ID",
      });
    }

    const result = await pool.query(
      `SELECT *
       FROM departments
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Department not found",
      });
    }

    return res.status(200).json({
      department: result.rows[0],
    });
  } catch (error) {
    console.error("Get department error:", error);

    return res.status(500).json({
      message: "Failed to retrieve department",
    });
  }
};


// UPDATE DEPARTMENT
export const updateDepartment = async (req, res) => {
  try {
    const { id } = req.params;
    const { code, name } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid department ID",
      });
    }

    if (!code?.trim() || !name?.trim()) {
      return res.status(400).json({
        message: "Department code and name are required",
      });
    }

    const result = await pool.query(
      `UPDATE departments
       SET code = $1,
           name = $2
       WHERE id = $3
       RETURNING *`,
      [code.trim().toUpperCase(), name.trim(), id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Department not found",
      });
    }

    return res.status(200).json({
      message: "Department updated successfully",
      department: result.rows[0],
    });
  } catch (error) {
    console.error("Update department error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "Department code already exists",
      });
    }

    return res.status(500).json({
      message: "Failed to update department",
    });
  }
};


// ACTIVATE OR DEACTIVATE DEPARTMENT
export const updateDepartmentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid department ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE departments
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [is_active, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Department not found",
      });
    }

    return res.status(200).json({
      message: "Department status updated successfully",
      department: result.rows[0],
    });
  } catch (error) {
    console.error("Update department status error:", error);

    return res.status(500).json({
      message: "Failed to update department status",
    });
  }
};
