<%@ page import="java.sql.*, courselane.Db" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<html>
<head>
  <title>Professors - CourseLane</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>

<nav class="topnav">
  <a class="brand" href="home.jsp">CourseLane</a>
  <div class="nav-links">
    <a href="home.jsp">Dashboard</a>
    <a href="courses.jsp">Course Search</a>
    <a href="#">Roadmap</a>
    <a href="professors.jsp">Professors</a>
    <a href="compare.jsp">Compare</a>
    <a href="profile.jsp">Profile</a>
    <a href="profile.jsp">Login</a>
  </div>
</nav>

<div class="section">
  <h2>Meet Your Professors</h2>
  <div class="card-grid">
  <%
    try {
        Connection con = Db.get();

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery(
            "SELECT p.first_name, p.last_name,"
          + " AVG(r.quality_rating) AS avg_q, COUNT(r.review_id) AS n"
          + " FROM Professor p LEFT JOIN Review r ON r.professor_id = p.professor_id"
          + " GROUP BY p.professor_id ORDER BY p.last_name, p.first_name");

        while (rs.next()) {
            out.println("<div class='card'>");
            out.println("<span class='tag'>Professor</span>");
            out.println("<h3>" + rs.getString("first_name") + " " + rs.getString("last_name") + "</h3>");
            Object avg = rs.getObject("avg_q");
            if (avg == null) {
                out.println("<p>No ratings yet</p>");
            } else {
                out.println("<span class='rating'>&#9733; "
                    + String.format("%.1f", rs.getDouble("avg_q"))
                    + " (" + rs.getInt("n") + " reviews)</span>");
            }
            out.println("</div>");
        }
        rs.close();
        stmt.close();
        con.close();
    } catch (Exception e) {
        out.println("<div class='error'>Error: " + e.getMessage() + "</div>");
    }
  %>
  </div>
</div>

</body>
</html>