<%@ page import="java.sql.*"%>
<html>
<head>
  <title>Professors - CourseLane</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    nav a { margin-right: 15px; }
    table { border-collapse: collapse; margin-top: 20px; }
    td, th { border: 1px solid #ccc; padding: 8px 12px; }
  </style>
</head>
<body>

<h1>CourseLane</h1>
<nav>
  <a href="home.jsp">Dashboard</a>
  <a href="#">Course Search</a>
  <a href="#">Roadmap</a>
  <a href="professors.jsp">Professors</a>
  <a href="#">Profile</a>
  <a href="#">Login</a>
</nav>

<h2>Professors</h2>
<table>
  <tr><th>Name</th><th>Department</th><th>Avg Rating</th></tr>
  <%
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/CourseLane?autoReconnect=true&useSSL=false",
            "root", "password");

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT * FROM Professors");

        while (rs.next()) {
            out.println("<tr><td>" + rs.getString("Name") + "</td><td>" + rs.getString("Department") + "</td><td>" + rs.getBigDecimal("AvgRating") + "</td></tr>");
        }
        rs.close();
        stmt.close();
        con.close();
    } catch (Exception e) {
        out.println("<tr><td colspan='3'>Error: " + e.getMessage() + "</td></tr>");
    }
  %>
</table>

</body>
</html>