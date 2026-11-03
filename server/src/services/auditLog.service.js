
import pool from "../config/db.js";

// Reusable function for recording an action.
// Pass a transaction client as the second argument when needed.
export const writeAuditLog = async (
  {
    user_id = null,
    action,
    table_name,
    record_id = null,
    details = {},
  },
  db = pool
) => {
  const result = await db.query(
    `INSERT INTO audit_logs
       (user_id, action, table_name, record_id, details)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [
      user_id,
      action,
      table_name,
      record_id,
      JSON.stringify(details),
    ]
  );

  return result.rows[0];
};

// Get audit logs with optional filters
export const getAuditLogs = async (req, res) => {
  try {
    const { user_id, action, table_name, limit = "50", offset = "0" } =
      req.query;

    if (
      user_id != null &&
      (!/^\d+$/.test(String(user_id)) || Number(user_id) < 1)
    ) {
      return res.status(400).json({ message: "Invalid user_id" });
    }

    if (
      !/^\d+$/.test(String(limit)) ||
      Number(limit) < 1 ||
      Number(limit) > 200
    ) {
      return res.status(400).json({
        message: "limit must be between 1 and 200",
      });
    }

    if (!/^\d+$/.test(String(offset)) || Number(offset) < 0) {
      return res.status(400).json({ message: "Invalid offset" });
    }

    const result = await pool.query(
      `SELECT
         al.*,
         u.full_name AS user_name,
         u.email AS user_email
       FROM audit_logs al
       LEFT JOIN users u ON u.id = al.user_id
       WHERE ($1::bigint IS NULL OR al.user_id = $1)
         AND ($2::text IS NULL OR al.action = $2)
         AND ($3::text IS NULL OR al.table_name = $3)
       ORDER BY al.created_at DESC, al.id DESC
       LIMIT $4 OFFSET $5`,
      [
        user_id || null,
        action || null,
        table_name || null,
        Number(limit),
        Number(offset),
      ]
    );

    return res.status(200).json({
      count: result.rows.length,
      limit: Number(limit),
      offset: Number(offset),
      logs: result.rows,
    });
  } catch (error) {
    console.error("Get audit logs error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

// Get one audit log by ID
export const getAuditLogById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^\d+$/.test(id) || Number(id) < 1) {
      return res.status(400).json({ message: "Invalid audit log ID" });
    }

    const result = await pool.query(
      `SELECT
         al.*,
         u.full_name AS user_name,
         u.email AS user_email
       FROM audit_logs al
       LEFT JOIN users u ON u.id = al.user_id
       WHERE al.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Audit log not found" });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get audit log error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
