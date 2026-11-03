import pool from "../config/db.js";

const allowedStatuses = ["active", "inactive"];

// CREATE ASSESSMENT
export const createAssessment = async (req, res) => {
  try {
    const {
      course_offering_id,
      name,
      max_marks,
      weight_percent,
      display_order = 1,
    } = req.body;

    if (
      !course_offering_id ||
      !Number.isInteger(Number(course_offering_id)) ||
      Number(course_offering_id) <= 0 ||
      typeof name !== "string" ||
      !name.trim() ||
      max_marks === undefined ||
      weight_percent === undefined
    ) {
      return res.status(400).json({
        message:
          "course_offering_id, name, max_marks, and weight_percent are required",
      });
    }

    const maxMarks = Number(max_marks);
    const weight = Number(weight_percent);
    const order = Number(display_order);

    if (!Number.isFinite(maxMarks) || maxMarks <= 0) {
      return res.status(400).json({
        message: "max_marks must be greater than 0",
      });
    }

    if (!Number.isFinite(weight) || weight < 0 || weight > 100) {
      return res.status(400).json({
        message: "weight_percent must be between 0 and 100",
      });
    }

    if (!Number.isInteger(order) || order < 1) {
      return res.status(400).json({
        message: "display_order must be a positive integer",
      });
    }

    const offering = await pool.query(
      `SELECT id
       FROM course_offerings
       WHERE id = $1 AND status = 'active'`,
      [Number(course_offering_id)]
    );

    if (offering.rowCount === 0) {
      return res.status(400).json({
        message: "Active course offering not found",
      });
    }

    // Keep the total assessment weight at or below 100%.
    const existingWeights = await pool.query(
      `SELECT COALESCE(SUM(weight_percent), 0) AS total_weight
       FROM assessments
       WHERE course_offering_id = $1 AND is_active = TRUE`,
      [Number(course_offering_id)]
    );

    const totalWeight = Number(existingWeights.rows[0].total_weight);

    if (totalWeight + weight > 100) {
      return res.status(400).json({
        message: `Total assessment weight cannot exceed 100%. Current total: ${totalWeight}%`,
      });
    }

    const result = await pool.query(
      `INSERT INTO assessments
       (course_offering_id, name, max_marks, weight_percent, display_order)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        Number(course_offering_id),
        name.trim(),
        maxMarks,
        weight,
        order,
      ]
    );

    return res.status(201).json({
      message: "Assessment created successfully",
      assessment: result.rows[0],
    });
  } catch (error) {
    console.error("Create assessment error:", error);
    return res.status(500).json({
      message: "Failed to create assessment",
    });
  }
};

// GET ALL ASSESSMENTS
export const getAssessments = async (req, res) => {
  try {
    const { course_offering_id, is_active } = req.query;

    const conditions = [];
    const values = [];

    if (course_offering_id !== undefined) {
      const offeringId = Number(course_offering_id);

      if (!Number.isInteger(offeringId) || offeringId <= 0) {
        return res.status(400).json({
          message: "Invalid course_offering_id",
        });
      }

      values.push(offeringId);
      conditions.push(`a.course_offering_id = $${values.length}`);
    }

    if (is_active !== undefined) {
      if (!["true", "false"].includes(is_active)) {
        return res.status(400).json({
          message: "is_active must be true or false",
        });
      }

      values.push(is_active === "true");
      conditions.push(`a.is_active = $${values.length}`);
    }

    const whereClause = conditions.length
      ? `WHERE ${conditions.join(" AND ")}`
      : "";

    const result = await pool.query(
      `SELECT
         a.*,
         c.code AS course_code,
         c.title AS course_title,
         co.section_name
       FROM assessments a
       JOIN course_offerings co ON co.id = a.course_offering_id
       JOIN courses c ON c.id = co.course_id
       ${whereClause}
       ORDER BY a.course_offering_id, a.display_order, a.id`,
      values
    );

    return res.json(result.rows);
  } catch (error) {
    console.error("Get assessments error:", error);
    return res.status(500).json({
      message: "Failed to fetch assessments",
    });
  }
};

// GET ONE ASSESSMENT
export const getAssessmentById = async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: "Invalid assessment ID" });
    }

    const result = await pool.query(
      `SELECT
         a.*,
         c.code AS course_code,
         c.title AS course_title,
         co.section_name
       FROM assessments a
       JOIN course_offerings co ON co.id = a.course_offering_id
       JOIN courses c ON c.id = co.course_id
       WHERE a.id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Assessment not found" });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error("Get assessment error:", error);
    return res.status(500).json({
      message: "Failed to fetch assessment",
    });
  }
};

// UPDATE ASSESSMENT
export const updateAssessment = async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: "Invalid assessment ID" });
    }

    const {
      course_offering_id,
      name,
      max_marks,
      weight_percent,
      display_order,
    } = req.body;

    if (
      !course_offering_id ||
      !Number.isInteger(Number(course_offering_id)) ||
      Number(course_offering_id) <= 0 ||
      typeof name !== "string" ||
      !name.trim() ||
      max_marks === undefined ||
      weight_percent === undefined ||
      display_order === undefined
    ) {
      return res.status(400).json({
        message:
          "course_offering_id, name, max_marks, weight_percent, and display_order are required",
      });
    }

    const maxMarks = Number(max_marks);
    const weight = Number(weight_percent);
    const order = Number(display_order);
    const offeringId = Number(course_offering_id);

    if (!Number.isFinite(maxMarks) || maxMarks <= 0) {
      return res.status(400).json({
        message: "max_marks must be greater than 0",
      });
    }

    if (!Number.isFinite(weight) || weight < 0 || weight > 100) {
      return res.status(400).json({
        message: "weight_percent must be between 0 and 100",
      });
    }

    if (!Number.isInteger(order) || order < 1) {
      return res.status(400).json({
        message: "display_order must be a positive integer",
      });
    }

    const current = await pool.query(
      `SELECT id, course_offering_id
       FROM assessments
       WHERE id = $1`,
      [id]
    );

    if (current.rowCount === 0) {
      return res.status(404).json({ message: "Assessment not found" });
    }

    const offering = await pool.query(
      `SELECT id
       FROM course_offerings
       WHERE id = $1 AND status = 'active'`,
      [offeringId]
    );

    if (offering.rowCount === 0) {
      return res.status(400).json({
        message: "Active course offering not found",
      });
    }

    const existingWeights = await pool.query(
      `SELECT COALESCE(SUM(weight_percent), 0) AS total_weight
       FROM assessments
       WHERE course_offering_id = $1
         AND is_active = TRUE
         AND id <> $2`,
      [offeringId, id]
    );

    const totalWeight = Number(existingWeights.rows[0].total_weight);

    const currentAssessment = await pool.query(
      `SELECT is_active FROM assessments WHERE id = $1`,
      [id]
    );

    if (
      currentAssessment.rows[0].is_active &&
      totalWeight + weight > 100
    ) {
      return res.status(400).json({
        message: `Total assessment weight cannot exceed 100%. Other assessments total: ${totalWeight}%`,
      });
    }

    const result = await pool.query(
      `UPDATE assessments
       SET course_offering_id = $1,
           name = $2,
           max_marks = $3,
           weight_percent = $4,
           display_order = $5
       WHERE id = $6
       RETURNING *`,
      [offeringId, name.trim(), maxMarks, weight, order, id]
    );

    return res.json({
      message: "Assessment updated successfully",
      assessment: result.rows[0],
    });
  } catch (error) {
    console.error("Update assessment error:", error);
    return res.status(500).json({
      message: "Failed to update assessment",
    });
  }
};

// ACTIVATE / DEACTIVATE ASSESSMENT
export const updateAssessmentStatus = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: "Invalid assessment ID" });
    }

    if (!["active", "inactive"].includes(status)) {
      return res.status(400).json({
        message: "status must be active or inactive",
      });
    }

    const result = await pool.query(
      `UPDATE assessments
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [status === "active", id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Assessment not found" });
    }

    return res.json({
      message: `Assessment ${status} successfully`,
      assessment: result.rows[0],
    });
  } catch (error) {
    console.error("Update assessment status error:", error);
    return res.status(500).json({
      message: "Failed to update assessment status",
    });
  }
};