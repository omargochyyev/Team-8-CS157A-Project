# CourseLane

Academic planning system for SJSU CS students — course search, prerequisite tracking, degree roadmaps, and professor review analytics.

## Tech Stack

- **Client:** HTML, CSS, JavaScript
- **Application:** Apache Tomcat, Java, JSP
- **Database:** MySQL Community Server

## Local Setup

1. **Install:** JDK 21, Apache Tomcat 10.1, MySQL Community Server, Eclipse IDE for Enterprise Java and Web Developers
2. **Database:** import `schema.sql` into your local MySQL server to create the `CourseLane` database and seed sample data:
   ```
   mysql -u root -p < schema.sql
   ```
3. **Eclipse:** import this project as a Dynamic Web Project, add the MySQL Connector/J jar to the build path (Build Path > Configure Build Path > Libraries > Add External JARs)
4. **Credentials:** the JSP files currently connect with `root` / `password` — update these in each `.jsp` file to match your local MySQL root password
5. **Run:** right-click a `.jsp` file in `src/main/webapp` > Run As > Run on Server (Tomcat v10.1)

## Pages

- `home.jsp` — landing page, shows featured courses
- `professors.jsp` — professor directory with ratings
