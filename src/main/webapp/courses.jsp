<%@ page import="java.util.*, courselane.CourseSearch, courselane.StudentProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%! String esc(String s) { return s == null ? "" : s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); } %>
<html>
<head>
  <title>Course Search - CourseLane</title>
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
  <h2>Course Search (FR2)</h2>
  <p class="muted">Search by course number, name, department / subject. Pick a student to see
  prerequisite completion against that student's Takes records.</p>

<%
  String q = request.getParameter("q");
  String sidRaw = request.getParameter("student_id");
  Integer sid = null;
  try { if (sidRaw != null && !sidRaw.isBlank()) sid = Integer.parseInt(sidRaw.trim()); }
  catch (NumberFormatException e) { sid = null; }

  List<CourseSearch.Course> results = new ArrayList<>();
  List<StudentProfile.Student> students = new ArrayList<>();
  Map<String, int[]> summary = new HashMap<>();
  String error = null;
  try {
      students = StudentProfile.listAll();
      results = CourseSearch.search(q);
      if (sid != null && !results.isEmpty()) summary = CourseSearch.completionSummary(sid, results);
  } catch (Exception e) { error = "Error: " + e.getMessage(); }
%>

  <form method="get" action="courses.jsp" class="form-row">
    <label>Search <input name="q" placeholder="e.g. 157A, Database, CS" value="<%= esc(q) %>"></label>
    <label>Student (for prereq check)
      <select name="student_id">
        <option value="">-- none --</option>
        <% for (StudentProfile.Student s : students) { %>
          <option value="<%= s.id %>"<%= (sid != null && sid == s.id) ? " selected" : "" %>>
            <%= esc(s.firstName + " " + s.lastName) %></option>
        <% } %>
      </select>
    </label>
    <button class="btn btn-primary" type="submit">Search</button>
  </form>

  <% if (error != null) { %><div class="error"><%= esc(error) %></div><% } %>

  <p class="muted"><%= results.size() %> course(s)<%= (q != null && !q.isBlank()) ? " for \"" + esc(q.trim()) + "\"" : "" %>.</p>

  <div class="card-grid">
  <% for (CourseSearch.Course c : results) {
       int[] sm = summary.get(c.subject + "|" + c.number);
       String link = "course.jsp?subject=" + c.subject + "&number=" + c.number
           + (sid != null ? "&student_id=" + sid : "");
  %>
    <div class="card">
      <span class="tag"><%= esc(c.subject + " " + c.number) %></span>
      <h3><a href="<%= link %>"><%= esc(c.title) %></a></h3>
      <p><%= c.units %> units &middot; <%= esc(c.category == null ? "" : c.category) %></p>
      <p><%= esc(c.description) %></p>
      <% if (sm != null) { %>
        <% if (sm[1] == 0) { %><span class="rating">No prerequisites</span>
        <% } else if (sm[0] == sm[1]) { %><span class="rating">Prereqs <%= sm[0] %>/<%= sm[1] %> met</span>
        <% } else { %><span class="pill-warn">Prereqs <%= sm[0] %>/<%= sm[1] %> met</span><% } %>
      <% } %>
    </div>
  <% } %>
  </div>
</div>

</body>
</html>
