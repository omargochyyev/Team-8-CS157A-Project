<%@ page import="java.util.*, courselane.CourseSearch, courselane.StudentProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%! String esc(String s) { return s == null ? "" : s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); } %>
<html>
<head>
  <title>Course Detail - CourseLane</title>
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
  <p><a href="courses.jsp">&larr; Back to search</a></p>

<%
  String subject = request.getParameter("subject");
  String number = request.getParameter("number");
  String sidRaw = request.getParameter("student_id");
  Integer sid = null;
  try { if (sidRaw != null && !sidRaw.isBlank()) sid = Integer.parseInt(sidRaw.trim()); }
  catch (NumberFormatException e) { sid = null; }

  CourseSearch.Course course = null;
  List<CourseSearch.Prereq> prereqs = new ArrayList<>();
  List<StudentProfile.Student> students = new ArrayList<>();
  String error = null;
  if (subject == null || number == null) {
      error = "Missing course. Pick one from Course Search.";
  } else {
      try {
          students = StudentProfile.listAll();
          course = CourseSearch.get(subject.trim(), number.trim());
          if (course == null) error = "Course " + subject + " " + number + " not found.";
          else prereqs = CourseSearch.prereqs(course.subject, course.number, sid);
      } catch (Exception e) { error = "Error: " + e.getMessage(); }
  }
  int met = 0;
  for (CourseSearch.Prereq p : prereqs) if (Boolean.TRUE.equals(p.met)) met++;
%>

  <% if (error != null) { %><div class="error"><%= esc(error) %></div><% } %>

  <% if (course != null) { %>
    <span class="tag"><%= esc(course.subject + " " + course.number) %></span>
    <h2 style="margin-top:8px"><%= esc(course.title) %></h2>
    <p class="muted"><%= course.units %> units &middot; Degree requirement: <%= esc(course.category == null ? "n/a" : course.category) %></p>
    <div class="card"><p><%= esc(course.description) %></p></div>

    <form method="get" action="course.jsp" class="form-row" style="margin-top:20px">
      <input type="hidden" name="subject" value="<%= esc(course.subject) %>">
      <input type="hidden" name="number" value="<%= esc(course.number) %>">
      <label>Check prerequisites for student
        <select name="student_id">
          <option value="">-- select --</option>
          <% for (StudentProfile.Student s : students) { %>
            <option value="<%= s.id %>"<%= (sid != null && sid == s.id) ? " selected" : "" %>>
              <%= esc(s.firstName + " " + s.lastName) %></option>
          <% } %>
        </select>
      </label>
      <button class="btn btn-secondary" type="submit">Check</button>
    </form>

    <h3>Prerequisites</h3>
    <% if (prereqs.isEmpty()) { %>
      <p class="muted">No prerequisites recorded for this course.</p>
    <% } else { %>
      <% if (sid == null) { %>
        <p class="muted">Select a student to see completion status.</p>
      <% } else if (met == prereqs.size()) { %>
        <div class="alert ok">Eligible: all <%= prereqs.size() %> prerequisite(s) completed.</div>
      <% } else { %>
        <div class="alert warn">Not yet eligible: <%= met %>/<%= prereqs.size() %> prerequisites completed.</div>
      <% } %>
      <div class="card-grid">
      <% for (CourseSearch.Prereq p : prereqs) { %>
        <div class="card">
          <span class="tag"><%= esc(p.subject + " " + p.number) %></span>
          <h3><%= esc(p.title) %></h3>
          <p>Minimum grade: <%= esc(p.minimumGrade == null ? "n/a" : p.minimumGrade) %></p>
          <% if (p.met == null) { %><span class="muted">completion unknown</span>
          <% } else if (p.met) { %><span class="rating">Completed</span>
          <% } else { %><span class="pill-warn">Not completed</span><% } %>
        </div>
      <% } %>
      </div>
    <% } %>
  <% } %>
</div>

</body>
</html>
