
import pool from "../config/db.js";

// CREATE TEACHER
export const createTeacher = async (req, res) => {
  try {
    const { user_id, department_id, employee_no } = req.body;

    if (!user_id || !department_id || !employee_no) {
      return res.status(400).json({
        message: "user_id, department_id and employee_no are required",
      });
    }

    if (
      !Number.isInteger(Number(user_id)) ||
      Number(user_id) <= 0 ||
      !Number.isInteger(Number(department_id)) ||
      Number(department_id) <= 0
    ) {
      return res.status(400).json({
        message: "user_id and department_id must be positive integers",
      });
    }

    // Check that the user exists, is active, and has the teacher role
    const userResult = await pool.query(
      `SELECT id
       FROM users
       WHERE id = $1
         AND role = 'teacher'
         AND is_active = TRUE`,
      [user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({
        message: "Active teacher user account not found",
      });
    }

    // Check that the department exists and is active
    const departmentResult = await pool.query(
      `SELECT id
       FROM departments
       WHERE id = $1 AND is_active = TRUE`,
      [department_id]
    );

    if (departmentResult.rows.length === 0) {
      return res.status(400).json({
        message: "Active department not found",
      });
    }

    const result = await pool.query(
      `INSERT INTO teachers (user_id, department_id, employee_no)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [user_id, department_id, employee_no.trim()]
    );

    return res.status(201).json({
      message: "Teacher created successfully",
      teacher: result.rows[0],
    });
  } catch (error) {
    console.error("Create teacher error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "This user or employee number is already registered",
      });
    }

    return res.status(500).json({
      message: "Failed to create teacher",
    });
  }
};


// GET ALL TEACHERS
export const getTeachers = async (req, res) => {
  try {
    const { department_id } = req.query;

    let query = `
      SELECT
        t.id,
        t.user_id,
        u.full_name,
        u.email,
        t.department_id,
        d.name AS department_name,
        d.code AS department_code,
        t.employee_no,
        t.is_active
      FROM teachers t
      JOIN users u ON t.user_id = u.id
      JOIN departments d ON t.department_id = d.id
    `;

    const values = [];

    if (department_id) {
      query += ` WHERE t.department_id = $1`;
      values.push(department_id);
    }

    query += ` ORDER BY t.id ASC`;

    const result = await pool.query(query, values);

    return res.status(200).json({
      count: result.rows.length,
      teachers: result.rows,
    });
  } catch (error) {
    console.error("Get teachers error:", error);

    return res.status(500).json({
      message: "Failed to retrieve teachers",
    });
  }
};


// GET TEACHER BY ID
export const getTeacherById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid teacher ID",
      });
    }

    const result = await pool.query(
      `SELECT
         t.id,
         t.user_id,
         u.full_name,
         u.email,
         t.department_id,
         d.name AS department_name,
         d.code AS department_code,
         t.employee_no,
         t.is_active
       FROM teachers t
       JOIN users u ON t.user_id = u.id
       JOIN departments d ON t.department_id = d.id
       WHERE t.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Teacher not found",
      });
    }

    return res.status(200).json({
      teacher: result.rows[0],
    });
  } catch (error) {
    console.error("Get teacher error:", error);

    return res.status(500).json({
      message: "Failed to retrieve teacher",
    });
  }
};


// UPDATE TEACHER
export const updateTeacher = async (req, res) => {
  try {
    const { id } = req.params;
    const { department_id, employee_no } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid teacher ID",
      });
    }

    if (!department_id || !employee_no) {
      return res.status(400).json({
        message: "department_id and employee_no are required",
      });
    }

    if (
      !Number.isInteger(Number(department_id)) ||
      Number(department_id) <= 0
    ) {
      return res.status(400).json({
        message: "department_id must be a positive integer",
      });
    }

    const teacherResult = await pool.query(
      `SELECT id FROM teachers WHERE id = $1`,
      [id]
    );

    if (teacherResult.rows.length === 0) {
      return res.status(404).json({
        message: "Teacher not found",
      });
    }

    const departmentResult = await pool.query(
      `SELECT id FROM departments WHERE id = $1 AND is_active = TRUE`,
      [department_id]
    );

    if (departmentResult.rows.length === 0) {
      return res.status(400).json({
        message: "Active department not found",
      });
    }

    const result = await pool.query(
      `UPDATE teachers
       SET department_id = $1,
           employee_no = $2
       WHERE id = $3
       RETURNING *`,
      [department_id, employee_no.trim(), id]
    );

    return res.status(200).json({
      message: "Teacher updated successfully",
      teacher: result.rows[0],
    });
  } catch (error) {
    console.error("Update teacher error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "This employee number is already registered",
      });
    }

    return res.status(500).json({
      message: "Failed to update teacher",
    });
  }
};


// ACTIVATE OR DEACTIVATE TEACHER
export const updateTeacherStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid teacher ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE teachers
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [is_active, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Teacher not found",
      });
    }

    return res.status(200).json({
      message: "Teacher status updated successfully",
      teacher: result.rows[0],
    });
  } catch (error) {
    console.error("Update teacher status error:", error);

    return res.status(500).json({
      message: "Failed to update teacher status",
    });
  }
};
