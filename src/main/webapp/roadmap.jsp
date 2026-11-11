<%@ page import="java.util.*, java.net.URLEncoder, java.nio.charset.StandardCharsets, courselane.Roadmap, courselane.CourseSearch, courselane.StudentProfile, courselane.ProfessorProfile" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
  String esc(String s) { return ProfessorProfile.esc(s); }

  String enc(String s) { return URLEncoder.encode(s == null ? "" : s, StandardCharsets.UTF_8); }

  String[] split2(String raw) {
      String[] p = raw == null ? new String[0] : raw.split("\\|");
      if (p.length != 2) throw new IllegalArgumentException("Invalid selection.");
      return p;
  }

  String termOptions(List<Roadmap.TermRow> terms, String selYear, String selSem) {
      StringBuilder sb = new StringBuilder();
      for (Roadmap.TermRow t : terms) {
          boolean sel = String.valueOf(t.year).equals(selYear) && t.semester.equals(selSem);
          sb.append("<option value=\"").append(t.year).append('|').append(esc(t.semester)).append('"')
            .append(sel ? " selected" : "").append('>').append(esc(t.label())).append("</option>");
      }
      return sb.toString();
  }
%>
<%
  request.setCharacterEncoding("UTF-8");

  Integer sid = null;
  try {
      String raw = request.getParameter("student_id");
      if (raw != null && !raw.isBlank()) sid = Integer.parseInt(raw.trim());
  } catch (NumberFormatException e) { sid = null; }

  String rname = request.getParameter("roadmap");
  rname = (rname == null || rname.trim().isEmpty()) ? null : rname.trim();

  //handle edits, then redirect so a refresh does not resubmit
  if ("POST".equalsIgnoreCase(request.getMethod()) && sid != null) {
      String action = request.getParameter("action");
      String nextMsg = null, nextErr = null, nextRoadmap = rname;
      try {
          if ("create".equals(action)) {
              Roadmap.create(sid, rname);
              nextMsg = "Created roadmap \"" + rname + "\".";
          } else if ("delete".equals(action)) {
              Roadmap.delete(sid, rname);
              nextMsg = "Deleted roadmap \"" + rname + "\".";
              nextRoadmap = null;
          } else if (rname == null) {
              throw new IllegalArgumentException("Pick a roadmap first.");
          } else if ("add".equals(action) || "move".equals(action)) {
              String[] c = split2(request.getParameter("course"));
              String[] t = split2(request.getParameter("term"));
              Roadmap.place(sid, rname, c[0], c[1], Integer.parseInt(t[0]), t[1]);
              int n = Roadmap.validate(sid, rname).issues.size();
              nextMsg = ("add".equals(action) ? "Saved " : "Moved ") + c[0] + " " + c[1] + " to " + t[1] + " " + t[0] + "."
                  + (n == 0 ? " No prerequisite problems." : " " + n + " warning(s) below.");
          } else if ("remove".equals(action)) {
              String[] c = split2(request.getParameter("course"));
              Roadmap.remove(sid, rname, c[0], c[1]);
              int n = Roadmap.validate(sid, rname).issues.size();
              nextMsg = "Removed " + c[0] + " " + c[1] + "."
                  + (n == 0 ? "" : " " + n + " warning(s) below.");
          } else if ("generate".equals(action)) {
              String[] t = split2(request.getParameter("start"));
              int cap = Integer.parseInt(request.getParameter("credits").trim());
              Roadmap.GenResult g = Roadmap.generate(sid, rname, cap, Integer.parseInt(t[0]), t[1]);
              nextMsg = "Generated " + g.placed + " course(s) across " + g.termsUsed + " term(s)."
                  + (g.unplaced.isEmpty() ? "" : " Could not place: " + String.join(", ", g.unplaced)
                      + " (blocked by prerequisites or offerings before graduation).");
          } else {
              throw new IllegalArgumentException("Unknown action.");
          }
      } catch (NumberFormatException nfe) {
          nextErr = "Enter a whole number of credits and pick a valid term.";
      } catch (IllegalArgumentException iae) {
          nextErr = iae.getMessage();
      } catch (Exception e) {
          nextErr = "Save failed: " + e.getMessage();
      }
      response.sendRedirect("roadmap.jsp?student_id=" + sid
          + (nextRoadmap != null ? "&roadmap=" + enc(nextRoadmap) : "")
          + (nextMsg != null ? "&msg=" + enc(nextMsg) : "")
          + (nextErr != null ? "&err=" + enc(nextErr) : ""));
      return;
  }

  //load data
  String message = request.getParameter("msg");
  String error = request.getParameter("err");

  List<StudentProfile.Student> students = new ArrayList<>();
  List<String> names = new ArrayList<>();
  List<Roadmap.TermRow> terms = new ArrayList<>();
  List<CourseSearch.Course> allCourses = new ArrayList<>();
  List<Roadmap.PlanItem> items = new ArrayList<>();
  Roadmap.Report report = new Roadmap.Report();
  StudentProfile.Student current = null;
  Roadmap.TermRow defStart = null;
  try {
      students = StudentProfile.listAll();
      terms = Roadmap.terms();
      defStart = Roadmap.defaultStart(terms);
      allCourses = CourseSearch.search(null);
      if (sid != null) {
          current = StudentProfile.findById(sid);
          if (current == null) { error = "Student #" + sid + " not found."; sid = null; }
      }
      if (sid != null) {
          names = Roadmap.listNames(sid);
          if (rname != null && !names.contains(rname)) rname = null;
          if (rname != null) {
              items = Roadmap.items(sid, rname);
              report = Roadmap.validate(sid, rname);
          }
      }
  } catch (Exception e) { error = "Error: " + e.getMessage(); }

  Map<Integer, Integer> unitsByTerm = new LinkedHashMap<>();
  int totalUnits = 0;
  for (Roadmap.PlanItem it : items) {
      unitsByTerm.merge(it.termKey(), it.units, Integer::sum);
      totalUnits += it.units;
  }
%>
<html>
<head>
  <title>Roadmap - CourseLane</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>

<nav class="topnav">
  <a class="brand" href="home.jsp">CourseLane</a>
  <div class="nav-links">
    <a href="home.jsp">Dashboard</a>
    <a href="courses.jsp">Course Search</a>
    <a href="roadmap.jsp">Roadmap</a>
    <a href="professors.jsp">Professors</a>
    <a href="compare.jsp">Compare</a>
    <a href="profile.jsp">Profile</a>
    <a href="profile.jsp">Login</a>
  </div>
</nav>

<div class="section">
  <h2>Academic Roadmap (FR3, FR5, FR6)</h2>
  <p class="muted">Plan courses term by term. Every change re-checks prerequisites across the whole
  roadmap, so moving or removing a course flags anything that depended on it.</p>

  <% if (message != null) { %><div class="alert ok"><%= esc(message) %></div><% } %>
  <% if (error != null) { %><div class="error"><%= esc(error) %></div><% } %>

  <form method="get" action="roadmap.jsp" class="form-row">
    <label>Student
      <select name="student_id" onchange="if (this.form.roadmap) this.form.roadmap.selectedIndex = 0; this.form.submit();">
        <option value="">-- select --</option>
        <% for (StudentProfile.Student s : students) { %>
          <option value="<%= s.id %>"<%= (sid != null && sid == s.id) ? " selected" : "" %>>
            <%= esc(s.firstName + " " + s.lastName) %></option>
        <% } %>
      </select>
    </label>
    <% if (sid != null) { %>
    <label>Roadmap
      <select name="roadmap">
        <option value="">-- choose --</option>
        <% for (String n : names) { %>
          <option value="<%= esc(n) %>"<%= n.equals(rname) ? " selected" : "" %>><%= esc(n) %></option>
        <% } %>
      </select>
    </label>
    <button class="btn btn-secondary" type="submit">Open</button>
    <% } %>
  </form>

<% if (sid == null) { %>
  <p class="muted">Pick a student to view or build a roadmap.</p>
<% } else { %>

  <p class="muted">
    Graduation: <%= (current.gradYear == null ? "not set" : esc(current.gradSemester + " " + current.gradYear)) %>
    &middot; Preferred credits/term: <%= (current.preferredCredits == null ? "not set" : current.preferredCredits) %>
  </p>

  <form method="post" action="roadmap.jsp" class="form-row">
    <input type="hidden" name="action" value="create">
    <input type="hidden" name="student_id" value="<%= sid %>">
    <label>New roadmap name <input name="roadmap" maxlength="50" placeholder="e.g. Main Plan" required></label>
    <button class="btn btn-primary" type="submit">Create roadmap</button>
  </form>

  <% if (names.isEmpty()) { %>
    <p class="muted">This student has no roadmaps yet. Create one above.</p>
  <% } else if (rname == null) { %>
    <p class="muted">Choose a roadmap to view it.</p>
  <% } else { %>

  <h3 class="sub"><%= esc(rname) %></h3>

  <div class="stats">
    <div class="stat"><div class="stat-num"><%= items.size() %></div><div class="stat-label">Planned courses</div></div>
    <div class="stat"><div class="stat-num"><%= totalUnits %></div><div class="stat-label">Planned units</div></div>
    <div class="stat"><div class="stat-num"><%= unitsByTerm.size() %></div><div class="stat-label">Terms used</div></div>
    <div class="stat"><div class="stat-num"><%= report.issues.size() %></div><div class="stat-label">Warnings</div></div>
  </div>

  <% if (!report.issues.isEmpty()) { %>
    <div class="alert warn">
      <strong><%= report.issues.size() %> warning(s)</strong>
      <ul class="warn-list">
        <% for (Roadmap.Issue i : report.issues) { %>
          <li><%= i.course == null ? "" : "<strong>" + esc(i.course) + "</strong>: " %><%= esc(i.message) %></li>
        <% } %>
      </ul>
    </div>
  <% } else if (!items.isEmpty()) { %>
    <div class="alert ok">No problems found: every planned course has its prerequisites in an earlier term.</div>
  <% } %>

  <% if (items.isEmpty()) { %>
    <p class="muted" style="margin-top:20px">This roadmap is empty. Add courses below or generate a plan.</p>
  <% } %>

  <%
    int lastKey = -1;
    for (Roadmap.PlanItem it : items) {
        if (it.termKey() != lastKey) {
            if (lastKey != -1) { %></ul></div><% }
            lastKey = it.termKey();
            List<String> termIssues = report.forTerm(lastKey);
  %>
    <div class="card term-card">
      <h3><%= esc(it.termLabel()) %> <span class="muted"><%= unitsByTerm.get(lastKey) %> units</span></h3>
      <% for (String m : termIssues) { %><div class="issue"><%= esc(m) %></div><% } %>
      <ul class="plain">
  <%  } %>
        <li class="plan-row">
          <div class="plan-main">
            <span class="tag"><%= esc(it.key()) %></span>
            <strong><%= esc(it.title) %></strong>
            <span class="muted"><%= it.units %> units</span>
            <% for (String m : report.forCourse(it.key())) { %><div class="issue"><%= esc(m) %></div><% } %>
          </div>
          <form method="post" action="roadmap.jsp" class="inline-form">
            <input type="hidden" name="action" value="move">
            <input type="hidden" name="student_id" value="<%= sid %>">
            <input type="hidden" name="roadmap" value="<%= esc(rname) %>">
            <input type="hidden" name="course" value="<%= esc(it.subject + "|" + it.number) %>">
            <select name="term"><%= termOptions(terms, String.valueOf(it.year), it.semester) %></select>
            <button class="btn btn-secondary btn-sm" type="submit">Move</button>
          </form>
          <form method="post" action="roadmap.jsp" class="inline-form">
            <input type="hidden" name="action" value="remove">
            <input type="hidden" name="student_id" value="<%= sid %>">
            <input type="hidden" name="roadmap" value="<%= esc(rname) %>">
            <input type="hidden" name="course" value="<%= esc(it.subject + "|" + it.number) %>">
            <button class="btn btn-danger btn-sm" type="submit">Remove</button>
          </form>
        </li>
  <% }
     if (lastKey != -1) { %></ul></div><% } %>

  <h3 class="sub">Add a course</h3>
  <form method="post" action="roadmap.jsp" class="form-row">
    <input type="hidden" name="action" value="add">
    <input type="hidden" name="student_id" value="<%= sid %>">
    <input type="hidden" name="roadmap" value="<%= esc(rname) %>">
    <label>Course
      <select name="course">
        <% for (CourseSearch.Course c : allCourses) { %>
          <option value="<%= esc(c.subject + "|" + c.number) %>"><%= esc(c.subject + " " + c.number + " - " + c.title) %> (<%= c.units %>u)</option>
        <% } %>
      </select>
    </label>
    <label>Term
      <select name="term"><%= termOptions(terms, defStart == null ? "" : String.valueOf(defStart.year), defStart == null ? "" : defStart.semester) %></select>
    </label>
    <button class="btn btn-primary" type="submit">Add to roadmap</button>
  </form>
  <p class="muted">Adding a course that is already in this roadmap moves it to the chosen term.</p>

  <h3 class="sub">Generate a plan</h3>
  <p class="muted">Fills the remaining Required courses (plus any prerequisites they need) into terms from the
  start term up to graduation, respecting prerequisites, published offerings and the credit limit.
  Electives are added manually. This replaces the courses currently in this roadmap.</p>
  <form method="post" action="roadmap.jsp" class="form-row"
        onsubmit="return <%= items.isEmpty() ? "true" : "confirm('Replace the current plan in this roadmap?')" %>;">
    <input type="hidden" name="action" value="generate">
    <input type="hidden" name="student_id" value="<%= sid %>">
    <input type="hidden" name="roadmap" value="<%= esc(rname) %>">
    <label>Credits per term
      <input type="number" name="credits" min="1" max="25"
             value="<%= current.preferredCredits != null ? current.preferredCredits : Roadmap.DEFAULT_CREDITS %>">
    </label>
    <label>Start term
      <select name="start"><%= termOptions(terms, defStart == null ? "" : String.valueOf(defStart.year), defStart == null ? "" : defStart.semester) %></select>
    </label>
    <button class="btn btn-primary" type="submit">Generate plan</button>
  </form>

  <h3 class="sub">Delete roadmap</h3>
  <form method="post" action="roadmap.jsp" onsubmit="return confirm('Delete this roadmap and all its planned courses?');">
    <input type="hidden" name="action" value="delete">
    <input type="hidden" name="student_id" value="<%= sid %>">
    <input type="hidden" name="roadmap" value="<%= esc(rname) %>">
    <button class="btn btn-danger" type="submit">Delete "<%= esc(rname) %>"</button>
  </form>

  <% } %>
<% } %>
</div>

</body>
</html>
