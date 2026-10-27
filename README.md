# CourseLane

Academic planning system for SJSU CS students — course search, prerequisite tracking, degree roadmaps, and professor review analytics.

## Tech Stack

- **Client:** HTML, CSS, JavaScript
- **Application:** Apache Tomcat, Java, JSP
- **Database:** MySQL Community Server

## Local Setup

1. **Install:** JDK 21, Apache Tomcat 10.1, MySQL Community Server, Eclipse IDE for Enterprise Java and Web Developers
2. **Database:** import `courselanedb_schema.sql` into your local MySQL server to create the `CourseLaneDB` database and seed sample data (full setup guide: `SETUP.md`):
   ```
   mysql -u root -p < courselanedb_schema.sql
   ```
   If you imported the schema before the `Student.major` column existed, also run:
   ```
   mysql -u root -p CourseLaneDB < student_major_migration.sql
   ```
3. **Eclipse:** import this project as a Dynamic Web Project, add the MySQL Connector/J jar to the build path (Build Path > Configure Build Path > Libraries > Add External JARs) — also copy it into Tomcat's `lib/` folder
4. **Credentials:** all code connects through `src/main/java/courselane/Db.java` (`localhost:3306 / CourseLaneDB`, `root / password`) — change the `DEFAULT_*` values there, or set `COURSELANE_DB_URL/USER/PASSWORD` env vars, to match your local MySQL setup
5. **Run:** right-click a `.jsp` file in `src/main/webapp` > Run As > Run on Server (Tomcat v10.1)

## Pages

- `home.jsp` — landing page, shows featured courses
- `courses.jsp` — course search (by number, name, department/subject)
- `course.jsp` — course detail: units, description, degree requirement, prerequisites + completion status
- `profile.jsp` — create/view/update academic profile (account, grad term, preferences, completed/enrolled)
- `professors.jsp` — professor directory with ratings
- `professor.jsp?id=N` — professor detail: courses, reviews, rating history by course and semester, rating trends by semester and year
