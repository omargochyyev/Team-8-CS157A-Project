package courselane;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ProfessorComparison {

    private static final String URL =
        "jdbc:mysql://localhost:3306/CourseLaneDB?autoReconnect=true&useSSL=false";

    public static class Row {
        public String name;
        public int reviewCount;
        public Double avgQuality;
        public Double avgDifficulty;
        public Double trend;
        public String trendLabel;

        List<Integer> terms = new ArrayList<>();
        List<Double> quality = new ArrayList<>();
        List<Double> difficulty = new ArrayList<>();
    }

    private static Connection connect() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL driver not found", e);
        }
        return DriverManager.getConnection(URL, "root", "password");
    }

    private static double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    public static List<String[]> listCourses() throws SQLException {
        List<String[]> courses = new ArrayList<>();
        try (Connection con = connect();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT subject_code, course_number, title FROM Course ORDER BY 1, 2");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                courses.add(new String[] {
                    rs.getString(1), rs.getString(2), rs.getString(3) });
            }
        }
        return courses;
    }

    public static List<Row> compare(String subjectCode, String courseNumber) throws SQLException {
        String sql =
            "SELECT p.professor_id, p.first_name, p.last_name, "
          + "       r.quality_rating, r.difficulty_rating, r.year, r.semester "
          + "FROM Review r JOIN Professor p ON p.professor_id = r.professor_id "
          + "WHERE r.subject_code = ? AND r.course_number = ?";

        Map<Integer, Row> professors = new LinkedHashMap<>();
        int latestTerm = 0;

        //this reads every review for this course and groups them by professor
        try (Connection con = connect();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, subjectCode);
            ps.setString(2, courseNumber);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt("professor_id");
                    Row row = professors.get(id);
                    if (row == null) {
                        row = new Row();
                        row.name = rs.getString("first_name") + " " + rs.getString("last_name");
                        professors.put(id, row);
                    }
                    // Spring = 1, Fall = 2, so a bigger number is a later term
                    int term = rs.getInt("year") * 10
                             + (rs.getString("semester").equals("Fall") ? 2 : 1);
                    latestTerm = Math.max(latestTerm, term);
                    row.terms.add(term);
                    row.quality.add(rs.getDouble("quality_rating"));
                    row.difficulty.add(rs.getDouble("difficulty_rating"));
                }
            }
        }

        //calculates averages, counts and trend for each professor
        List<Row> rows = new ArrayList<>(professors.values());
        for (Row row : rows) {
            double qualitySum = 0, difficultySum = 0;
            double recentSum = 0, earlierSum = 0;
            int recentCount = 0, earlierCount = 0;

            for (int i = 0; i < row.terms.size(); i++) {
                qualitySum += row.quality.get(i);
                difficultySum += row.difficulty.get(i);
                if (row.terms.get(i) == latestTerm) {
                    recentSum += row.quality.get(i);
                    recentCount++;
                } else {
                    earlierSum += row.quality.get(i);
                    earlierCount++;
                }
            }

            row.reviewCount = row.terms.size();
            row.avgQuality = round2(qualitySum / row.reviewCount);
            row.avgDifficulty = round2(difficultySum / row.reviewCount);

            if (recentCount > 0 && earlierCount > 0) {
                row.trend = round2(recentSum / recentCount - earlierSum / earlierCount);
                if (row.trend > 0.1) {
                    row.trendLabel = "Improving";
                } else if (row.trend < -0.1) {
                    row.trendLabel = "Declining";
                } else {
                    row.trendLabel = "Steady";
                }
            } else {
                row.trendLabel = "Not enough data";
            }
        }

        //best average quality first
        rows.sort((a, b) -> Double.compare(b.avgQuality, a.avgQuality));
        return rows;
    }
}
