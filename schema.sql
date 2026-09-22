-- CourseLane database schema
-- Run this against a local MySQL server to set up the database for this project.

CREATE DATABASE IF NOT EXISTS CourseLane;

CREATE TABLE IF NOT EXISTS CourseLane.Courses (
    CourseID INT NOT NULL AUTO_INCREMENT,
    CourseNum VARCHAR(20) NOT NULL,
    Title VARCHAR(100) NOT NULL,
    Units INT NOT NULL,
    PRIMARY KEY (CourseID)
);

INSERT INTO CourseLane.Courses (CourseNum, Title, Units) VALUES
('CS 146', 'Data Structures and Algorithms', 3),
('CS 157A', 'Database Management Systems', 3),
('CS 160', 'Software Engineering', 3);

CREATE TABLE IF NOT EXISTS CourseLane.Professors (
    ProfessorID INT NOT NULL AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Department VARCHAR(50) NOT NULL,
    AvgRating DECIMAL(2,1),
    PRIMARY KEY (ProfessorID)
);

INSERT INTO CourseLane.Professors (Name, Department, AvgRating) VALUES
('Ching-seh Wu', 'Computer Science', 3.8),
('William Andreopoulos', 'Computer Science', 4.0),
('Paul Sanghera', 'Computer Science', 2.9);
