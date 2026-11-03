-- =========================================================
-- RESULT MANAGEMENT SYSTEM
-- PostgreSQL starter schema
-- =========================================================

-- Run this file after creating and connecting to database:
-- CREATE DATABASE result_management;

BEGIN;

-- 1. User accounts and roles
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Departments
CREATE TABLE departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(150) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Degree programs
CREATE TABLE programs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id BIGINT NOT NULL REFERENCES departments(id),
    code VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    degree_name VARCHAR(100) NOT NULL DEFAULT 'Bachelor',
    total_semesters INTEGER NOT NULL DEFAULT 8 CHECK (total_semesters > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (department_id, name)
);

-- 4. Academic sessions / admission batches
CREATE TABLE academic_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,       -- e.g. 2025-2026
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

-- 5. Semester definitions
-- A semester belongs to a program; labels and numbers are data, not hardcoded.
CREATE TABLE semesters (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    program_id BIGINT NOT NULL REFERENCES programs(id),
    semester_number INTEGER NOT NULL CHECK (semester_number > 0),
    name VARCHAR(100) NOT NULL,             -- e.g. First Semester
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (program_id, semester_number),
    UNIQUE (program_id, name)
);

-- 6. Student profiles
CREATE TABLE students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id),
    student_no VARCHAR(50) NOT NULL,
    program_id BIGINT NOT NULL REFERENCES programs(id),
    session_id BIGINT NOT NULL REFERENCES academic_sessions(id),
    admission_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'graduated', 'suspended', 'withdrawn')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. Teacher profiles
CREATE TABLE teachers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id),
    department_id BIGINT NOT NULL REFERENCES departments(id),
    employee_no VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 8. Courses
CREATE TABLE courses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id BIGINT NOT NULL REFERENCES departments(id),
    code VARCHAR(30) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    credit NUMERIC(4,2) NOT NULL CHECK (credit > 0),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 9. Course offerings
-- The same course can be offered in different sessions/semesters.
CREATE TABLE course_offerings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES courses(id),
    program_id BIGINT NOT NULL REFERENCES programs(id),
    session_id BIGINT NOT NULL REFERENCES academic_sessions(id),
    semester_id BIGINT NOT NULL REFERENCES semesters(id),
    teacher_id BIGINT REFERENCES teachers(id),
    section_name VARCHAR(30) NOT NULL DEFAULT 'A',
    status VARCHAR(20) NOT NULL DEFAULT 'setup'
        CHECK (status IN ('setup', 'open', 'completed', 'published')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (course_id, session_id, semester_id, section_name)
);

-- 10. Student enrollment in course offerings
CREATE TABLE enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id),
    course_offering_id BIGINT NOT NULL REFERENCES course_offerings(id),
    status VARCHAR(20) NOT NULL DEFAULT 'enrolled'
        CHECK (status IN ('enrolled', 'completed', 'withdrawn', 'incomplete')),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, course_offering_id)
);

-- 11. Configurable assessment components
-- Examples: Assignment, Class Test, Midterm, Final, Presentation.
CREATE TABLE assessments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_offering_id BIGINT NOT NULL REFERENCES course_offerings(id),
    name VARCHAR(100) NOT NULL,
    max_marks NUMERIC(7,2) NOT NULL CHECK (max_marks > 0),
    weight_percent NUMERIC(5,2) NOT NULL CHECK (weight_percent >= 0 AND weight_percent <= 100),
    display_order INTEGER NOT NULL DEFAULT 1 CHECK (display_order > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (course_offering_id, name)
);

-- 12. Marks
-- NULL obtained_marks means not entered yet; zero means an actual zero mark.
CREATE TABLE marks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id BIGINT NOT NULL REFERENCES enrollments(id),
    assessment_id BIGINT NOT NULL REFERENCES assessments(id),
    obtained_marks NUMERIC(7,2) CHECK (obtained_marks >= 0),
    entered_by BIGINT REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (enrollment_id, assessment_id)
);

-- 13. Configurable grading scale
CREATE TABLE grading_scales (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    program_id BIGINT NOT NULL REFERENCES programs(id),
    grade_letter VARCHAR(5) NOT NULL,
    min_percent NUMERIC(5,2) NOT NULL CHECK (min_percent >= 0 AND min_percent <= 100),
    max_percent NUMERIC(5,2) NOT NULL CHECK (max_percent >= 0 AND max_percent <= 100),
    grade_point NUMERIC(4,2) NOT NULL CHECK (grade_point >= 0),
    UNIQUE (program_id, grade_letter),
    CHECK (max_percent >= min_percent)
);

-- 14. Calculated course results
-- Store the calculated snapshot for a given enrollment.
CREATE TABLE course_results (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    enrollment_id BIGINT UNIQUE NOT NULL REFERENCES enrollments(id),
    total_marks NUMERIC(7,2) NOT NULL CHECK (total_marks >= 0),
    percentage NUMERIC(5,2) NOT NULL CHECK (percentage >= 0 AND percentage <= 100),
    grade_letter VARCHAR(5) NOT NULL,
    grade_point NUMERIC(4,2) NOT NULL CHECK (grade_point >= 0),
    quality_points NUMERIC(8,3) NOT NULL CHECK (quality_points >= 0),
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 15. Semester result / publication record
CREATE TABLE semester_results (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id),
    semester_id BIGINT NOT NULL REFERENCES semesters(id),
    session_id BIGINT NOT NULL REFERENCES academic_sessions(id),
    gpa NUMERIC(4,2) CHECK (gpa >= 0),
    cgpa NUMERIC(4,2) CHECK (cgpa >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'published')),
    published_by BIGINT REFERENCES users(id),
    published_at TIMESTAMPTZ,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, semester_id, session_id),
    CHECK (
        (status = 'draft' AND published_at IS NULL)
        OR (status = 'published' AND published_at IS NOT NULL)
    )
);

-- 16. Basic audit log for important changes
CREATE TABLE audit_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Helpful indexes for common lookups
CREATE INDEX idx_students_program_session ON students(program_id, session_id);
CREATE INDEX idx_offerings_session_semester ON course_offerings(session_id, semester_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_offering ON enrollments(course_offering_id);
CREATE INDEX idx_assessments_offering ON assessments(course_offering_id);
CREATE INDEX idx_marks_enrollment ON marks(enrollment_id);
CREATE INDEX idx_marks_assessment ON marks(assessment_id);
CREATE INDEX idx_semester_results_student ON semester_results(student_id);

COMMIT;
