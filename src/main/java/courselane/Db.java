package courselane;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Db {

    private static final String DEFAULT_URL =
        "jdbc:mysql://localhost:3306/CourseLaneDB?autoReconnect=true&useSSL=false";
    private static final String DEFAULT_USER = "root";
    private static final String DEFAULT_PASS = "password";

    private static String envOrDefault(String name, String fallback) {
        String v = System.getenv(name);
        return (v == null || v.isBlank()) ? fallback : v;
    }

    public static Connection get() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL driver not found", e);
        }
        return DriverManager.getConnection(
            envOrDefault("COURSELANE_DB_URL", DEFAULT_URL),
            envOrDefault("COURSELANE_DB_USER", DEFAULT_USER),
            envOrDefault("COURSELANE_DB_PASSWORD", DEFAULT_PASS));
    }
}
