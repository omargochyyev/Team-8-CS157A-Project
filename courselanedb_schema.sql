-- CourseLaneDB: full 10-table schema with 10 sample rows per table.
-- Run against a local MySQL server. Drops and recreates CourseLaneDB.

DROP DATABASE IF EXISTS CourseLaneDB;
CREATE DATABASE CourseLaneDB;
USE CourseLaneDB;

CREATE TABLE Term (
    year INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    start_date DATE,
    end_date DATE,
    PRIMARY KEY (year, semester)
);

CREATE TABLE Course (
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    title VARCHAR(100) NOT NULL,
    units INT NOT NULL,
    description TEXT,
    requirement_category VARCHAR(30),
    PRIMARY KEY (subject_code, course_number)
);

CREATE TABLE Professor (
    professor_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (professor_id)
);

CREATE TABLE Student (
    student_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    preferred_credits_per_term INT,
    grad_year INT,
    grad_semester VARCHAR(10),
    PRIMARY KEY (student_id),
    FOREIGN KEY (grad_year, grad_semester) REFERENCES Term(year, semester)
);

CREATE TABLE Roadmap (
    student_id INT NOT NULL,
    roadmap_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (student_id, roadmap_name),
    FOREIGN KEY (student_id) REFERENCES Student(student_id)
);

CREATE TABLE Section (
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    section_number VARCHAR(5) NOT NULL,
    professor_id INT NOT NULL,
    PRIMARY KEY (subject_code, course_number, year, semester, section_number),
    FOREIGN KEY (subject_code, course_number) REFERENCES Course(subject_code, course_number),
    FOREIGN KEY (year, semester) REFERENCES Term(year, semester),
    FOREIGN KEY (professor_id) REFERENCES Professor(professor_id)
);

CREATE TABLE Review (
    review_id INT NOT NULL AUTO_INCREMENT,
    professor_id INT NOT NULL,
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    quality_rating DECIMAL(2,1),
    difficulty_rating DECIMAL(2,1),
    review_text TEXT,
    review_date DATE,
    PRIMARY KEY (review_id),
    FOREIGN KEY (professor_id) REFERENCES Professor(professor_id),
    FOREIGN KEY (subject_code, course_number) REFERENCES Course(subject_code, course_number),
    FOREIGN KEY (year, semester) REFERENCES Term(year, semester)
);

CREATE TABLE Takes (
    student_id INT NOT NULL,
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    section_number VARCHAR(5) NOT NULL,
    status VARCHAR(20),
    grade VARCHAR(5),
    PRIMARY KEY (student_id, subject_code, course_number, year, semester, section_number),
    FOREIGN KEY (student_id) REFERENCES Student(student_id),
    FOREIGN KEY (subject_code, course_number, year, semester, section_number)
        REFERENCES Section(subject_code, course_number, year, semester, section_number)
);

CREATE TABLE Requires (
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    prereq_subject_code VARCHAR(10) NOT NULL,
    prereq_course_number VARCHAR(10) NOT NULL,
    minimum_grade VARCHAR(5),
    alternative_group INT,
    PRIMARY KEY (subject_code, course_number, prereq_subject_code, prereq_course_number),
    FOREIGN KEY (subject_code, course_number) REFERENCES Course(subject_code, course_number),
    FOREIGN KEY (prereq_subject_code, prereq_course_number) REFERENCES Course(subject_code, course_number)
);

CREATE TABLE Plans (
    student_id INT NOT NULL,
    roadmap_name VARCHAR(50) NOT NULL,
    subject_code VARCHAR(10) NOT NULL,
    course_number VARCHAR(10) NOT NULL,
    year INT NOT NULL,
    semester VARCHAR(10) NOT NULL,
    PRIMARY KEY (student_id, roadmap_name, subject_code, course_number),
    FOREIGN KEY (student_id, roadmap_name) REFERENCES Roadmap(student_id, roadmap_name),
    FOREIGN KEY (subject_code, course_number) REFERENCES Course(subject_code, course_number),
    FOREIGN KEY (year, semester) REFERENCES Term(year, semester)
);

-- ============ DATA ============

INSERT INTO Term (year, semester, start_date, end_date) VALUES
(2022, 'Fall', '2022-08-22', '2022-12-16'),
(2022, 'Spring', '2022-01-23', '2022-05-18'),
(2023, 'Fall', '2023-08-21', '2023-12-15'),
(2024, 'Spring', '2024-01-22', '2024-05-17'),
(2024, 'Fall', '2024-08-19', '2024-12-13'),
(2025, 'Spring', '2025-01-21', '2025-05-16'),
(2025, 'Fall', '2025-08-18', '2025-12-12'),
(2026, 'Spring', '2026-01-20', '2026-05-15'),
(2026, 'Fall', '2026-08-17', '2026-12-11'),
(2027, 'Spring', '2027-01-19', '2027-05-14');

INSERT INTO Course (subject_code, course_number, title, units, description, requirement_category) VALUES
('CS', '146', 'Data Structures and Algorithms', 3, 'Covers core data structures and algorithm analysis.', 'Required'),
('CS', '149', 'Operating Systems', 3, 'Introduction to operating system concepts.', 'Required'),
('CS', '151', 'Object-Oriented Design', 3, 'Software design using OOP principles.', 'Required'),
('CS', '152', 'Programming Paradigms', 3, 'Survey of programming language paradigms.', 'Required'),
('CS', '153', 'Compiler Design', 3, 'Introduction to compiler construction.', 'Elective'),
('CS', '154', 'Formal Languages and Computability', 3, 'Automata theory and computability.', 'Required'),
('CS', '157A', 'Database Management Systems I', 3, 'Relational database design and SQL.', 'Required'),
('CS', '157B', 'Database Management Systems II', 3, 'Advanced database topics and application development.', 'Elective'),
('CS', '160', 'Software Engineering', 3, 'Software development lifecycle and project management.', 'Required'),
('CS', '166', 'Information Security', 3, 'Principles of computer and network security.', 'Elective');

INSERT INTO Professor (professor_id, first_name, last_name) VALUES
(1, 'Ching-seh', 'Wu'),
(2, 'William', 'Andreopoulos'),
(3, 'Paul', 'Sanghera'),
(4, 'Thomas', 'Austin'),
(5, 'Sami', 'Khuri'),
(6, 'Suneuy', 'Kim'),
(7, 'Fabio', 'Di Troia'),
(8, 'Robert', 'Chun'),
(9, 'Katerina', 'Potika'),
(10, 'Jon', 'Pearce');

INSERT INTO Student (student_id, first_name, last_name, email, password_hash, preferred_credits_per_term, grad_year, grad_semester) VALUES
(1, 'Maria', 'Lopez', 'maria.lopez@sjsu.edu', 'hash1', 15, 2026, 'Spring'),
(2, 'James', 'Chen', 'james.chen@sjsu.edu', 'hash2', 12, 2026, 'Fall'),
(3, 'Aisha', 'Khan', 'aisha.khan@sjsu.edu', 'hash3', 16, 2027, 'Spring'),
(4, 'David', 'Kim', 'david.kim@sjsu.edu', 'hash4', 14, 2026, 'Spring'),
(5, 'Sofia', 'Garcia', 'sofia.garcia@sjsu.edu', 'hash5', 15, 2027, 'Spring'),
(6, 'Ethan', 'Nguyen', 'ethan.nguyen@sjsu.edu', 'hash6', 13, 2026, 'Fall'),
(7, 'Olivia', 'Patel', 'olivia.patel@sjsu.edu', 'hash7', 15, 2026, 'Spring'),
(8, 'Noah', 'Brown', 'noah.brown@sjsu.edu', 'hash8', 12, 2027, 'Spring'),
(9, 'Grace', 'Martinez', 'grace.martinez@sjsu.edu', 'hash9', 16, 2026, 'Fall'),
(10, 'Liam', 'Davis', 'liam.davis@sjsu.edu', 'hash10', 14, 2027, 'Spring');

INSERT INTO Roadmap (student_id, roadmap_name) VALUES
(1, 'Main Plan'),
(1, 'Backup Plan'),
(2, 'Main Plan'),
(3, 'Fast Track'),
(4, 'Main Plan'),
(5, 'Main Plan'),
(6, 'Grad School Prep'),
(7, 'Main Plan'),
(8, 'Main Plan'),
(9, 'Main Plan');

INSERT INTO Section (subject_code, course_number, year, semester, section_number, professor_id) VALUES
('CS', '146', 2026, 'Fall', '01', 1),
('CS', '149', 2026, 'Fall', '01', 4),
('CS', '151', 2026, 'Fall', '01', 2),
('CS', '152', 2025, 'Spring', '01', 5),
('CS', '153', 2025, 'Fall', '01', 7),
('CS', '154', 2026, 'Spring', '01', 6),
('CS', '157A', 2026, 'Fall', '01', 1),
('CS', '157B', 2025, 'Fall', '01', 8),
('CS', '160', 2026, 'Spring', '01', 3),
('CS', '166', 2025, 'Fall', '01', 9);

INSERT INTO Review (professor_id, subject_code, course_number, year, semester, quality_rating, difficulty_rating, review_text, review_date) VALUES
(1, 'CS', '146', 2026, 'Fall', 4.0, 3.5, 'Clear lectures, fair exams.', '2026-12-01'),
(1, 'CS', '157A', 2026, 'Fall', 4.5, 3.0, 'Great explanation of SQL joins.', '2026-12-05'),
(4, 'CS', '149', 2026, 'Fall', 3.5, 4.0, 'Challenging but rewarding.', '2026-12-03'),
(2, 'CS', '151', 2026, 'Fall', 4.0, 3.0, 'Good OOP examples.', '2026-12-02'),
(5, 'CS', '152', 2025, 'Spring', 3.8, 3.5, 'Interesting paradigms covered.', '2025-05-10'),
(7, 'CS', '153', 2025, 'Fall', 3.0, 4.5, 'Compiler project was tough.', '2025-12-08'),
(6, 'CS', '154', 2026, 'Spring', 4.2, 3.8, 'Good theory foundation.', '2026-05-09'),
(8, 'CS', '157B', 2025, 'Fall', 3.9, 3.2, 'Useful advanced DB topics.', '2025-12-10'),
(3, 'CS', '160', 2026, 'Spring', 4.6, 2.8, 'Well organized SE course.', '2026-05-11'),
(9, 'CS', '166', 2025, 'Fall', 4.1, 3.6, 'Security labs were great.', '2025-12-09');

INSERT INTO Takes (student_id, subject_code, course_number, year, semester, section_number, status, grade) VALUES
(1, 'CS', '146', 2026, 'Fall', '01', 'Completed', 'A'),
(2, 'CS', '149', 2026, 'Fall', '01', 'In Progress', NULL),
(3, 'CS', '151', 2026, 'Fall', '01', 'Completed', 'B+'),
(4, 'CS', '152', 2025, 'Spring', '01', 'Completed', 'A-'),
(5, 'CS', '153', 2025, 'Fall', '01', 'Completed', 'B'),
(6, 'CS', '154', 2026, 'Spring', '01', 'In Progress', NULL),
(7, 'CS', '157A', 2026, 'Fall', '01', 'In Progress', NULL),
(8, 'CS', '157B', 2025, 'Fall', '01', 'Completed', 'A'),
(9, 'CS', '160', 2026, 'Spring', '01', 'Completed', 'B+'),
(10, 'CS', '166', 2025, 'Fall', '01', 'Completed', 'A');

INSERT INTO Requires (subject_code, course_number, prereq_subject_code, prereq_course_number, minimum_grade, alternative_group) VALUES
('CS', '157A', 'CS', '146', 'C', NULL),
('CS', '157B', 'CS', '157A', 'C', NULL),
('CS', '160', 'CS', '146', 'C', NULL),
('CS', '160', 'CS', '151', 'C', NULL),
('CS', '153', 'CS', '146', 'C', NULL),
('CS', '153', 'CS', '154', 'C', NULL),
('CS', '149', 'CS', '146', 'C', NULL),
('CS', '166', 'CS', '149', 'C', NULL),
('CS', '152', 'CS', '146', 'C', NULL),
('CS', '154', 'CS', '146', 'C', NULL);

INSERT INTO Plans (student_id, roadmap_name, subject_code, course_number, year, semester) VALUES
(1, 'Main Plan', 'CS', '160', 2026, 'Fall'),
(1, 'Backup Plan', 'CS', '166', 2027, 'Spring'),
(2, 'Main Plan', 'CS', '157A', 2026, 'Fall'),
(3, 'Fast Track', 'CS', '157A', 2026, 'Fall'),
(4, 'Main Plan', 'CS', '157B', 2026, 'Fall'),
(5, 'Main Plan', 'CS', '160', 2026, 'Fall'),
(6, 'Grad School Prep', 'CS', '166', 2026, 'Fall'),
(7, 'Main Plan', 'CS', '153', 2026, 'Fall'),
(8, 'Main Plan', 'CS', '154', 2026, 'Fall'),
(9, 'Main Plan', 'CS', '149', 2026, 'Fall');
