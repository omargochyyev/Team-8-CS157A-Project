<%@ page import="java.util.*, courselane.ProfessorComparison" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<html>
<head>
  <title>Compare Professors - CourseLane</title>
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
    <a href="compare.jsp">Compare</a>
    <a href="#">Profile</a>
    <a href="#">Login</a>
  </div>
</nav>

<div class="section">
  <h2>Compare Professors</h2>
  <form method="get" action="compare.jsp">
    <select name="course">
    <%
      String selected = request.getParameter("course");
      try {
          for (String[] c : ProfessorComparison.listCourses()) {
              String value = c[0] + "|" + c[1];
              String isSelected = value.equals(selected) ? " selected" : "";
              out.println("<option value='" + value + "'" + isSelected + ">"
                  + c[0] + " " + c[1] + " - " + c[2] + "</option>");
          }
      } catch (Exception e) {
          out.println("<option>Error loading courses</option>");
      }
    %>
    </select>
    <button class="btn btn-primary" type="submit">Compare</button>
  </form>

  <div class="card-grid" style="margin-top:24px">
  <%
    if (selected != null && selected.contains("|")) {
        String[] parts = selected.split("\\|");
        try {
            List<ProfessorComparison.Row> rows = ProfessorComparison.compare(parts[0], parts[1]);
            if (rows.isEmpty()) {
                out.println("<div class='error'>No professors have taught this course.</div>");
            }
            for (ProfessorComparison.Row r : rows) {
                out.println("<div class='card'>");
                out.println("<h3>" + r.name + "</h3>");
                out.println("<p>Avg quality: " + (r.avgQuality == null ? "n/a" : r.avgQuality) + "</p>");
                out.println("<p>Avg difficulty: " + (r.avgDifficulty == null ? "n/a" : r.avgDifficulty) + "</p>");
                out.println("<p>Reviews: " + r.reviewCount + "</p>");
                out.println("<span class='rating'>" + r.trendLabel
                    + (r.trend == null ? "" : " (" + r.trend + ")") + "</span>");
                out.println("</div>");
            }
        } catch (Exception e) {
            out.println("<div class='error'>Error: " + e.getMessage() + "</div>");
        }
    }
  %>
  </div>
</div>

</body>
</html>