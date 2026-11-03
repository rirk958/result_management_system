import pool from "../config/db.js";

// Create academic session
export const createSession = async (req, res) => {
  try {
    const { name, start_date, end_date } = req.body;

    if (!name || !start_date || !end_date) {
      return res.status(400).json({
        message: "Name, start date and end date are required",
      });
    }

    if (end_date < start_date) {
      return res.status(400).json({
        message: "End date cannot be before start date",
      });
    }

    const result = await pool.query(
      `INSERT INTO academic_sessions (name, start_date, end_date)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [name.trim(), start_date, end_date]
    );

    return res.status(201).json({
      message: "Academic session created successfully",
      session: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "This academic session already exists",
      });
    }

    console.error("Create session error:", error);
    return res.status(500).json({
      message: "Failed to create academic session",
    });
  }
};

// Get all academic sessions
export const getSessions = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT *
       FROM academic_sessions
       ORDER BY start_date DESC, id DESC`
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get sessions error:", error);
    return res.status(500).json({
      message: "Failed to fetch academic sessions",
    });
  }
};

// Get one academic session
export const getSessionById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid session ID",
      });
    }

    const result = await pool.query(
      "SELECT * FROM academic_sessions WHERE id = $1",
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Academic session not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get session error:", error);
    return res.status(500).json({
      message: "Failed to fetch academic session",
    });
  }
};

// Update academic session
export const updateSession = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, start_date, end_date } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid session ID",
      });
    }

    if (!name || !start_date || !end_date) {
      return res.status(400).json({
        message: "Name, start date and end date are required",
      });
    }

    if (end_date < start_date) {
      return res.status(400).json({
        message: "End date cannot be before start date",
      });
    }

    const result = await pool.query(
      `UPDATE academic_sessions
       SET name = $1,
           start_date = $2,
           end_date = $3
       WHERE id = $4
       RETURNING *`,
      [name.trim(), start_date, end_date, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Academic session not found",
      });
    }

    return res.status(200).json({
      message: "Academic session updated successfully",
      session: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "This academic session already exists",
      });
    }

    console.error("Update session error:", error);
    return res.status(500).json({
      message: "Failed to update academic session",
    });
  }
};

// Activate or deactivate academic session
export const updateSessionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid session ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE academic_sessions
       SET is_active = $1
       WHERE id = $2
       RETURNING *`,
      [is_active, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "Academic session not found",
      });
    }

    return res.status(200).json({
      message: `Academic session ${is_active ? "activated" : "deactivated"} successfully`,
      session: result.rows[0],
    });
  } catch (error) {
    console.error("Update session status error:", error);
    return res.status(500).json({
      message: "Failed to update session status",
    });
  }
};
