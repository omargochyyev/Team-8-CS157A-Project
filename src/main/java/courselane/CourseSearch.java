package courselane;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class CourseSearch {

    public static class Course {
        public String subject;
        public String number;
        public String title;
        public int units;
        public String description;
        public String category;
    }

    public static class Prereq {
        public String subject;
        public String number;
        public String title;
        public String minimumGrade;
        public Boolean met;
    }

    private static Course mapCourse(ResultSet rs) throws SQLException {
        Course c = new Course();
        c.subject = rs.getString("subject_code");
        c.number = rs.getString("course_number");
        c.title = rs.getString("title");
        c.units = rs.getInt("units");
        c.description = rs.getString("description");
        c.category = rs.getString("requirement_category");
        return c;
    }

    public static List<Course> search(String q) throws SQLException {
        List<Course> out = new ArrayList<>();
        String like = (q == null || q.isBlank()) ? "%" : "%" + q.trim() + "%";
        String sql = "SELECT subject_code, course_number, title, units, description,"
            + " requirement_category FROM Course"
            + " WHERE subject_code LIKE ? OR course_number LIKE ?"
            + " OR title LIKE ? OR description LIKE ?"
            + " ORDER BY subject_code, course_number LIMIT 100";
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, like);
            ps.setString(2, like);
            ps.setString(3, like);
            ps.setString(4, like);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(mapCourse(rs));
                }
            }
        }
        return out;
    }

    public static Course get(String subject, String number) throws SQLException {
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT subject_code, course_number, title, units, description,"
               + " requirement_category FROM Course"
               + " WHERE subject_code = ? AND course_number = ?")) {
            ps.setString(1, subject);
            ps.setString(2, number);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapCourse(rs) : null;
            }
        }
    }

    public static List<Prereq> prereqs(String subject, String number) throws SQLException {
        return prereqs(subject, number, null);
    }

    public static List<Prereq> prereqs(String subject, String number, Integer studentId)
            throws SQLException {
        List<Prereq> out = new ArrayList<>();
        String sql = "SELECT r.prereq_subject_code, r.prereq_course_number,"
            + " c.title, r.minimum_grade FROM Requires r"
            + " JOIN Course c ON c.subject_code = r.prereq_subject_code"
            + " AND c.course_number = r.prereq_course_number"
            + " WHERE r.subject_code = ? AND r.course_number = ?"
            + " ORDER BY r.prereq_subject_code, r.prereq_course_number";
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, subject);
            ps.setString(2, number);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Prereq p = new Prereq();
                    p.subject = rs.getString(1);
                    p.number = rs.getString(2);
                    p.title = rs.getString(3);
                    p.minimumGrade = rs.getString(4);
                    p.met = (studentId == null) ? null
                        : hasCompleted(con, studentId, p.subject, p.number, p.minimumGrade);
                    out.add(p);
                }
            }
        }
        return out;
    }

    static boolean hasCompleted(Connection con, int studentId,
            String subject, String number, String minimumGrade) throws SQLException {
        String sql = "SELECT grade FROM Takes WHERE student_id = ?"
            + " AND subject_code = ? AND course_number = ? AND status = 'Completed'";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ps.setString(2, subject);
            ps.setString(3, number);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (gradePasses(rs.getString(1), minimumGrade)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    static boolean gradePasses(String grade, String minimum) {
        if (minimum == null || minimum.isBlank()) {
            return true;
        }
        if (grade == null || grade.isBlank()) {
            return false;
        }
        return baseValue(grade.charAt(0)) >= baseValue(minimum.charAt(0));
    }

    private static int baseValue(char letter) {
        switch (Character.toUpperCase(letter)) {
            case 'A': return 4;
            case 'B': return 3;
            case 'C': return 2;
            case 'D': return 1;
            default: return 0;
        }
    }

    public static Map<String, int[]> completionSummary(int studentId, List<Course> courses)
            throws SQLException {
        Map<String, int[]> out = new LinkedHashMap<>();
        try (Connection con = Db.get()) {
            for (Course c : courses) {
                int met = 0;
                int total = 0;
                String sql = "SELECT r.prereq_subject_code, r.prereq_course_number,"
                    + " r.minimum_grade FROM Requires r"
                    + " WHERE r.subject_code = ? AND r.course_number = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, c.subject);
                    ps.setString(2, c.number);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            total++;
                            if (hasCompleted(con, studentId,
                                    rs.getString(1), rs.getString(2), rs.getString(3))) {
                                met++;
                            }
                        }
                    }
                }
                out.put(c.subject + "|" + c.number, new int[] { met, total });
            }
        }
        return out;
    }
}
