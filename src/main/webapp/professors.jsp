<%@ page import="java.sql.*"%>
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
    <a href="#">Course Search</a>
    <a href="#">Roadmap</a>
    <a href="professors.jsp">Professors</a>
    <a href="#">Profile</a>
    <a href="#">Login</a>
  </div>
</nav>

<div class="section">
  <h2>Meet Your Professors</h2>
  <div class="card-grid">
  <%
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/CourseLane?autoReconnect=true&useSSL=false",
            "root", "password");

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT * FROM Professors");

        while (rs.next()) {
            out.println("<div class='card'>");
            out.println("<span class='tag'>" + rs.getString("Department") + "</span>");
            out.println("<h3>" + rs.getString("Name") + "</h3>");
            out.println("<span class='rating'>&#9733; " + rs.getBigDecimal("AvgRating") + "</span>");
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