<%@ page import="java.util.*, courselane.ProfessorProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  String q = request.getParameter("q");
  q = (q == null) ? "" : q.trim();
%>
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
  <form class="search" method="get" action="professors.jsp">
    <input type="text" name="q" value="<%= ProfessorProfile.esc(q) %>" placeholder="Search professors by name...">
    <button class="btn btn-primary" type="submit">Search</button>
    <% if (!q.isEmpty()) { %><a class="clear" href="professors.jsp">Clear</a><% } %>
  </form>
  <div class="card-grid">
  <%
  try {
      List<ProfessorProfile.Summary> list = ProfessorProfile.search(q);
      if (list.isEmpty()) {
          out.println("<div class='error'>No professors match \"" + ProfessorProfile.esc(q) + "\".</div>");
      }
      for (ProfessorProfile.Summary s : list) {
          out.println("<a class='card-link' href='professor.jsp?id=" + s.id + "'>");
          out.println("<div class='card'>");
          out.println("<h3>" + ProfessorProfile.esc(s.name) + "</h3>");
          if (s.reviewCount == 0) {
              out.println("<span class='rating'>No reviews</span>");
          } else {
              out.println("<span class='rating'>&#9733; " + ProfessorProfile.fmt(s.avgQuality) + "</span>");
              out.println("<p>" + s.reviewCount + " review" + (s.reviewCount == 1 ? "" : "s") + "</p>");
          }
          out.println("</div></a>");
      }
  } catch (Exception e) {
      out.println("<div class='error'>Error: " + ProfessorProfile.esc(e.getMessage()) + "</div>");
  }
%>
  </div>
</div>

</body>
</html>