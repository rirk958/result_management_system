
import pool from "../config/db.js";

// Create a student profile
export const createStudent = async (req, res) => {
  try {
    const {
      user_id,
      student_no,
      program_id,
      session_id,
      admission_date,
    } = req.body;

    if (
      !user_id ||
      !student_no?.trim() ||
      !program_id ||
      !session_id ||
      !admission_date
    ) {
      return res.status(400).json({
        message:
          "User ID, student number, program ID, session ID and admission date are required",
      });
    }

    const positiveInteger = (value) =>
      Number.isInteger(Number(value)) && Number(value) > 0;

    if (
      !positiveInteger(user_id) ||
      !positiveInteger(program_id) ||
      !positiveInteger(session_id)
    ) {
      return res.status(400).json({
        message: "User, program and session IDs must be positive integers",
      });
    }

    // Check the linked account
    const userResult = await pool.query(
      `SELECT id, role
       FROM users
       WHERE id = $1 AND is_active = TRUE`,
      [user_id]
    );

    if (userResult.rowCount === 0) {
      return res.status(404).json({
        message: "Active user account not found",
      });
    }

    if (userResult.rows[0].role !== "student") {
      return res.status(400).json({
        message: "The linked user account must have the student role",
      });
    }

    // Check the program
    const programResult = await pool.query(
      `SELECT id
       FROM programs
       WHERE id = $1 AND is_active = TRUE`,
      [program_id]
    );

    if (programResult.rowCount === 0) {
      return res.status(404).json({
        message: "Active program not found",
      });
    }

    // Check the academic session
    const sessionResult = await pool.query(
      `SELECT id
       FROM academic_sessions
       WHERE id = $1 AND is_active = TRUE`,
      [session_id]
    );

    if (sessionResult.rowCount === 0) {
      return res.status(404).json({
        message: "Active academic session not found",
      });
    }

    const result = await pool.query(
      `INSERT INTO students
         (user_id, student_no, program_id, session_id, admission_date)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        user_id,
        student_no.trim(),
        program_id,
        session_id,
        admission_date,
      ]
    );

    return res.status(201).json({
      message: "Student profile created successfully",
      student: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "This user or student number may already have a student profile",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "A referenced user, program or session does not exist",
      });
    }

    if (error.code === "23514" || error.code === "22007") {
      return res.status(400).json({
        message: "Invalid student status or admission date",
      });
    }

    console.error("Create student error:", error);
    return res.status(500).json({
      message: "Failed to create student profile",
    });
  }
};

// Get all student profiles
export const getStudents = async (req, res) => {
  try {
    const { program_id, session_id, status } = req.query;

    if (
      program_id !== undefined &&
      !/^[1-9]\d*$/.test(program_id)
    ) {
      return res.status(400).json({
        message: "Invalid program ID",
      });
    }

    if (
      session_id !== undefined &&
      !/^[1-9]\d*$/.test(session_id)
    ) {
      return res.status(400).json({
        message: "Invalid session ID",
      });
    }

    const result = await pool.query(
      `SELECT
         s.id,
         s.user_id,
         u.full_name,
         u.email,
         s.student_no,
         s.program_id,
         p.name AS program_name,
         p.code AS program_code,
         s.session_id,
         ac.name AS session_name,
         s.admission_date,
         s.status,
         s.created_at
       FROM students s
       JOIN users u ON u.id = s.user_id
       JOIN programs p ON p.id = s.program_id
       JOIN academic_sessions ac ON ac.id = s.session_id
       WHERE ($1::integer IS NULL OR s.program_id = $1)
         AND ($2::integer IS NULL OR s.session_id = $2)
         AND ($3::text IS NULL OR s.status::text = $3)
       ORDER BY s.id DESC`,
      [program_id || null, session_id || null, status || null]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get students error:", error);
    return res.status(500).json({
      message: "Failed to fetch students",
    });
  }
};

// Get one student profile
export const getStudentById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid student ID",
      });
    }

    const result = await pool.query(
      `SELECT
         s.*,
         u.full_name,
         u.email,
         p.name AS program_name,
         p.code AS program_code,
         ac.name AS session_name
       FROM students s
       JOIN users u ON u.id = s.user_id
       JOIN programs p ON p.id = s.program_id
       JOIN academic_sessions ac ON ac.id = s.session_id
       WHERE s.id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get student error:", error);
    return res.status(500).json({
      message: "Failed to fetch student",
    });
  }
};

// Update student academic information
export const updateStudent = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      student_no,
      program_id,
      session_id,
      admission_date,
    } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid student ID",
      });
    }

    const positiveInteger = (value) =>
      Number.isInteger(Number(value)) && Number(value) > 0;

    if (
      !student_no?.trim() ||
      !positiveInteger(program_id) ||
      !positiveInteger(session_id) ||
      !admission_date
    ) {
      return res.status(400).json({
        message:
          "Student number, program ID, session ID and admission date are required",
      });
    }

    const programResult = await pool.query(
      `SELECT id FROM programs
       WHERE id = $1 AND is_active = TRUE`,
      [program_id]
    );

    if (programResult.rowCount === 0) {
      return res.status(404).json({
        message: "Active program not found",
      });
    }

    const sessionResult = await pool.query(
      `SELECT id FROM academic_sessions
       WHERE id = $1 AND is_active = TRUE`,
      [session_id]
    );

    if (sessionResult.rowCount === 0) {
      return res.status(404).json({
        message: "Active academic session not found",
      });
    }

    const result = await pool.query(
      `UPDATE students
       SET student_no = $1,
           program_id = $2,
           session_id = $3,
           admission_date = $4
       WHERE id = $5
       RETURNING *`,
      [
        student_no.trim(),
        program_id,
        session_id,
        admission_date,
        id,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    return res.status(200).json({
      message: "Student profile updated successfully",
      student: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "That student number is already in use",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "A referenced program or session does not exist",
      });
    }

    console.error("Update student error:", error);
    return res.status(500).json({
      message: "Failed to update student profile",
    });
  }
};

// Update student status
export const updateStudentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid student ID",
      });
    }

    if (
      typeof status !== "string" ||
      !["active", "graduated", "suspended", "withdrawn"].includes(status)
    ) {
      return res.status(400).json({
        message:
          "Status must be active, graduated, suspended or withdrawn",
      });
    }

    const result = await pool.query(
      `UPDATE students
       SET status = $1
       WHERE id = $2
       RETURNING *`,
      [status, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    return res.status(200).json({
      message: "Student status updated successfully",
      student: result.rows[0],
    });
  } catch (error) {
    console.error("Update student status error:", error);
    return res.status(500).json({
      message: "Failed to update student status",
    });
  }
};
