package courselane;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Functional requirements 7 and 8: professor directory/search, professor details,
 * rating history by course and semester, and rating trends by semester and year.
 */
public class ProfessorProfile {

    private static final String URL =
        "jdbc:mysql://localhost:3306/CourseLaneDB?autoReconnect=true&useSSL=false";

    // Spring < Summer < Fall
    private static final String TERM_ORDER = "FIELD(r.semester, 'Spring', 'Summer', 'Fall')";

    public static class Summary {
        public int id;
        public String name;
        public int reviewCount;
        public Double avgQuality;
        public Double avgDifficulty;
    }

    public static class CourseStat {
        public String course;
        public String title;
        public int reviewCount;
        public Double avgQuality;
    }

    // Aggregated ratings: per course+semester, per semester, or per year
    public static class TermStat {
        public String course;      // only set for the by-course history
        public String label;       // "Fall 2025" or "2025"
        public int reviewCount;
        public int ratedCount;     // reviews that actually have a quality rating
        public Double avgQuality;
        public Double avgDifficulty;
    }

    public static class ReviewItem {
        public String course;
        public String term;
        public Double quality;
        public Double difficulty;
        public String text;
        public Date date;
    }

    public static class Profile {
        public Summary summary;
        public List<CourseStat> courses = new ArrayList<>();
        public List<TermStat> history = new ArrayList<>();  // by course and semester, newest first
        public List<TermStat> byTerm = new ArrayList<>();   // oldest first
        public List<TermStat> byYear = new ArrayList<>();   // oldest first
        public List<ReviewItem> reviews = new ArrayList<>();
        public Double trend;                                // latest semester minus earlier average
        public String trendLabel = "Not enough data";
        public String latestTermLabel;
    }

    // ---------- helpers ----------

    private static Connection connect() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL driver not found", e);
        }
        return DriverManager.getConnection(URL, "root", "password");
    }

    private static Double dbl(ResultSet rs, int col) throws SQLException {
        double v = rs.getDouble(col);
        return rs.wasNull() ? null : v;
    }

    private static double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    public static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }

    public static String fmt(Double d) {
        return d == null ? "n/a" : String.format("%.1f", d);
    }

    // directory + search
    public static List<Summary> search(String text) throws SQLException {
        try (Connection con = connect()) {
            return summaries(con, null, text);
        }
    }

    private static List<Summary> summaries(Connection con, Integer id, String text) throws SQLException {
        boolean hasText = id == null && text != null && !text.trim().isEmpty();
        String sql =
            "SELECT p.professor_id, p.first_name, p.last_name, COUNT(r.review_id), "
          + "       AVG(r.quality_rating), AVG(r.difficulty_rating) "
          + "FROM Professor p LEFT JOIN Review r ON r.professor_id = p.professor_id "
          + (id != null ? "WHERE p.professor_id = ? "
             : hasText ? "WHERE CONCAT(p.first_name, ' ', p.last_name) LIKE ? " : "")
          + "GROUP BY p.professor_id, p.first_name, p.last_name "
          + "ORDER BY p.last_name, p.first_name";

        List<Summary> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            if (id != null) ps.setInt(1, id);
            else if (hasText) ps.setString(1, "%" + text.trim() + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Summary s = new Summary();
                    s.id = rs.getInt(1);
                    s.name = rs.getString(2) + " " + rs.getString(3);
                    s.reviewCount = rs.getInt(4);
                    s.avgQuality = dbl(rs, 5);
                    s.avgDifficulty = dbl(rs, 6);
                    list.add(s);
                }
            }
        }
        return list;
    }

    // professor detail page
    // Returns null when no professor has this id. */
    public static Profile load(int professorId) throws SQLException {
        try (Connection con = connect()) {
            List<Summary> found = summaries(con, professorId, null);
            if (found.isEmpty()) return null;

            Profile p = new Profile();
            p.summary = found.get(0);

            // courses this professor has been reviewed for
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT c.subject_code, c.course_number, c.title, COUNT(*), AVG(r.quality_rating) "
                  + "FROM Review r JOIN Course c "
                  + "  ON c.subject_code = r.subject_code AND c.course_number = r.course_number "
                  + "WHERE r.professor_id = ? "
                  + "GROUP BY c.subject_code, c.course_number, c.title ORDER BY 1, 2")) {
                ps.setInt(1, professorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        CourseStat c = new CourseStat();
                        c.course = rs.getString(1) + " " + rs.getString(2);
                        c.title = rs.getString(3);
                        c.reviewCount = rs.getInt(4);
                        c.avgQuality = dbl(rs, 5);
                        p.courses.add(c);
                    }
                }
            }

            // full rating history by course and semester, newest first
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT r.subject_code, r.course_number, r.year, r.semester, COUNT(*), "
                  + "       COUNT(r.quality_rating), AVG(r.quality_rating), AVG(r.difficulty_rating) "
                  + "FROM Review r WHERE r.professor_id = ? "
                  + "GROUP BY r.subject_code, r.course_number, r.year, r.semester "
                  + "ORDER BY r.year DESC, " + TERM_ORDER + " DESC, r.subject_code, r.course_number")) {
                ps.setInt(1, professorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        TermStat t = new TermStat();
                        t.course = rs.getString(1) + " " + rs.getString(2);
                        t.label = rs.getString(4) + " " + rs.getInt(3);
                        t.reviewCount = rs.getInt(5);
                        t.ratedCount = rs.getInt(6);
                        t.avgQuality = dbl(rs, 7);
                        t.avgDifficulty = dbl(rs, 8);
                        p.history.add(t);
                    }
                }
            }

            // trend by semester, oldest first
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT r.year, r.semester, COUNT(*), COUNT(r.quality_rating), "
                  + "       AVG(r.quality_rating), AVG(r.difficulty_rating) "
                  + "FROM Review r WHERE r.professor_id = ? "
                  + "GROUP BY r.year, r.semester ORDER BY r.year, " + TERM_ORDER)) {
                ps.setInt(1, professorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        TermStat t = new TermStat();
                        t.label = rs.getString(2) + " " + rs.getInt(1);
                        t.reviewCount = rs.getInt(3);
                        t.ratedCount = rs.getInt(4);
                        t.avgQuality = dbl(rs, 5);
                        t.avgDifficulty = dbl(rs, 6);
                        p.byTerm.add(t);
                    }
                }
            }

            // trend by year, oldest first
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT r.year, COUNT(*), COUNT(r.quality_rating), "
                  + "       AVG(r.quality_rating), AVG(r.difficulty_rating) "
                  + "FROM Review r WHERE r.professor_id = ? GROUP BY r.year ORDER BY r.year")) {
                ps.setInt(1, professorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        TermStat t = new TermStat();
                        t.label = String.valueOf(rs.getInt(1));
                        t.reviewCount = rs.getInt(2);
                        t.ratedCount = rs.getInt(3);
                        t.avgQuality = dbl(rs, 4);
                        t.avgDifficulty = dbl(rs, 5);
                        p.byYear.add(t);
                    }
                }
            }

            // individual reviews, newest first
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT r.subject_code, r.course_number, r.year, r.semester, "
                  + "       r.quality_rating, r.difficulty_rating, r.review_text, r.review_date "
                  + "FROM Review r WHERE r.professor_id = ? "
                  + "ORDER BY r.review_date DESC, r.review_id DESC")) {
                ps.setInt(1, professorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        ReviewItem r = new ReviewItem();
                        r.course = rs.getString(1) + " " + rs.getString(2);
                        r.term = rs.getString(4) + " " + rs.getInt(3);
                        r.quality = dbl(rs, 5);
                        r.difficulty = dbl(rs, 6);
                        r.text = rs.getString(7);
                        r.date = rs.getDate(8);
                        p.reviews.add(r);
                    }
                }
            }

            computeTrend(p);
            return p;
        }
    }

    private static void computeTrend(Profile p) {
        List<TermStat> terms = new ArrayList<>();
        for (TermStat t : p.byTerm) {
            if (t.avgQuality != null) terms.add(t);
        }
        if (terms.size() < 2) return;

        TermStat latest = terms.get(terms.size() - 1);
        double earlierSum = 0;
        int earlierCount = 0;
        for (int i = 0; i < terms.size() - 1; i++) {
            earlierSum += terms.get(i).avgQuality * terms.get(i).ratedCount;
            earlierCount += terms.get(i).ratedCount;
        }

        p.trend = round2(latest.avgQuality - earlierSum / earlierCount);
        p.latestTermLabel = latest.label;
        if (p.trend > 0.1) {
            p.trendLabel = "Improving";
        } else if (p.trend < -0.1) {
            p.trendLabel = "Declining";
        } else {
            p.trendLabel = "Steady";
        }
    }
}
