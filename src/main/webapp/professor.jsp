<%@ page import="java.util.*, courselane.ProfessorProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  int profId = -1;
  try { profId = Integer.parseInt(request.getParameter("id")); } catch (Exception ignored) {}

  ProfessorProfile.Profile p = null;
  String error = null;
  try {
      p = ProfessorProfile.load(profId);
  } catch (Exception e) {
      error = e.getMessage();
  }
%>
<html>
<head>
  <title><%= p == null ? "Professor" : ProfessorProfile.esc(p.summary.name) %> - CourseLane</title>
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
  <a class="back" href="professors.jsp">&larr; All professors</a>

<% if (error != null) { %>
  <div class="error">Error: <%= ProfessorProfile.esc(error) %></div>
<% } else if (p == null) { %>
  <div class="error">Professor not found.</div>
<% } else {
     ProfessorProfile.Summary s = p.summary;
     String trendClass = "Improving".equals(p.trendLabel) ? "up"
                       : "Declining".equals(p.trendLabel) ? "down" : "flat";
     String trendNote = p.trend == null
         ? "needs 2+ semesters"
         : p.latestTermLabel + " vs earlier (" + (p.trend >= 0 ? "+" : "") + String.format("%.2f", p.trend) + ")";
%>

  <h2><%= ProfessorProfile.esc(s.name) %></h2>

  <div class="stats">
    <div class="stat"><div class="stat-num"><%= s.reviewCount == 0 ? "-" : ProfessorProfile.fmt(s.avgQuality) %></div><div class="stat-label">Avg quality</div></div>
    <div class="stat"><div class="stat-num"><%= s.reviewCount == 0 ? "-" : ProfessorProfile.fmt(s.avgDifficulty) %></div><div class="stat-label">Avg difficulty</div></div>
    <div class="stat"><div class="stat-num"><%= s.reviewCount %></div><div class="stat-label">Reviews</div></div>
    <div class="stat">
      <div class="stat-num"><span class="trend <%= trendClass %>"><%= ProfessorProfile.esc(p.trendLabel) %></span></div>
      <div class="stat-label">Recent trend: <%= ProfessorProfile.esc(trendNote) %></div>
    </div>
  </div>

  <% if (s.reviewCount == 0) { %>
    <p class="muted" style="margin-top:24px">No reviews yet for this professor.</p>
  <% } else { %>

  <h3 class="sub">Courses</h3>
  <div class="card-grid">
    <% for (ProfessorProfile.CourseStat c : p.courses) { %>
      <div class="card">
        <span class="tag"><%= ProfessorProfile.esc(c.course) %></span>
        <h3><%= ProfessorProfile.esc(c.title) %></h3>
        <span class="rating">&#9733; <%= ProfessorProfile.fmt(c.avgQuality) %></span>
        <p><%= c.reviewCount %> review<%= c.reviewCount == 1 ? "" : "s" %></p>
      </div>
    <% } %>
  </div>

  <h3 class="sub">Rating trend by semester</h3>
  <div class="bars">
    <% for (ProfessorProfile.TermStat t : p.byTerm) {
         double w = t.avgQuality == null ? 0 : t.avgQuality / 5.0 * 100; %>
      <div class="bar-row">
        <span class="bar-label"><%= ProfessorProfile.esc(t.label) %></span>
        <div class="bar-track"><div class="bar-fill" style="width:<%= String.format("%.0f", w) %>%"></div></div>
        <span class="bar-val"><%= ProfessorProfile.fmt(t.avgQuality) %> <small>(<%= t.reviewCount %>)</small></span>
      </div>
    <% } %>
  </div>

  <h3 class="sub">Rating trend by year</h3>
  <table class="data">
    <tr><th>Year</th><th>Reviews</th><th>Avg quality</th><th>Avg difficulty</th></tr>
    <% for (ProfessorProfile.TermStat y : p.byYear) { %>
      <tr><td><%= ProfessorProfile.esc(y.label) %></td><td><%= y.reviewCount %></td>
          <td><%= ProfessorProfile.fmt(y.avgQuality) %></td><td><%= ProfessorProfile.fmt(y.avgDifficulty) %></td></tr>
    <% } %>
  </table>

  <h3 class="sub">Rating history by course and semester</h3>
  <table class="data">
    <tr><th>Course</th><th>Semester</th><th>Reviews</th><th>Avg quality</th><th>Avg difficulty</th></tr>
    <% for (ProfessorProfile.TermStat h : p.history) { %>
      <tr><td><%= ProfessorProfile.esc(h.course) %></td><td><%= ProfessorProfile.esc(h.label) %></td><td><%= h.reviewCount %></td>
          <td><%= ProfessorProfile.fmt(h.avgQuality) %></td><td><%= ProfessorProfile.fmt(h.avgDifficulty) %></td></tr>
    <% } %>
  </table>

  <h3 class="sub">Reviews</h3>
  <% for (ProfessorProfile.ReviewItem r : p.reviews) { %>
    <div class="review">
      <div class="review-meta">
        <span class="tag"><%= ProfessorProfile.esc(r.course) %></span>
        <strong><%= ProfessorProfile.esc(r.term) %></strong>
        <span class="rating">&#9733; <%= ProfessorProfile.fmt(r.quality) %></span>
        <span class="muted">Difficulty <%= ProfessorProfile.fmt(r.difficulty) %>/5<%= r.date == null ? "" : " &middot; " + r.date %></span>
      </div>
      <p><%= ProfessorProfile.esc(r.text) %></p>
    </div>
  <% } %>

  <% } %>
<% } %>
</div>

</body>
</html>
