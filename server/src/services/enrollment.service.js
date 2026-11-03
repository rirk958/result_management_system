
import pool from "../config/db.js";

// CREATE ENROLLMENT
export const createEnrollment = async (req, res) => {
  try {
    const { student_id, course_offering_id, status = "enrolled" } = req.body;

    if (!student_id || !course_offering_id) {
      return res.status(400).json({
        message: "student_id and course_offering_id are required",
      });
    }

    const allowedStatuses = ["enrolled", "completed", "withdrawn"];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: "Invalid enrollment status",
      });
    }

    // Check student
    const studentResult = await pool.query(
      `SELECT id, status
       FROM students
       WHERE id = $1`,
      [student_id]
    );

    if (studentResult.rows.length === 0) {
      return res.status(404).json({
        message: "Student not found",
      });
    }

    if (studentResult.rows[0].status !== "active") {
      return res.status(400).json({
        message: "Student is not active",
      });
    }

    // Check course offering
    const offeringResult = await pool.query(
      `SELECT id, status
       FROM course_offerings
       WHERE id = $1`,
      [course_offering_id]
    );

    if (offeringResult.rows.length === 0) {
      return res.status(404).json({
        message: "Course offering not found",
      });
    }

    if (offeringResult.rows[0].status !== "active") {
      return res.status(400).json({
        message: "Course offering is not active",
      });
    }

    // Create enrollment
    const result = await pool.query(
      `INSERT INTO enrollments
        (student_id, course_offering_id, status)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [student_id, course_offering_id, status]
    );

    return res.status(201).json({
      message: "Student enrolled successfully",
      enrollment: result.rows[0],
    });

  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "Student is already enrolled in this course",
      });
    }

    console.error("Create enrollment error:", error);

    return res.status(500).json({
      message: "Failed to create enrollment",
    });
  }
};


// GET ALL ENROLLMENTS
export const getEnrollments = async (req, res) => {
  try {
    const { student_id, course_offering_id, status } = req.query;

    let query = `
      SELECT
        e.id,
        e.student_id,
        s.student_no,
        u.full_name AS student_name,
        e.course_offering_id,
        c.code AS course_code,
        c.title AS course_title,
        co.section_name,
        e.status,
        e.enrolled_at
      FROM enrollments e
      JOIN students s ON e.student_id = s.id
      JOIN users u ON s.user_id = u.id
      JOIN course_offerings co ON e.course_offering_id = co.id
      JOIN courses c ON co.course_id = c.id
      WHERE 1 = 1
    `;

    const values = [];
    let index = 1;

    if (student_id) {
      query += ` AND e.student_id = $${index++}`;
      values.push(student_id);
    }

    if (course_offering_id) {
      query += ` AND e.course_offering_id = $${index++}`;
      values.push(course_offering_id);
    }

    if (status) {
      query += ` AND e.status = $${index++}`;
      values.push(status);
    }

    query += " ORDER BY e.id DESC";

    const result = await pool.query(query, values);

    return res.json({
      count: result.rows.length,
      enrollments: result.rows,
    });

  } catch (error) {
    console.error("Get enrollments error:", error);

    return res.status(500).json({
      message: "Failed to fetch enrollments",
    });
  }
};


// GET ENROLLMENT BY ID
export const getEnrollmentById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT
        e.id,
        e.student_id,
        s.student_no,
        u.full_name AS student_name,
        e.course_offering_id,
        c.code AS course_code,
        c.title AS course_title,
        co.section_name,
        e.status,
        e.enrolled_at
       FROM enrollments e
       JOIN students s ON e.student_id = s.id
       JOIN users u ON s.user_id = u.id
       JOIN course_offerings co ON e.course_offering_id = co.id
       JOIN courses c ON co.course_id = c.id
       WHERE e.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Enrollment not found",
      });
    }

    return res.json({
      enrollment: result.rows[0],
    });

  } catch (error) {
    console.error("Get enrollment error:", error);

    return res.status(500).json({
      message: "Failed to fetch enrollment",
    });
  }
};


// UPDATE ENROLLMENT STATUS
export const updateEnrollmentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const allowedStatuses = ["enrolled", "completed", "withdrawn"];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: "Invalid enrollment status",
        allowedStatuses,
      });
    }

    const result = await pool.query(
      `UPDATE enrollments
       SET status = $1
       WHERE id = $2
       RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Enrollment not found",
      });
    }

    return res.json({
      message: "Enrollment status updated successfully",
      enrollment: result.rows[0],
    });

  } catch (error) {
    console.error("Update enrollment error:", error);

    return res.status(500).json({
      message: "Failed to update enrollment status",
    });
  }
};
