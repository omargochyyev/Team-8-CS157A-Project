<%@ page import="java.util.*, courselane.StudentProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%! String esc(String s) { return s == null ? "" : s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); } %>
<html>
<head>
  <title>Profile - CourseLane</title>
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
  <h2>Academic Profile (FR1)</h2>

<%
  String message = null, error = null;
  String idParam = request.getParameter("student_id");
  Integer currentId = null;
  try { if (idParam != null && !idParam.isBlank()) currentId = Integer.parseInt(idParam.trim()); }
  catch (NumberFormatException e) { error = "Invalid student id."; }

  if ("POST".equalsIgnoreCase(request.getMethod())) {
      String mode = request.getParameter("mode");
      String first = request.getParameter("first_name");
      String last = request.getParameter("last_name");
      String email = request.getParameter("email");
      String pw = request.getParameter("password");
      String major = request.getParameter("major");
      String prefRaw = request.getParameter("preferred_credits");
      String gradRaw = request.getParameter("grad");
      Integer pref = null, gradYear = null;
      String gradSem = null;
      try {
          if (prefRaw != null && !prefRaw.isBlank()) pref = Integer.parseInt(prefRaw.trim());
          if (gradRaw != null && !gradRaw.isBlank() && gradRaw.contains("|")) {
              String[] g = gradRaw.split("\\|");
              gradYear = Integer.parseInt(g[0]);
              gradSem = g[1];
          }
          if (first == null || first.isBlank() || last == null || last.isBlank()
                  || email == null || email.isBlank()) {
              throw new IllegalArgumentException("Name and email are required.");
          }
          if ("create".equals(mode) && (pw == null || pw.isBlank())) {
              throw new IllegalArgumentException("Password is required to create an account.");
          }
          if ("update".equals(mode)) {
              int uid = Integer.parseInt(request.getParameter("student_id"));
              StudentProfile.update(uid, first.trim(), last.trim(), email.trim(),
                  pw, major, pref, gradYear, gradSem);
              currentId = uid;
              message = "Profile updated for student #" + uid + ".";
          } else {
              int nid = StudentProfile.create(first.trim(), last.trim(), email.trim(),
                  pw, major, pref, gradYear, gradSem);
              currentId = nid;
              message = "Account created: student #" + nid + ".";
          }
      } catch (NumberFormatException nfe) {
          error = "Preferred credits and graduation term must be valid selections.";
      } catch (IllegalArgumentException iae) {
          error = iae.getMessage();
      } catch (Exception e) {
          error = "Save failed: " + e.getMessage();
      }
  }

  List<StudentProfile.Student> students = new ArrayList<>();
  List<String[]> terms = new ArrayList<>();
  StudentProfile.Student current = null;
  List<StudentProfile.Enrollment> history = new ArrayList<>();
  try {
      students = StudentProfile.listAll();
      terms = StudentProfile.listTerms();
      if (currentId != null) {
          current = StudentProfile.findById(currentId);
          if (current == null) { error = "Student #" + currentId + " not found."; currentId = null; }
          else history = StudentProfile.history(currentId);
      }
  } catch (Exception e) { error = "Error: " + e.getMessage(); }
%>

  <% if (message != null) { %><div class="alert ok"><%= esc(message) %></div><% } %>
  <% if (error != null) { %><div class="error"><%= esc(error) %></div><% } %>

  <form method="get" action="profile.jsp" class="form-row">
    <label>View student
      <select name="student_id">
        <option value="">-- create new account --</option>
        <% for (StudentProfile.Student s : students) { %>
          <option value="<%= s.id %>"<%= (currentId != null && currentId == s.id) ? " selected" : "" %>>
            <%= esc(s.firstName + " " + s.lastName + " (" + s.email + ")") %></option>
        <% } %>
      </select>
    </label>
    <button class="btn btn-secondary" type="submit">Open</button>
  </form>

  <div class="cols">
    <div class="card form-card">
      <h3><%= (current == null ? "Create account" : "Update profile (#" + current.id + ")") %></h3>
      <form method="post" action="profile.jsp">
        <input type="hidden" name="mode" value="<%= (current == null ? "create" : "update") %>">
        <% if (current != null) { %><input type="hidden" name="student_id" value="<%= current.id %>"><% } %>
        <label>First name<input name="first_name" required value="<%= esc(current == null ? request.getParameter("first_name") : current.firstName) %>"></label>
        <label>Last name<input name="last_name" required value="<%= esc(current == null ? request.getParameter("last_name") : current.lastName) %>"></label>
        <label>Email<input type="email" name="email" required value="<%= esc(current == null ? request.getParameter("email") : current.email) %>"></label>
        <label>Password <%= (current == null ? "(required)" : "(leave blank to keep current)") %>
          <input type="password" name="password" <%= (current == null ? "required" : "") %>></label>
        <label>Major<input name="major" value="<%= esc(current == null ? "Computer Science" : current.major) %>"></label>
        <label>Preferred credits / term
          <input type="number" name="preferred_credits" min="1" max="25"
            value="<%= (current != null && current.preferredCredits != null) ? current.preferredCredits : "" %>"></label>
        <label>Anticipated graduation term
          <select name="grad">
            <option value="">-- none --</option>
            <% for (String[] t : terms) {
                 String v = t[0] + "|" + t[1];
                 boolean sel = current != null && current.gradYear != null
                     && String.valueOf(current.gradYear).equals(t[0])
                     && t[1].equals(current.gradSemester);
            %>
              <option value="<%= v %>"<%= sel ? " selected" : "" %>><%= t[1] + " " + t[0] %></option>
            <% } %>
          </select>
        </label>
        <button class="btn btn-primary" type="submit"><%= (current == null ? "Create account" : "Save changes") %></button>
      </form>
    </div>

    <div class="card">
      <h3>Academic profile</h3>
      <% if (current == null) { %>
        <p class="muted">No student selected. Create an account or pick a student above.
        Completed / enrolled courses come from Takes records.</p>
      <% } else { %>
        <p><strong><%= esc(current.firstName + " " + current.lastName) %></strong><br>
        <%= esc(current.email) %> &middot; <%= esc(current.major) %></p>
        <p>Graduation: <%= (current.gradYear == null ? "not set" : esc(current.gradSemester + " " + current.gradYear)) %><br>
        Preferred credits/term: <%= (current.preferredCredits == null ? "not set" : current.preferredCredits) %></p>
        <h4>Completed</h4>
        <ul class="plain">
        <% boolean anyC = false; for (StudentProfile.Enrollment e : history) {
             if ("Completed".equalsIgnoreCase(e.status)) { anyC = true; %>
          <li><%= esc(e.subject + " " + e.number + " - " + e.title) %>
            <span class="muted">(<%= esc(e.semester + " " + e.year) %><%= e.grade != null ? ", grade " + esc(e.grade) : "" %>)</span></li>
        <% } } if (!anyC) { %><li class="muted">None recorded.</li><% } %>
        </ul>
        <h4>Enrolled / in progress</h4>
        <ul class="plain">
        <% boolean anyE = false; for (StudentProfile.Enrollment e : history) {
             if (!"Completed".equalsIgnoreCase(e.status)) { anyE = true; %>
          <li><%= esc(e.subject + " " + e.number + " - " + e.title) %>
            <span class="muted">(<%= esc(e.semester + " " + e.year + ", " + e.status) %>)</span></li>
        <% } } if (!anyE) { %><li class="muted">None recorded.</li><% } %>
        </ul>
      <% } %>
    </div>
  </div>
</div>

</body>
</html>
