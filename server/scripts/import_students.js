
import bcrypt from "bcryptjs";
import pool from "../src/config/db.js";

const PROGRAM_CODE = "BSCCSE";
const SESSION_NAME = "2026-2027";
const TEMP_PASSWORD = "12341234";

const students = [
  ["22001", "Din Muhammad"],
  ["22002", "Md Rashadul Islam Rohan"],
  ["22003", "Md. Saif Al Islam"],
  ["22004", "Mushfika Mehjabin Prapti"],
  ["22005", "Rahim Istiak Rafi"],
  ["22006", "Abu Siddiqui Alfi"],
  ["22008", "Prince Shahriar Sazzad"],
  ["22009", "Pushpita"],
  ["22010", "Sumaia Akter Eti"],
  ["22011", "Sania Sultana"],
  ["22012", "Shakib Ahmed Numan"],
  ["22013", "Kazi Abu Sayem"],
  ["22015", "Nahid Khan Shuvo"],
  ["22016", "Md.Faisalul Haque"],
  ["22021", "Md Ashraful Hasan"],
  ["22022", "Israt jahan"],
  ["22023", "Sohom das"],
  ["22024", "Marfua Binta Safiq"],
  ["22026", "Omar Faruk"],
  ["22027", "Lamia Mahajabeen"],
  ["22028", "Prosenjit Roy"],
  ["22029", "sarwar"],
  ["22031", "Md udzzal"],
  ["22032", "Afshana Haque Disha"],
  ["22033", "Nahiyan Hossain Jeem"],
  ["22034", "Md. Sakib Ali"],
  ["22035", "Shahriar Sabraj"],
  ["22036", "Trisha"],
  ["22039", "Md. Mehedi Hasan"],
  ["22041", "Noor Mohammad Anto"],
  ["22046", "Rahul Mozumdar"],
  ["22047", "Md.Rahemon Sarker"],
  ["22049", "Abu Raihan"],
  ["22050", "Sabil Satcho"],
  ["22051", "Shahedul Islam Shahed"],
  ["22052", "Otishy Islam Puspi"],
  ["22053", "Munni Akter"],
  ["22054", "Ashura Islam Emo"],
  ["22055", "Samia Akter"],
  ["22056", "Farjana Akter"],
  ["22057", "Mahidul Islam"],
  ["22058", "Farhan Uddin Sarkar"],
  ["22060", "Fareha Moshrafa"],
  ["22062", "Mahammad shariar Alam Sarker"],
  ["22064", "Anika Akhter Eti"],
  ["22065", "Shoyab Shorashi"],
  ["22068", "Md. Abdullah Al Rakib"],
  ["22069", "Rafidul Islam Onnoy"],
  ["22070", "Purna Deb paul"],
  ["22071", "Md.Shakib Mia"],
  ["22072", "Zubaier Galib"],
  ["22073", "M.H. Nokib"],
  ["22074", "Monjurul Islam Akash"],
  ["22075", "Kazi Saif Hossain Emon"],
  ["22076", "Shakib Al Hasan"],
  ["22077", "Md Siam Islam"],
  ["22078", "Farzana Akter Lima"],
  ["22080", "Shrestha saha"],
  ["22082", "Mst.Pinkey Khatun"],
  ["22083", "Umme Hafsa Hany"],
  ["22084", "Mahmudul Hasan"],
  ["22085", "Rashedur Zaman"],
  ["22086", "Mahir Tahomid"],
  ["22087", "Ali Haider Sami"],
  ["22088", "Shachin Debnath"],
  ["22089", "Md. Niharul Haque Dihan"],
  ["22092", "Md. Al Amin Hossain"],
  ["22093", "Edul hasan"],
  ["22094", "Shaharia Al Nafis"],
  ["22095", "MD Muktadin Hassan Mahim"],
  ["22096", "Imran Hosen"],
  ["22097", "Rahul Mondal"],
  ["22099", "Md Rafikul Islam"],
  ["22100", "Mahbub Hossain"],
  ["22106", "Nabiha Tawsen"],
];

function emailFromName(name) {
  const parts = name
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .match(/[a-z0-9]+/g);

  return `${parts.join(".")}@gmail.com`;
}

async function importStudents() {
  const client = await pool.connect();

  let inserted = 0;
  const skipped = [];

  try {
    await client.query("BEGIN");

    // Find program
    const programResult = await client.query(
      "SELECT id FROM programs WHERE code = $1",
      [PROGRAM_CODE]
    );

    if (programResult.rowCount !== 1) {
      throw new Error(`Program ${PROGRAM_CODE} not found.`);
    }

    // Find academic session
    const sessionResult = await client.query(
      "SELECT id FROM academic_sessions WHERE name = $1",
      [SESSION_NAME]
    );

    if (sessionResult.rowCount !== 1) {
      throw new Error(`Session ${SESSION_NAME} not found.`);
    }

    const programId = programResult.rows[0].id;
    const sessionId = sessionResult.rows[0].id;

    // Same temporary password for all students
    const passwordHash = await bcrypt.hash(TEMP_PASSWORD, 12);

    for (const [studentNo, fullName] of students) {
      const email = emailFromName(fullName);

      // Skip existing student numbers
      const existingStudent = await client.query(
        "SELECT id FROM students WHERE student_no = $1",
        [studentNo]
      );

      if (existingStudent.rowCount > 0) {
        skipped.push(`${studentNo} - Student already exists`);
        continue;
      }

      // Skip existing emails
      const existingEmail = await client.query(
        "SELECT id FROM users WHERE email = $1",
        [email]
      );

      if (existingEmail.rowCount > 0) {
        skipped.push(`${studentNo} - Email already exists: ${email}`);
        continue;
      }

      // Create user
      const userResult = await client.query(
        `INSERT INTO users
          (full_name, email, password_hash, role)
         VALUES ($1, $2, $3, 'student')
         RETURNING id`,
        [fullName, email, passwordHash]
      );

      const userId = userResult.rows[0].id;

      // Create student
      await client.query(
        `INSERT INTO students
          (user_id, student_no, program_id, session_id)
         VALUES ($1, $2, $3, $4)`,
        [userId, studentNo, programId, sessionId]
      );

      inserted++;

      console.log(
        `Inserted: ${studentNo} | ${fullName} | ${email}`
      );
    }

    await client.query("COMMIT");

    console.log("\n========== IMPORT SUMMARY ==========");
    console.log("Total records:", students.length);
    console.log("Inserted:", inserted);
    console.log("Skipped:", skipped.length);

    if (skipped.length > 0) {
      console.log("\nSkipped records:");

      skipped.forEach((item) => console.log(item));
    }

    console.log("\nTemporary password:", TEMP_PASSWORD);
    console.log("====================================");

  } catch (error) {
    await client.query("ROLLBACK");

    console.error("\nImport failed. All changes rolled back.");
    console.error(error.message);

    process.exitCode = 1;

  } finally {
    client.release();
    await pool.end();
  }
}

console.log(`Preparing ${students.length} student records...`);

importStudents();
