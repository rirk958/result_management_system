
import pool from "../config/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

// Create a user
export const createUser = async (req, res) => {
  try {
    const { full_name, email, password, role } = req.body;

    if (
      !full_name?.trim() ||
      !email?.trim() ||
      !password ||
      !role
    ) {
      return res.status(400).json({
        message: "Full name, email, password and role are required",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const allowedRoles = ["admin", "teacher", "student"];

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        message: "Please provide a valid email address",
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: "Password must be at least 8 characters",
      });
    }

    if (!allowedRoles.includes(role)) {
      return res.status(400).json({
        message: "Role must be admin, teacher or student",
      });
    }

    const password_hash = await bcrypt.hash(password, 12);

    const result = await pool.query(
      `INSERT INTO users (full_name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, full_name, email, role, is_active, created_at`,
      [full_name.trim(), normalizedEmail, password_hash, role]
    );

    return res.status(201).json({
      message: "User created successfully",
      user: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "A user with this email already exists",
      });
    }

    console.error("Create user error:", error);
    return res.status(500).json({
      message: "Failed to create user",
    });
  }
};

// Get all users
export const getUsers = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, full_name, email, role, is_active, created_at
       FROM users
       ORDER BY id DESC`
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    console.error("Get users error:", error);
    return res.status(500).json({
      message: "Failed to fetch users",
    });
  }
};

// Get one user by ID
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid user ID",
      });
    }

    const result = await pool.query(
      `SELECT id, full_name, email, role, is_active, created_at
       FROM users
       WHERE id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Get user error:", error);
    return res.status(500).json({
      message: "Failed to fetch user",
    });
  }
};

// Update user details
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { full_name, email, role } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid user ID",
      });
    }

    if (
      !full_name?.trim() ||
      !email?.trim() ||
      !role
    ) {
      return res.status(400).json({
        message: "Full name, email and role are required",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const allowedRoles = ["admin", "teacher", "student"];

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        message: "Please provide a valid email address",
      });
    }

    if (!allowedRoles.includes(role)) {
      return res.status(400).json({
        message: "Role must be admin, teacher or student",
      });
    }

    const result = await pool.query(
      `UPDATE users
       SET full_name = $1,
           email = $2,
           role = $3
       WHERE id = $4
       RETURNING id, full_name, email, role, is_active, created_at`,
      [full_name.trim(), normalizedEmail, role, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    return res.status(200).json({
      message: "User updated successfully",
      user: result.rows[0],
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({
        message: "A user with this email already exists",
      });
    }

    console.error("Update user error:", error);
    return res.status(500).json({
      message: "Failed to update user",
    });
  }
};

// Activate or deactivate a user
export const updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    if (!/^[1-9]\d*$/.test(id)) {
      return res.status(400).json({
        message: "Invalid user ID",
      });
    }

    if (typeof is_active !== "boolean") {
      return res.status(400).json({
        message: "is_active must be true or false",
      });
    }

    const result = await pool.query(
      `UPDATE users
       SET is_active = $1
       WHERE id = $2
       RETURNING id, full_name, email, role, is_active, created_at`,
      [is_active, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    return res.status(200).json({
      message: `User ${is_active ? "activated" : "deactivated"} successfully`,
      user: result.rows[0],
    });
  } catch (error) {
    console.error("Update user status error:", error);
    return res.status(500).json({
      message: "Failed to update user status",
    });
  }
};

// Login
export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email?.trim() || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    const result = await pool.query(
      `SELECT id, full_name, email, password_hash, role, is_active
       FROM users
       WHERE email = $1`,
      [email.trim().toLowerCase()]
    );

    if (result.rowCount === 0) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(403).json({
        message: "This account is inactive",
      });
    }

    const passwordMatches = await bcrypt.compare(
      password,
      user.password_hash
    );

    if (!passwordMatches) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error("JWT_SECRET is missing from environment");
      return res.status(500).json({
        message: "Authentication is not configured",
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({
      message: "Login failed",
    });
  }
};
