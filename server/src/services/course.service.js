
import pool from "../config/db.js";

// CREATE COURSE
export const createCourse = async (req, res) => {
  try {
    const { department_id, code, title, credit, description } = req.body;

    if (
      !department_id ||
      !code?.trim() ||
      !title?.trim() ||
      credit === undefined ||
      credit === null
    ) {
      return res.status(400).json({
        message: "department_id, code, title and credit are required",
      });
    }

    const departmentId = Number(department_id);
    const credits = Number(credit);

    if (!Number.isInteger(departmentId) || departmentId <= 0) {
      return res.status(400).json({
        message: "department_id must be a positive integer",
      });
    }

    if (!Number.isFinite(credits) || credits <= 0) {
      return res.status(400).json({
        message: "credit must be greater than zero",
      });
    }

    const department = await pool.query(
      `SELECT id FROM departments
       WHERE id = $1 AND is_active = TRUE`,
      [departmentId]
    );

    if (department.rows.length === 0) {
      return res.status(400).json({
        message: "Active department not found",
      });
    }

    const result = await pool.query(
      `INSERT INTO courses
         (department_id, code, title, credit, description)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        departmentId,
        code.trim().toUpperCase(),
        title.trim(),
        credits,
        description?.trim() || null,
      ]
    );

    return res.status(201).json({
      message: "Course created successfully",
      course: result.rows[0],
    });
  } catch (error) {
    console.error("Create course error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "This course code already exists",
      });
    }

    if (error.code === "23514") {
      return res.status(400).json({
        message: "One or more course values violate a database constraint",
      });
    }

    return res.status(500).json({
      message: "Failed to create course",
    });
  }
};


// GET ALL COURSES
export const getCourses = async (req, res) => {
  try {
    const { department_id, is_active } = req.query;

    const conditions = [];
    const values = [];

    if (department_id !== undefined) {
      const departmentId = Number(department_id);

      if (!Number.isInteger(departmentId) || departmentId <= 0) {
        return res.status(400).json({
          message: "Invalid department_id",
        });
      }

      values.push(departmentId);
      conditions.push(`c.department_id = $${values.length}`);
    }

    if (is_active !== undefined) {
      if (!["true", "false"].includes(is_active)) {
        return res.status(400).json({
          message: "is_active must be true or false",
        });
      }

      values.push(is_active === "true");
      conditions.push(`c.is_active = $${values.length}`);
    }

    let query = `
      SELECT
        c.*,
        d.name AS department_name,
        d.code AS department_code
      FROM courses c
      JOIN departments d ON d.id = c.department_id
    `;

    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(" AND ")}`;
    }

    query += ` ORDER BY c.code ASC`;

    const result = await pool.query(query, values);

    return res.status(200).json({
      count: result.rows.length,
      courses: result.rows,
    });
  } catch (error) {
    console.error("Get courses error:", error);

    return res.status(500).json({
      message: "Failed to retrieve courses",
    });
  }
};


// GET COURSE BY ID
export const getCourseById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course ID",
      });
    }

    const result = await pool.query(
      `SELECT
         c.*,
         d.name AS department_name,
         d.code AS department_code
       FROM courses c
       JOIN departments d ON d.id = c.department_id
       WHERE c.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    return res.status(200).json({
      course: result.rows[0],
    });
  } catch (error) {
    console.error("Get course error:", error);

    return res.status(500).json({
      message: "Failed to retrieve course",
    });
  }
};


// UPDATE COURSE
export const updateCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const { department_id, code, title, credit, description } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course ID",
      });
    }

    if (
      !department_id ||
      !code?.trim() ||
      !title?.trim() ||
      credit === undefined ||
      credit === null
    ) {
      return res.status(400).json({
        message: "department_id, code, title and credit are required",
      });
    }

    const departmentId = Number(department_id);
    const credits = Number(credit);

    if (!Number.isInteger(departmentId) || departmentId <= 0) {
      return res.status(400).json({
        message: "Invalid department_id",
      });
    }

    if (!Number.isFinite(credits) || credits <= 0) {
      return res.status(400).json({
        message: "credit must be greater than zero",
      });
    }

    const existing = await pool.query(
      `SELECT id FROM courses WHERE id = $1`,
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    const department = await pool.query(
      `SELECT id FROM departments
       WHERE id = $1 AND is_active = TRUE`,
      [departmentId]
    );

    if (department.rows.length === 0) {
      return res.status(400).json({
        message: "Active department not found",
      });
    }

    const result = await pool.query(
      `UPDATE courses
       SET department_id = $1,
           code = $2,
           title = $3,
           credit = $4,
           description = $5
       WHERE id = $6
       RETURNING *`,
      [
        departmentId,
        code.trim().toUpperCase(),
        title.trim(),
        credits,
        description?.trim() || null,
        id,
      ]
    );

    return res.status(200).json({
      message: "Course updated successfully",
      course: result.rows[0],
    });
  } catch (error) {
    console.error("Update course error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "This course code already exists",
      });
    }

    if (error.code === "23514") {
      return res.status(400).json({
        message: "One or more course values violate a database constraint",
      });
    }

    return res.status(500).json({
      message: "Failed to update course",
    });
  }
};


// ACTIVATE OR DEACTIVATE COURSE
export const updateCourseStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE courses
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [is_active, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    return res.status(200).json({
      message: "Course status updated successfully",
      course: result.rows[0],
    });
  } catch (error) {
    console.error("Update course status error:", error);

    return res.status(500).json({
      message: "Failed to update course status",
    });
  }
};
