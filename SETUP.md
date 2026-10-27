# CourseLane — Teammate Setup

One-time setup to run the app locally (Eclipse + Tomcat + MySQL).

## 1. Install

- JDK 21, Apache Tomcat 10.1, MySQL Community Server 8.x
- Eclipse IDE for Enterprise Java and Web Developers
- MySQL Connector/J (`mysql-connector-j.jar`) — put it in Tomcat's `lib/` folder

## 2. Create the database

Fresh setup:

```
mysql -u root -p < courselanedb_schema.sql
```

This creates `CourseLaneDB` with all 10 tables and 10 sample rows each.

If you already imported `courselanedb_schema.sql` **before** the `Student.major`
column existed, run the additive migration (safe, keeps your data):

```
mysql -u root -p CourseLaneDB < student_major_migration.sql
```

## 3. Database credentials (one place)

The app connects to `localhost:3306 / CourseLaneDB` as `root / password`.
All Java code and JSPs go through `src/main/java/courselane/Db.java` — change
the `DEFAULT_*` values there if your MySQL password is different.

No code change needed if you prefer env vars (they win over the defaults):

```
COURSELANE_DB_URL=jdbc:mysql://localhost:3306/CourseLaneDB?autoReconnect=true&useSSL=false
COURSELANE_DB_USER=root
COURSELANE_DB_PASSWORD=password
```

Set them in the environment that launches Tomcat/Eclipse before starting it.

## 4. Run in Eclipse

The Eclipse project files (`.project`, `.classpath`, `.settings/`) are not
in git, so each teammate creates the project shell once, then drops the repo
files into it:

1. File > New > Dynamic Web Project, name it `CourseLane`, target runtime
   Tomcat v10.1, default config.
2. Copy the repo's `src/main/webapp/*` into the project's `WebContent/`
   folder and `src/main/java/*` into `Java Resources/src`.
3. Build path: add the MySQL Connector/J jar
   (Build Path > Configure Build Path > Libraries > Add External JARs).
4. Right-click a `.jsp` in `WebContent` > Run As > Run on Server (Tomcat v10.1).

## 5. Pages to try

- `home.jsp` — dashboard, featured courses (from `Course`)
- `courses.jsp` — FR2 course search; pick a student to see prereq completion
- `course.jsp` — FR2 course detail: units, description, degree requirement,
  prerequisites + eligibility for the selected student
- `profile.jsp` — FR1: create an account or open a student to view/update the
  academic profile (grad term, preferred credits, completed/enrolled from Takes)
- `professors.jsp`, `compare.jsp` — professor info and side-by-side comparison

Seed logins for testing (pick from the student dropdown, no password needed
for the demo): `maria.lopez@sjsu.edu`, `james.chen@sjsu.edu`, …

Example checks: student 1 (Maria, completed CS 146) is eligible for CS 157A
but not CS 157B; `courses.jsp?q=Database` returns 2 rows.

## 6. Troubleshooting

- `Communications link failure` — MySQL isn't running; start the server.
- `Access denied for user 'root'` — wrong password: fix `Db.java` or set
  `COURSELANE_DB_PASSWORD`.
- `Unknown database 'CourseLaneDB'` — step 2 wasn't run.
- `Unknown column 'major'` — run `student_major_migration.sql` (step 2).
- JSP driver errors — Connector/J jar missing from Tomcat `lib/`.
