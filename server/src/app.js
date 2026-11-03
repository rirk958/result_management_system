import express from "express";
import cors from "cors";
import helmet from "helmet";

import { getStudentTranscript } from "./services/transcript.service.js";
import { getDashboard } from "./services/dashboard.service.js";
import { getCurrentUser } from "./services/auth.service.js";

import {
  authenticate,
  authorize,
} from "./middleware/auth.middleware.js";

import {
  createProgram,
  getPrograms,
  getProgramById,
  updateProgram,
  deactivateProgram,
} from "./services/program.service.js";

import {
  createSession,
  getSessions,
  getSessionById,
  updateSession,
  updateSessionStatus,
} from "./services/session.service.js";


import {
  createSemester,
  getSemesters,
  getSemesterById,
  updateSemester,
  updateSemesterStatus,
} from "./services/semester.service.js";


import {
  createUser,
  getUsers,
  getUserById,
  updateUser,
  updateUserStatus,
  loginUser,
} from "./services/user.service.js";

import {
  createStudent,
  getStudents,
  getStudentById,
  updateStudent,
  updateStudentStatus,
} from "./services/student.service.js";

import {
  createTeacher,
  getTeachers,
  getTeacherById,
  updateTeacher,
  updateTeacherStatus,
} from "./services/teacher.service.js";

import {
  createDepartment,
  getDepartments,
  getDepartmentById,
  updateDepartment,
  updateDepartmentStatus,
} from "./services/department.service.js";

import {
  createCourse,
  getCourses,
  getCourseById,
  updateCourse,
  updateCourseStatus,
} from "./services/course.service.js";

import {
  createCourseOffering,
  getCourseOfferings,
  getCourseOfferingById,
  updateCourseOffering,
  updateCourseOfferingStatus,
} from "./services/courseOffering.service.js";

import {
  createAssessment,
  getAssessments,
  getAssessmentById,
  updateAssessment,
  updateAssessmentStatus,
} from "./services/assessment.service.js";

import {
  createMark,
  getMarks,
  getMarkById,
  updateMark,
  getMarksByAssessment,
saveAssessmentMarks,
} from "./services/mark.service.js";

import {
  createEnrollment,
  getEnrollments,
  getEnrollmentById,
  updateEnrollmentStatus
} from "./services/enrollment.service.js";

import {
  createGradingScale,
  getGradingScales,
  getGradingScaleById,
  updateGradingScale,
  deleteGradingScale,
} from "./services/gradingScale.service.js";

import {
  calculateCourseResult,
  getCourseResults,
  getCourseResultById,
} from "./services/courseResult.service.js";

import {
  calculateSemesterResult,
  getSemesterResults,
  getSemesterResultById,
} from "./services/semesterResult.service.js";

import {
  publishSemesterResult,
  unpublishSemesterResult,
  getPublishedResultsForStudent,
} from "./services/resultPublishing.service.js";

import {
  getAuditLogs,
  getAuditLogById,
} from "./services/auditLog.service.js";

import {
  getSemesterResultReport,
  getCourseResultReport,
} from "./services/resultReport.service.js";



const app = express();

// Prevent API responses from returning 304 due to ETag caching.
app.set("etag", false);

// Request logging
app.use((req, res, next) => {
  const startedAt = Date.now();

  res.on("finish", () => {
    console.log(
      `[API] ${req.method} ${req.path} -> ${res.statusCode} ` +
      `(${Date.now() - startedAt}ms)`
    );
  });

  next();
});

app.use(helmet());
app.use(cors());
app.use(express.json());

// Prevent browser caching of API responses.
app.use("/api", (req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});

//////////      Test route    //////////
app.get("/api/health", (req, res) => {
  res.json({ message: "Result Management API is running" });
});


//////////       Audit Logs       //////////
app.get("/api/audit-logs", authenticate, authorize("admin"), getAuditLogs);

app.get("/api/audit-logs/:id", authenticate, authorize("admin"), getAuditLogById);

//////////       Transcript       //////////
app.get("/api/students/:student_id/transcript", authenticate, authorize("admin"), getStudentTranscript);

//////////       Dashboard        //////////
app.get("/api/dashboard", authenticate, authorize("admin"), getDashboard);

//////////     Authentication     //////////
app.get("/api/auth/me", authenticate, getCurrentUser);

//===============================
//           Programs
//===============================
app.post("/api/programs", authenticate, authorize("admin"), createProgram);
app.get("/api/programs", authenticate, authorize("admin"), getPrograms);
app.get("/api/programs/:id", authenticate, authorize("admin"), getProgramById);
app.put("/api/programs/:id", authenticate, authorize("admin"), updateProgram);
app.patch("/api/programs/:id/status", authenticate, authorize("admin"), deactivateProgram);

//===============================
//       Academic Sessions
//===============================
app.post("/api/sessions", authenticate, authorize("admin"), createSession);
app.get("/api/sessions", authenticate, authorize("admin"), getSessions);
app.get("/api/sessions/:id", authenticate, authorize("admin"), getSessionById);
app.put("/api/sessions/:id", authenticate, authorize("admin"), updateSession);
app.patch("/api/sessions/:id/status", authenticate, authorize("admin"), updateSessionStatus);

//===============================
//           Semesters
//===============================
app.post("/api/semesters", authenticate, authorize("admin"), createSemester);
app.get("/api/semesters", authenticate, authorize("admin"), getSemesters);
app.get("/api/semesters/:id", authenticate, authorize("admin"), getSemesterById);
app.put("/api/semesters/:id", authenticate, authorize("admin"), updateSemester);
app.patch("/api/semesters/:id/status", authenticate, authorize("admin"), updateSemesterStatus);

//===============================
//             Users
//===============================
app.post("/api/users", authenticate, authorize("admin"), createUser);
app.get("/api/users", authenticate, authorize("admin"), getUsers);
app.get("/api/users/:id", authenticate, authorize("admin"), getUserById);
app.put("/api/users/:id", authenticate, authorize("admin"), updateUser);
app.patch("/api/users/:id/status", authenticate, authorize("admin"), updateUserStatus);

// Public login
app.post("/api/auth/login", loginUser);

//===============================
//            Students
//===============================
app.post("/api/students", authenticate, authorize("admin"), createStudent);
app.get("/api/students", authenticate, authorize("admin"), getStudents);
app.get("/api/students/:id", authenticate, authorize("admin"), getStudentById);
app.put("/api/students/:id", authenticate, authorize("admin"), updateStudent);
app.patch("/api/students/:id/status", authenticate, authorize("admin"), updateStudentStatus);

//===============================
//            Teachers
//===============================
app.post("/api/teachers", authenticate, authorize("admin"), createTeacher);
app.get("/api/teachers", authenticate, authorize("admin"), getTeachers);
app.get("/api/teachers/:id", authenticate, authorize("admin"), getTeacherById);
app.put("/api/teachers/:id", authenticate, authorize("admin"), updateTeacher);
app.patch("/api/teachers/:id/status", authenticate, authorize("admin"), updateTeacherStatus);

//===============================
//          Departments
//===============================
app.post("/api/departments", authenticate, authorize("admin"), createDepartment);
app.get("/api/departments", authenticate, authorize("admin"), getDepartments);
app.get("/api/departments/:id", authenticate, authorize("admin"), getDepartmentById);
app.put("/api/departments/:id", authenticate, authorize("admin"), updateDepartment);
app.patch("/api/departments/:id/status", authenticate, authorize("admin"), updateDepartmentStatus);

//===============================
//             Courses
//===============================
app.post("/api/courses", authenticate, authorize("admin"), createCourse);
app.get("/api/courses", authenticate, authorize("admin"), getCourses);
app.get("/api/courses/:id", authenticate, authorize("admin"), getCourseById);
app.put("/api/courses/:id", authenticate, authorize("admin"), updateCourse);
app.patch("/api/courses/:id/status", authenticate, authorize("admin"), updateCourseStatus);

//===============================
//         Course Offerings
//===============================
app.post("/api/course-offerings", authenticate, authorize("admin"), createCourseOffering);
app.get("/api/course-offerings", authenticate, authorize("admin"), getCourseOfferings);
app.get("/api/course-offerings/:id", authenticate, authorize("admin"), getCourseOfferingById);
app.put("/api/course-offerings/:id", authenticate, authorize("admin"), updateCourseOffering);
app.patch("/api/course-offerings/:id/status", authenticate, authorize("admin"), updateCourseOfferingStatus);

//===============================
//           Enrollments
//===============================
// Add these if you have already registered the enrollment functions.
app.post("/api/enrollments", authenticate, authorize("admin"), createEnrollment);
app.get("/api/enrollments", authenticate, authorize("admin"), getEnrollments);
app.get("/api/enrollments/:id", authenticate, authorize("admin"), getEnrollmentById);
app.patch("/api/enrollments/:id/status", authenticate, authorize("admin"), updateEnrollmentStatus);

//===============================
//           Assessments
//===============================
app.post("/api/assessments", authenticate, authorize("admin"), createAssessment);
app.get("/api/assessments", authenticate, authorize("admin"), getAssessments);
app.get("/api/assessments/:id", authenticate, authorize("admin"), getAssessmentById);
app.put("/api/assessments/:id", authenticate, authorize("admin"), updateAssessment);
app.patch("/api/assessments/:id/status", authenticate, authorize("admin"), updateAssessmentStatus);

//===============================
//              Marks
//===============================
app.post("/api/marks", authenticate, authorize("admin"), createMark);
app.get("/api/marks", authenticate, authorize("admin"), getMarks);
app.get("/api/marks/:id", authenticate, authorize("admin"), getMarkById);
app.put("/api/marks/:id", authenticate, authorize("admin"), updateMark);
// Assessment Marks Entry
app.get(
  "/api/assessments/:id/marks",
  authenticate,
  authorize("admin"),
  getMarksByAssessment
);

app.put(
  "/api/assessments/:id/marks",
  authenticate,
  authorize("admin"),
  saveAssessmentMarks
);

//===============================
//          Grading Scales
//===============================
app.post("/api/grading-scales", authenticate, authorize("admin"), createGradingScale);
app.get("/api/grading-scales", authenticate, authorize("admin"), getGradingScales);
app.get("/api/grading-scales/:id", authenticate, authorize("admin"), getGradingScaleById);
app.put("/api/grading-scales/:id", authenticate, authorize("admin"), updateGradingScale);
app.delete("/api/grading-scales/:id", authenticate, authorize("admin"), deleteGradingScale);

//===============================
//          Course Results
//===============================
app.post("/api/course-results/:enrollment_id/calculate", authenticate, authorize("admin"), calculateCourseResult);
app.get("/api/course-results", authenticate, authorize("admin"), getCourseResults);
app.get("/api/course-results/:id", authenticate, authorize("admin"), getCourseResultById);

//===============================
//         Semester Results
//===============================
app.post("/api/semester-results/calculate", authenticate, authorize("admin"), calculateSemesterResult);
app.get("/api/semester-results", authenticate, authorize("admin"), getSemesterResults);
app.get("/api/semester-results/:id", authenticate, authorize("admin"), getSemesterResultById);

//===============================
//       Result Publishing
//===============================
app.patch("/api/semester-results/:id/publish", authenticate, authorize("admin"), publishSemesterResult);
app.patch("/api/semester-results/:id/unpublish", authenticate, authorize("admin"), unpublishSemesterResult);
app.get(
  "/api/my/published-results",
  authenticate,
  authorize("student"),
  getPublishedResultsForStudent
);

//===============================
//             Reports
//===============================
app.get("/api/reports/semester-results", authenticate, authorize("admin"), getSemesterResultReport);
app.get("/api/reports/course-results", authenticate, authorize("admin"), getCourseResultReport);



//================================
//          404 Handler
//================================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "API endpoint not found",
    path: req.path,
  });
});


//================================
//       Global Error Handler
//================================
app.use((err, req, res, next) => {
  console.error("[API ERROR]", {
    method: req.method,
    path: req.path,
    message: err.message,
    stack: err.stack,
  });

  if (res.headersSent) {
    return next(err);
  }

  const status =
    Number.isInteger(err.status) &&
    err.status >= 400 &&
    err.status < 600
      ? err.status
      : 500;

  res.status(status).json({
    success: false,
    message:
      status >= 500
        ? "Internal server error"
        : err.message,
  });
});

export default app;