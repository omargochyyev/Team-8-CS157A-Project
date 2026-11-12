package courselane;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringJoiner;

// Functional requirements 3, 5 and 6: saved roadmaps (Roadmap + Plans tables),

public class Roadmap {

    public static final int DEFAULT_CREDITS = 15;

    //public data classes

    public static class TermRow {
        public int year;
        public String semester;
        public Date startDate;

        public int key() { return termKey(year, semester); }
        public String label() { return semester + " " + year; }
    }

    public static class PlanItem {
        public String subject;
        public String number;
        public String title;
        public int units;
        public int year;
        public String semester;

        public String key() { return subject + " " + number; }
        public int termKey() { return Roadmap.termKey(year, semester); }
        public String termLabel() { return semester + " " + year; }
    }

    //one problem found in a roadmap. course == null means issue is about the whole term
    public static class Issue {
        public String course;
        public int termKey;
        public String message;
    }

    public static class Report {
        public List<Issue> issues = new ArrayList<>();

        void add(String course, int termKey, String message) {
            Issue i = new Issue();
            i.course = course;
            i.termKey = termKey;
            i.message = message;
            issues.add(i);
        }

        public List<String> forCourse(String courseKey) {
            List<String> out = new ArrayList<>();
            for (Issue i : issues) {
                if (courseKey.equals(i.course)) out.add(i.message);
            }
            return out;
        }

        public List<String> forTerm(int termKey) {
            List<String> out = new ArrayList<>();
            for (Issue i : issues) {
                if (i.course == null && i.termKey == termKey) out.add(i.message);
            }
            return out;
        }
    }

    public static class GenResult {
        public int placed;
        public int termsUsed;
        public List<String> unplaced = new ArrayList<>();
    }

    //helpers

    private static class Req {
        String subj;
        String num;
        String minGrade;
        Integer group;

        String key() { return subj + " " + num; }

        String describe() {
            return key() + (minGrade == null || minGrade.isBlank() ? "" : " (min grade " + minGrade + ")");
        }
    }

    private static class Taken {
        String key;
        int termKey;
        String label;
        String status;
        String grade;
    }

    private static int semOrder(String semester) {
        if ("Spring".equalsIgnoreCase(semester)) return 1;
        if ("Summer".equalsIgnoreCase(semester)) return 2;
        if ("Fall".equalsIgnoreCase(semester)) return 3;
        return 0;
    }

    //larger key = later term
    public static int termKey(int year, String semester) {
        return year * 10 + semOrder(semester);
    }

    private static String key(String subject, String number) {
        return subject + " " + number;
    }

    private static boolean exists(Connection con, int studentId, String name) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT 1 FROM Roadmap WHERE student_id = ? AND roadmap_name = ?")) {
            ps.setInt(1, studentId);
            ps.setString(2, name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static void requireRoadmap(Connection con, int studentId, String name) throws SQLException {
        if (name == null || !exists(con, studentId, name)) {
            throw new IllegalArgumentException("Roadmap not found.");
        }
    }

    private static List<TermRow> loadTerms(Connection con) throws SQLException {
        List<TermRow> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                 "SELECT year, semester, start_date FROM Term");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                TermRow t = new TermRow();
                t.year = rs.getInt(1);
                t.semester = rs.getString(2);
                t.startDate = rs.getDate(3);
                out.add(t);
            }
        }
        out.sort(Comparator.comparingInt(TermRow::key));
        return out;
    }

    private static Map<String, CourseSearch.Course> loadCourses(Connection con) throws SQLException {
        Map<String, CourseSearch.Course> out = new LinkedHashMap<>();
        try (PreparedStatement ps = con.prepareStatement(
                 "SELECT subject_code, course_number, title, units, description, requirement_category"
               + " FROM Course ORDER BY subject_code, course_number");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                CourseSearch.Course c = new CourseSearch.Course();
                c.subject = rs.getString(1);
                c.number = rs.getString(2);
                c.title = rs.getString(3);
                c.units = rs.getInt(4);
                c.description = rs.getString(5);
                c.category = rs.getString(6);
                out.put(key(c.subject, c.number), c);
            }
        }
        return out;
    }

    private static Map<String, List<Req>> loadRequires(Connection con) throws SQLException {
        Map<String, List<Req>> out = new HashMap<>();
        try (PreparedStatement ps = con.prepareStatement(
                 "SELECT subject_code, course_number, prereq_subject_code, prereq_course_number,"
               + " minimum_grade, alternative_group FROM Requires");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Req r = new Req();
                r.subj = rs.getString(3);
                r.num = rs.getString(4);
                r.minGrade = rs.getString(5);
                int g = rs.getInt(6);
                r.group = rs.wasNull() ? null : g;
                out.computeIfAbsent(key(rs.getString(1), rs.getString(2)), k -> new ArrayList<>()).add(r);
            }
        }
        return out;
    }

    private static List<Taken> loadHistory(Connection con, int studentId) throws SQLException {
        List<Taken> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT subject_code, course_number, year, semester, status, grade"
              + " FROM Takes WHERE student_id = ?")) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Taken t = new Taken();
                    t.key = key(rs.getString(1), rs.getString(2));
                    t.termKey = termKey(rs.getInt(3), rs.getString(4));
                    t.label = rs.getString(4) + " " + rs.getInt(3);
                    t.status = rs.getString(5);
                    t.grade = rs.getString(6);
                    out.add(t);
                }
            }
        }
        return out;
    }

    //termKey -> courses with a published Section that term. terms with no Sections are absent
    private static Map<Integer, Set<String>> loadOfferings(Connection con) throws SQLException {
        Map<Integer, Set<String>> out = new HashMap<>();
        try (PreparedStatement ps = con.prepareStatement(
                 "SELECT DISTINCT subject_code, course_number, year, semester FROM Section");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                out.computeIfAbsent(termKey(rs.getInt(3), rs.getString(4)), k -> new HashSet<>())
                   .add(key(rs.getString(1), rs.getString(2)));
            }
        }
        return out;
    }

    private static List<PlanItem> loadItems(Connection con, int studentId, String name) throws SQLException {
        List<PlanItem> out = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT p.subject_code, p.course_number, c.title, c.units, p.year, p.semester"
              + " FROM Plans p JOIN Course c"
              + " ON c.subject_code = p.subject_code AND c.course_number = p.course_number"
              + " WHERE p.student_id = ? AND p.roadmap_name = ?")) {
            ps.setInt(1, studentId);
            ps.setString(2, name);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PlanItem it = new PlanItem();
                    it.subject = rs.getString(1);
                    it.number = rs.getString(2);
                    it.title = rs.getString(3);
                    it.units = rs.getInt(4);
                    it.year = rs.getInt(5);
                    it.semester = rs.getString(6);
                    out.add(it);
                }
            }
        }
        out.sort(Comparator.comparingInt(PlanItem::termKey).thenComparing(PlanItem::key));
        return out;
    }

    //prereq logic

    private static boolean satisfied(Req r, int targetKey, List<Taken> history, Map<String, Integer> planned) {
        String k = r.key();
        for (Taken t : history) {
            if (!t.key.equals(k) || t.termKey >= targetKey) continue;
            if ("Completed".equalsIgnoreCase(t.status) && CourseSearch.gradePasses(t.grade, r.minGrade)) {
                return true;
            }
            if ("In Progress".equalsIgnoreCase(t.status)) {
                return true;   // assume current enrolled will be passed
            }
        }
        Integer p = planned.get(k);
        return p != null && p < targetKey;
    }

    //descriptions of prerequisites that are not met before targetKey. Empty = eligible
    private static List<String> unmetPrereqs(List<Req> reqs, int targetKey,
            List<Taken> history, Map<String, Integer> planned) {
        List<String> out = new ArrayList<>();
        if (reqs == null) return out;

        Map<Integer, List<Req>> groups = new LinkedHashMap<>();
        for (Req r : reqs) {
            if (r.group == null) {
                if (!satisfied(r, targetKey, history, planned)) out.add(r.describe());
            } else {
                groups.computeIfAbsent(r.group, g -> new ArrayList<>()).add(r);
            }
        }
        for (List<Req> g : groups.values()) {
            boolean ok = false;
            for (Req r : g) {
                if (satisfied(r, targetKey, history, planned)) { ok = true; break; }
            }
            if (!ok) {
                StringJoiner sj = new StringJoiner(" or ");
                for (Req r : g) sj.add(r.describe());
                out.add("one of " + sj);
            }
        }
        return out;
    }

    //reading

    public static List<String> listNames(int studentId) throws SQLException {
        List<String> out = new ArrayList<>();
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT roadmap_name FROM Roadmap WHERE student_id = ? ORDER BY roadmap_name")) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(rs.getString(1));
            }
        }
        return out;
    }

    //all terms
    public static List<TermRow> terms() throws SQLException {
        try (Connection con = Db.get()) {
            return loadTerms(con);
        }
    }

    //first term that starts after today; falls back to the last term in the table. */
    public static TermRow defaultStart(List<TermRow> terms) {
        LocalDate today = LocalDate.now();
        for (TermRow t : terms) {
            if (t.startDate != null && t.startDate.toLocalDate().isAfter(today)) return t;
        }
        return terms.isEmpty() ? null : terms.get(terms.size() - 1);
    }

    //planned courses
    public static List<PlanItem> items(int studentId, String name) throws SQLException {
        try (Connection con = Db.get()) {
            return loadItems(con, studentId, name);
        }
    }

    //validation

    public static Report validate(int studentId, String name) throws SQLException {
        try (Connection con = Db.get()) {
            return check(con, studentId, loadItems(con, studentId, name));
        }
    }

    private static Report check(Connection con, int studentId, List<PlanItem> items) throws SQLException {
        Report rep = new Report();
        if (items.isEmpty()) return rep;

        Map<String, List<Req>> reqs = loadRequires(con);
        List<Taken> history = loadHistory(con, studentId);
        Map<Integer, Set<String>> offered = loadOfferings(con);
        StudentProfile.Student st = StudentProfile.findById(studentId);
        int gradKey = (st != null && st.gradYear != null && st.gradSemester != null)
            ? termKey(st.gradYear, st.gradSemester) : Integer.MAX_VALUE;

        Map<String, Integer> planned = new HashMap<>();
        for (PlanItem it : items) planned.put(it.key(), it.termKey());

        Map<Integer, Integer> unitsByTerm = new LinkedHashMap<>();
        Map<Integer, String> labels = new HashMap<>();

        for (PlanItem it : items) {
            int tk = it.termKey();
            unitsByTerm.merge(tk, it.units, Integer::sum);
            labels.put(tk, it.termLabel());

            for (Taken t : history) {
                if (!t.key.equals(it.key())) continue;
                if ("Completed".equalsIgnoreCase(t.status)) {
                    rep.add(it.key(), tk, "Already completed in " + t.label
                        + (t.grade == null ? "" : " (grade " + t.grade + ")") + ".");
                    break;
                }
                if ("In Progress".equalsIgnoreCase(t.status)) {
                    rep.add(it.key(), tk, "Already enrolled in " + t.label + ".");
                    break;
                }
            }

            for (String need : unmetPrereqs(reqs.get(it.key()), tk, history, planned)) {
                rep.add(it.key(), tk, "Prerequisite not met before " + it.termLabel() + ": " + need + ".");
            }

            Set<String> off = offered.get(tk);
            if (off != null && !off.contains(it.key())) {
                rep.add(it.key(), tk, "No section published for " + it.termLabel() + ".");
            }

            if (tk > gradKey) {
                rep.add(it.key(), tk, "Scheduled after your anticipated graduation ("
                    + st.gradSemester + " " + st.gradYear + ").");
            }
        }

        if (st != null && st.preferredCredits != null) {
            for (Map.Entry<Integer, Integer> e : unitsByTerm.entrySet()) {
                if (e.getValue() > st.preferredCredits) {
                    rep.add(null, e.getKey(), labels.get(e.getKey()) + " has " + e.getValue()
                        + " units, over your preferred " + st.preferredCredits + ".");
                }
            }
        }
        return rep;
    }

    //roadmap CRUD

    public static void create(int studentId, String name) throws SQLException {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Roadmap name is required.");
        }
        name = name.trim();
        if (name.length() > 50) {
            throw new IllegalArgumentException("Roadmap name must be 50 characters or fewer.");
        }
        if (StudentProfile.findById(studentId) == null) {
            throw new IllegalArgumentException("Student #" + studentId + " not found.");
        }
        try (Connection con = Db.get()) {
            if (exists(con, studentId, name)) {
                throw new IllegalArgumentException("You already have a roadmap named \"" + name + "\".");
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO Roadmap (student_id, roadmap_name) VALUES (?, ?)")) {
                ps.setInt(1, studentId);
                ps.setString(2, name);
                ps.executeUpdate();
            }
        }
    }

    public static void delete(int studentId, String name) throws SQLException {
        try (Connection con = Db.get()) {
            requireRoadmap(con, studentId, name);
            con.setAutoCommit(false);
            try {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM Plans WHERE student_id = ? AND roadmap_name = ?")) {
                    ps.setInt(1, studentId);
                    ps.setString(2, name);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM Roadmap WHERE student_id = ? AND roadmap_name = ?")) {
                    ps.setInt(1, studentId);
                    ps.setString(2, name);
                    ps.executeUpdate();
                }
                con.commit();
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        }
    }

    //adds the course to the roadmap in the given term, or moves it if it is already there
    public static void place(int studentId, String name, String subject, String number,
            int year, String semester) throws SQLException {
        try (Connection con = Db.get()) {
            requireRoadmap(con, studentId, name);
            if (CourseSearch.get(subject, number) == null) {
                throw new IllegalArgumentException("Course " + subject + " " + number + " not found.");
            }
            boolean termOk = false;
            for (TermRow t : loadTerms(con)) {
                if (t.year == year && t.semester.equals(semester)) { termOk = true; break; }
            }
            if (!termOk) {
                throw new IllegalArgumentException("Term " + semester + " " + year + " not found.");
            }

            int updated;
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE Plans SET year = ?, semester = ?"
                  + " WHERE student_id = ? AND roadmap_name = ? AND subject_code = ? AND course_number = ?")) {
                ps.setInt(1, year);
                ps.setString(2, semester);
                ps.setInt(3, studentId);
                ps.setString(4, name);
                ps.setString(5, subject);
                ps.setString(6, number);
                updated = ps.executeUpdate();
            }
            if (updated == 0) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO Plans (student_id, roadmap_name, subject_code, course_number, year, semester)"
                      + " VALUES (?, ?, ?, ?, ?, ?)")) {
                    ps.setInt(1, studentId);
                    ps.setString(2, name);
                    ps.setString(3, subject);
                    ps.setString(4, number);
                    ps.setInt(5, year);
                    ps.setString(6, semester);
                    ps.executeUpdate();
                }
            }
        }
    }

    public static void remove(int studentId, String name, String subject, String number) throws SQLException {
        try (Connection con = Db.get();
             PreparedStatement ps = con.prepareStatement(
                 "DELETE FROM Plans WHERE student_id = ? AND roadmap_name = ?"
               + " AND subject_code = ? AND course_number = ?")) {
            ps.setInt(1, studentId);
            ps.setString(2, name);
            ps.setString(3, subject);
            ps.setString(4, number);
            ps.executeUpdate();
        }
    }

    //roadmap generation
    public static GenResult generate(int studentId, String name, int creditsPerTerm,
            int startYear, String startSemester) throws SQLException {
        if (creditsPerTerm < 1) {
            throw new IllegalArgumentException("Credits per term must be at least 1.");
        }
        try (Connection con = Db.get()) {
            requireRoadmap(con, studentId, name);
            StudentProfile.Student st = StudentProfile.findById(studentId);
            Map<String, CourseSearch.Course> courses = loadCourses(con);
            Map<String, List<Req>> reqs = loadRequires(con);
            List<Taken> history = loadHistory(con, studentId);
            Map<Integer, Set<String>> offered = loadOfferings(con);

            int startKey = termKey(startYear, startSemester);
            int gradKey = (st != null && st.gradYear != null && st.gradSemester != null)
                ? termKey(st.gradYear, st.gradSemester) : Integer.MAX_VALUE;
            List<TermRow> terms = new ArrayList<>();
            for (TermRow t : loadTerms(con)) {
                if (t.key() >= startKey && t.key() <= gradKey) terms.add(t);
            }
            if (terms.isEmpty()) {
                throw new IllegalArgumentException("No terms between " + startSemester + " " + startYear
                    + " and your graduation term. Pick an earlier start or a later graduation term.");
            }

            //courses student already completed or is taking
            Set<String> taken = new HashSet<>();
            for (Taken t : history) {
                if ("Completed".equalsIgnoreCase(t.status) || "In Progress".equalsIgnoreCase(t.status)) {
                    taken.add(t.key);
                }
            }

            //candidates: remaining Required courses, then pull in missing prerequisites
            Set<String> cand = new LinkedHashSet<>();
            for (Map.Entry<String, CourseSearch.Course> e : courses.entrySet()) {
                if ("Required".equalsIgnoreCase(e.getValue().category) && !taken.contains(e.getKey())) {
                    cand.add(e.getKey());
                }
            }
            List<String> work = new ArrayList<>(cand);
            while (!work.isEmpty()) {
                String k = work.remove(work.size() - 1);
                List<Req> rs = reqs.get(k);
                if (rs == null) continue;
                Map<Integer, List<Req>> groups = new LinkedHashMap<>();
                for (Req r : rs) {
                    if (r.group != null) {
                        groups.computeIfAbsent(r.group, g -> new ArrayList<>()).add(r);
                    } else if (!taken.contains(r.key()) && courses.containsKey(r.key()) && cand.add(r.key())) {
                        work.add(r.key());
                    }
                }
                for (List<Req> g : groups.values()) {
                    boolean covered = false;
                    for (Req r : g) {
                        if (taken.contains(r.key()) || cand.contains(r.key())) { covered = true; break; }
                    }
                    if (!covered && courses.containsKey(g.get(0).key()) && cand.add(g.get(0).key())) {
                        work.add(g.get(0).key());
                    }
                }
            }

            //courses that unlock the most others are scheduled first
            Map<String, Integer> unlocks = new HashMap<>();
            for (String k : cand) {
                List<Req> rs = reqs.get(k);
                if (rs == null) continue;
                for (Req r : rs) unlocks.merge(r.key(), 1, Integer::sum);
            }
            List<String> order = new ArrayList<>(cand);
            order.sort((a, b) -> {
                int cmp = Integer.compare(unlocks.getOrDefault(b, 0), unlocks.getOrDefault(a, 0));
                return cmp != 0 ? cmp : a.compareTo(b);
            });

            //greedy term-by-term placement
            Map<String, Integer> planned = new HashMap<>();
            List<Object[]> placements = new ArrayList<>();   // {courseKey, TermRow}
            Set<String> remaining = new LinkedHashSet<>(order);
            int termsUsed = 0;

            for (TermRow t : terms) {
                Set<String> off = offered.get(t.key());
                List<String> picks = new ArrayList<>();
                int units = 0;
                for (String k : remaining) {
                    CourseSearch.Course c = courses.get(k);
                    if (off != null && !off.contains(k)) continue;
                    if (!unmetPrereqs(reqs.get(k), t.key(), history, planned).isEmpty()) continue;
                    if (units + c.units > creditsPerTerm) continue;
                    picks.add(k);
                    units += c.units;
                }
                if (!picks.isEmpty()) termsUsed++;
                for (String k : picks) {
                    planned.put(k, t.key());
                    remaining.remove(k);
                    placements.add(new Object[] { k, t });
                }
            }

            //save, replacing old plan
            con.setAutoCommit(false);
            try {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM Plans WHERE student_id = ? AND roadmap_name = ?")) {
                    ps.setInt(1, studentId);
                    ps.setString(2, name);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO Plans (student_id, roadmap_name, subject_code, course_number, year, semester)"
                      + " VALUES (?, ?, ?, ?, ?, ?)")) {
                    for (Object[] p : placements) {
                        CourseSearch.Course c = courses.get((String) p[0]);
                        TermRow t = (TermRow) p[1];
                        ps.setInt(1, studentId);
                        ps.setString(2, name);
                        ps.setString(3, c.subject);
                        ps.setString(4, c.number);
                        ps.setInt(5, t.year);
                        ps.setString(6, t.semester);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                con.commit();
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }

            GenResult res = new GenResult();
            res.placed = placements.size();
            res.termsUsed = termsUsed;
            res.unplaced.addAll(remaining);
            return res;
        }
    }
}
