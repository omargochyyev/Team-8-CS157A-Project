<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    <a href="#">Course Search</a>
    <a href="#">Roadmap</a>
    <a href="professors.jsp">Professors</a>
    <a href="#">Profile</a>
    <a href="#">Login</a>
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
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/CourseLane?autoReconnect=true&useSSL=false",
            "root", "password");

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT * FROM Courses");

        while (rs.next()) {
            out.println("<div class='card'>");
            out.println("<span class='tag'>" + rs.getString("CourseNum") + "</span>");
            out.println("<h3>" + rs.getString("Title") + "</h3>");
            out.println("<p>" + rs.getInt("Units") + " units</p>");
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