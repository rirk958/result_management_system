
import pool from "../config/db.js";

const allowedStatuses = ["planned", "active", "completed", "cancelled"];


// CREATE COURSE OFFERING
export const createCourseOffering = async (req, res) => {
  try {
    const {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
      section_name,
      status = "planned",
    } = req.body;

    const ids = {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
    };

    for (const [field, value] of Object.entries(ids)) {
      if (
        value === undefined ||
        !Number.isInteger(Number(value)) ||
        Number(value) <= 0
      ) {
        return res.status(400).json({
          message: `${field} must be a positive integer`,
        });
      }
    }

    if (typeof section_name !== "string" || !section_name.trim()) {
      return res.status(400).json({
        message: "section_name is required",
      });
    }

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: `status must be one of: ${allowedStatuses.join(", ")}`,
      });
    }

    // Check that the course is active
    const course = await pool.query(
      `SELECT id, department_id
       FROM courses
       WHERE id = $1 AND is_active = TRUE`,
      [course_id]
    );

    if (course.rows.length === 0) {
      return res.status(400).json({
        message: "Active course not found",
      });
    }

    // Check that the program is active
    const program = await pool.query(
      `SELECT id
       FROM programs
       WHERE id = $1 AND is_active = TRUE`,
      [program_id]
    );

    if (program.rows.length === 0) {
      return res.status(400).json({
        message: "Active program not found",
      });
    }

    // Check that the academic session is active
    const session = await pool.query(
      `SELECT id
       FROM academic_sessions
       WHERE id = $1 AND is_active = TRUE`,
      [session_id]
    );

    if (session.rows.length === 0) {
      return res.status(400).json({
        message: "Active academic session not found",
      });
    }

    // The semester must belong to the selected program
    const semester = await pool.query(
      `SELECT id
       FROM semesters
       WHERE id = $1
         AND program_id = $2
         AND is_active = TRUE`,
      [semester_id, program_id]
    );

    if (semester.rows.length === 0) {
      return res.status(400).json({
        message: "Active semester not found for this program",
      });
    }

    // Check that the teacher is active
    const teacher = await pool.query(
      `SELECT id
       FROM teachers
       WHERE id = $1 AND is_active = TRUE`,
      [teacher_id]
    );

    if (teacher.rows.length === 0) {
      return res.status(400).json({
        message: "Active teacher not found",
      });
    }

    const result = await pool.query(
      `INSERT INTO course_offerings
         (course_id, program_id, session_id, semester_id,
          teacher_id, section_name, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        course_id,
        program_id,
        session_id,
        semester_id,
        teacher_id,
        section_name.trim(),
        status,
      ]
    );

    return res.status(201).json({
      message: "Course offering created successfully",
      offering: result.rows[0],
    });
  } catch (error) {
    console.error("Create course offering error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "A conflicting course offering already exists",
      });
    }

    if (error.code === "23503") {
      return res.status(400).json({
        message: "One or more referenced records do not exist",
      });
    }

    if (error.code === "23514") {
      return res.status(400).json({
        message: "A course offering value violates a database constraint",
      });
    }

    return res.status(500).json({
      message: "Failed to create course offering",
    });
  }
};


// GET ALL COURSE OFFERINGS
export const getCourseOfferings = async (req, res) => {
  try {
    const {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
      status,
    } = req.query;

    const filters = [];
    const values = [];

    const idFilters = {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
    };

    for (const [field, value] of Object.entries(idFilters)) {
      if (value !== undefined) {
        if (
          !Number.isInteger(Number(value)) ||
          Number(value) <= 0
        ) {
          return res.status(400).json({
            message: `Invalid ${field}`,
          });
        }

        values.push(Number(value));
        filters.push(`co.${field} = $${values.length}`);
      }
    }

    if (status !== undefined) {
      if (!allowedStatuses.includes(status)) {
        return res.status(400).json({
          message: "Invalid status",
        });
      }

      values.push(status);
      filters.push(`co.status = $${values.length}`);
    }

    let query = `
      SELECT
        co.*,
        c.code AS course_code,
        c.title AS course_title,
        c.credit,
        p.code AS program_code,
        p.name AS program_name,
        s.name AS session_name,
        sem.name AS semester_name,
        sem.semester_number,
        u.full_name AS teacher_name,
        t.employee_no
      FROM course_offerings co
      JOIN courses c ON c.id = co.course_id
      JOIN programs p ON p.id = co.program_id
      JOIN academic_sessions s ON s.id = co.session_id
      JOIN semesters sem ON sem.id = co.semester_id
      LEFT JOIN teachers t ON t.id = co.teacher_id
      LEFT JOIN users u ON u.id = t.user_id
    `;

    if (filters.length > 0) {
      query += ` WHERE ${filters.join(" AND ")}`;
    }

    query += ` ORDER BY co.id DESC`;

    const result = await pool.query(query, values);

    return res.status(200).json({
      count: result.rows.length,
      offerings: result.rows,
    });
  } catch (error) {
    console.error("Get course offerings error:", error);

    return res.status(500).json({
      message: "Failed to retrieve course offerings",
    });
  }
};



// GET COURSE OFFERING BY ID
export const getCourseOfferingById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course offering ID",
      });
    }

    const result = await pool.query(
      `SELECT
        co.*,
        c.code AS course_code,
        c.title AS course_title,
        c.credit,
        p.code AS program_code,
        p.name AS program_name,
        s.name AS session_name,
        sem.name AS semester_name,
        sem.semester_number,
        u.full_name AS teacher_name,
        u.email AS teacher_email,
        t.employee_no
       FROM course_offerings co
       JOIN courses c ON c.id = co.course_id
       JOIN programs p ON p.id = co.program_id
       JOIN academic_sessions s ON s.id = co.session_id
       JOIN semesters sem ON sem.id = co.semester_id
       JOIN teachers t ON t.id = co.teacher_id
       JOIN users u ON u.id = t.user_id
       WHERE co.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Course offering not found",
      });
    }

    return res.status(200).json({
      offering: result.rows[0],
    });
  } catch (error) {
    console.error("Get course offering error:", error);

    return res.status(500).json({
      message: "Failed to retrieve course offering",
    });
  }
};


// UPDATE COURSE OFFERING
export const updateCourseOffering = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
      section_name,
      status,
    } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course offering ID",
      });
    }

    const existing = await pool.query(
      `SELECT id FROM course_offerings WHERE id = $1`,
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        message: "Course offering not found",
      });
    }

    const ids = {
      course_id,
      program_id,
      session_id,
      semester_id,
      teacher_id,
    };

    for (const [field, value] of Object.entries(ids)) {
      if (
        value === undefined ||
        !Number.isInteger(Number(value)) ||
        Number(value) <= 0
      ) {
        return res.status(400).json({
          message: `${field} must be a positive integer`,
        });
      }
    }

    if (typeof section_name !== "string" || !section_name.trim()) {
      return res.status(400).json({
        message: "section_name is required",
      });
    }

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: `status must be one of: ${allowedStatuses.join(", ")}`,
      });
    }

    // Validate all related records and ensure the semester belongs to the program
    const checks = await pool.query(
      `SELECT
        EXISTS (
          SELECT 1 FROM courses
          WHERE id = $1 AND is_active = TRUE
        ) AS course_ok,
        EXISTS (
          SELECT 1 FROM programs
          WHERE id = $2 AND is_active = TRUE
        ) AS program_ok,
        EXISTS (
          SELECT 1 FROM academic_sessions
          WHERE id = $3 AND is_active = TRUE
        ) AS session_ok,
        EXISTS (
          SELECT 1 FROM semesters
          WHERE id = $4
            AND program_id = $2
            AND is_active = TRUE
        ) AS semester_ok,
        EXISTS (
          SELECT 1 FROM teachers
          WHERE id = $5 AND is_active = TRUE
        ) AS teacher_ok`,
      [course_id, program_id, session_id, semester_id, teacher_id]
    );

    const check = checks.rows[0];

    if (!check.course_ok) {
      return res.status(400).json({ message: "Active course not found" });
    }

    if (!check.program_ok) {
      return res.status(400).json({ message: "Active program not found" });
    }

    if (!check.session_ok) {
      return res.status(400).json({ message: "Active academic session not found" });
    }

    if (!check.semester_ok) {
      return res.status(400).json({
        message: "Active semester not found for this program",
      });
    }

    if (!check.teacher_ok) {
      return res.status(400).json({ message: "Active teacher not found" });
    }

    const result = await pool.query(
      `UPDATE course_offerings
       SET course_id = $1,
           program_id = $2,
           session_id = $3,
           semester_id = $4,
           teacher_id = $5,
           section_name = $6,
           status = $7
       WHERE id = $8
       RETURNING *`,
      [
        course_id,
        program_id,
        session_id,
        semester_id,
        teacher_id,
        section_name.trim(),
        status,
        id,
      ]
    );

    return res.status(200).json({
      message: "Course offering updated successfully",
      offering: result.rows[0],
    });
  } catch (error) {
    console.error("Update course offering error:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        message: "A conflicting course offering already exists",
      });
    }

    if (error.code === "23514") {
      return res.status(400).json({
        message: "A course offering value violates a database constraint",
      });
    }

    return res.status(500).json({
      message: "Failed to update course offering",
    });
  }
};


// UPDATE COURSE OFFERING STATUS
export const updateCourseOfferingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!Number.isInteger(Number(id)) || Number(id) <= 0) {
      return res.status(400).json({
        message: "Invalid course offering ID",
      });
    }

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: `status must be one of: ${allowedStatuses.join(", ")}`,
      });
    }

    const result = await pool.query(
      `UPDATE course_offerings
       SET status = $1
       WHERE id = $2
       RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Course offering not found",
      });
    }

    return res.status(200).json({
      message: "Course offering status updated successfully",
      offering: result.rows[0],
    });
  } catch (error) {
    console.error("Update course offering status error:", error);

    return res.status(500).json({
      message: "Failed to update course offering status",
    });
  }
};
