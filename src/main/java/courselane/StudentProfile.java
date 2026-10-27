package courselane;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class StudentProfile {

    public static class Student {
        public int id;
        public String firstName;
        public String lastName;
        public String email;
        public String passwordHash;
        public String major;
        public Integer preferredCredits;
        public Integer gradYear;
        public String gradSemester;
    }

    public static class Enrollment {
        public String subject;
        public String number;
        public String title;
        public int year;
        public String semester;
        public String section;
        public String status;
        public String grade;
    }

    public static String hashPassword(String plain) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(plain.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 not available", e);
        }
    }

    private static Student mapStudent(ResultSet rs) throws SQLException {
        Student s = new Student();
        s.id = rs.getInt("student_id");
        s.firstName = rs.getString("first_name");
        s.lastName = rs.getString("last_name");
        s.email = rs.getString("email");
        s.passwordHash = rs.getString("password_hash");
        try {
            s.major = rs.getString("major");
        } catch (SQLException e) {
            s.major = "Computer Science";
        }
        if (s.major == null) {
            s.major = "Computer Science";
        }
        int pref = rs.getInt("preferred_credits_per_term");
        s.preferredCredits = rs.wasNull() ? null : pref;
        int gy = rs.getInt("grad_year");
        s.gradYear = rs.wasNull() ? null : gy;
        s.gradSemester = rs.getString("grad_semester");
        return s;
    }

    public static Student findById(int id) throws SQLException {
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT * FROM Student WHERE student_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapStudent(rs) : null;
            }
        }
    }

    public static Student findByEmail(String email) throws SQLException {
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT * FROM Student WHERE email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapStudent(rs) : null;
            }
        }
    }

    public static List<Student> listAll() throws SQLException {
        List<Student> out = new ArrayList<>();
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT * FROM Student ORDER BY last_name, first_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                out.add(mapStudent(rs));
            }
        }
        return out;
    }

    public static List<String[]> listTerms() throws SQLException {
        List<String[]> terms = new ArrayList<>();
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT year, semester FROM Term ORDER BY year DESC, semester DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                terms.add(new String[] {
                    String.valueOf(rs.getInt("year")), rs.getString("semester") });
            }
        }
        return terms;
    }

    private static int nextId(Connection con) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                 "SELECT COALESCE(MAX(student_id), 0) + 1 FROM Student");
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt(1);
        }
    }

    public static int create(String firstName, String lastName, String email,
            String plainPassword, String major, Integer preferredCredits,
            Integer gradYear, String gradSemester) throws SQLException {
        if (findByEmail(email) != null) {
            throw new SQLException("Email is already registered: " + email);
        }
        try (Connection con = Db.get()) {
            int id = nextId(con);
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO Student (student_id, first_name, last_name, email,"
                  + " password_hash, major, preferred_credits_per_term,"
                  + " grad_year, grad_semester) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                ps.setInt(1, id);
                ps.setString(2, firstName);
                ps.setString(3, lastName);
                ps.setString(4, email);
                ps.setString(5, hashPassword(plainPassword));
                ps.setString(6, major == null || major.isBlank()
                    ? "Computer Science" : major.trim());
                if (preferredCredits == null) {
                    ps.setNull(7, java.sql.Types.INTEGER);
                } else {
                    ps.setInt(7, preferredCredits);
                }
                if (gradYear == null) {
                    ps.setNull(8, java.sql.Types.INTEGER);
                } else {
                    ps.setInt(8, gradYear);
                }
                ps.setString(9, gradSemester);
                ps.executeUpdate();
            }
            return id;
        }
    }

    public static void update(int id, String firstName, String lastName, String email,
            String plainPassword, String major, Integer preferredCredits,
            Integer gradYear, String gradSemester) throws SQLException {
        Student existing = findByEmail(email);
        if (existing != null && existing.id != id) {
            throw new SQLException("Email is already registered: " + email);
        }
        String hash = (plainPassword == null || plainPassword.isBlank())
            ? findById(id).passwordHash
            : hashPassword(plainPassword);
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "UPDATE Student SET first_name = ?, last_name = ?, email = ?,"
               + " password_hash = ?, major = ?, preferred_credits_per_term = ?,"
               + " grad_year = ?, grad_semester = ? WHERE student_id = ?")) {
            ps.setString(1, firstName);
            ps.setString(2, lastName);
            ps.setString(3, email);
            ps.setString(4, hash);
            ps.setString(5, major == null || major.isBlank()
                ? "Computer Science" : major.trim());
            if (preferredCredits == null) {
                ps.setNull(6, java.sql.Types.INTEGER);
            } else {
                ps.setInt(6, preferredCredits);
            }
            if (gradYear == null) {
                ps.setNull(7, java.sql.Types.INTEGER);
            } else {
                ps.setInt(7, gradYear);
            }
            ps.setString(8, gradSemester);
            ps.setInt(9, id);
            ps.executeUpdate();
        }
    }

    public static List<Enrollment> history(int studentId) throws SQLException {
        List<Enrollment> out = new ArrayList<>();
        String sql = "SELECT t.subject_code, t.course_number, c.title,"
            + " t.year, t.semester, t.section_number, t.status, t.grade"
            + " FROM Takes t JOIN Course c"
            + " ON c.subject_code = t.subject_code AND c.course_number = t.course_number"
            + " WHERE t.student_id = ? ORDER BY t.year, t.semester, t.subject_code";
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Enrollment e = new Enrollment();
                    e.subject = rs.getString(1);
                    e.number = rs.getString(2);
                    e.title = rs.getString(3);
                    e.year = rs.getInt(4);
                    e.semester = rs.getString(5);
                    e.section = rs.getString(6);
                    e.status = rs.getString(7);
                    e.grade = rs.getString(8);
                    out.add(e);
                }
            }
        }
        return out;
    }
}
