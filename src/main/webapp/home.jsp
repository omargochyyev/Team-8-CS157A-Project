<%@ page import="java.sql.*, courselane.Db" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<html>
<head>
  <title>CourseLane</title>
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

<div class="hero">
  <h1>Plan smarter.</h1>
  <p>Track requirements, plan your roadmap, and find the right professors all in one place.</p>
  <a class="btn btn-primary" href="#">Get Started</a>
  <a class="btn btn-secondary" href="professors.jsp">View Professors</a>
</div>

<div class="section">
  <h2>Featured Courses</h2>
  <div class="card-grid">
  <%
    try {
        Connection con = Db.get();

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery(
            "SELECT subject_code, course_number, title, units FROM Course ORDER BY 1, 2 LIMIT 6");

        while (rs.next()) {
            out.println("<div class='card'>");
            out.println("<span class='tag'>" + rs.getString("subject_code") + " " + rs.getString("course_number") + "</span>");
            out.println("<h3>" + rs.getString("title") + "</h3>");
            out.println("<p>" + rs.getInt("units") + " units</p>");
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