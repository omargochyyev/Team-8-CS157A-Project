-- this is extra sample data for the ProfessorComparison feature
-- Run after courselanedb_schema.sql and run it only once
-- to reset: rerun courselanedb_schema.sql, rebuilds everything

USE CourseLaneDB;

INSERT INTO Section (subject_code, course_number, year, semester, section_number, professor_id) VALUES
('CS', '157A', 2025, 'Fall', '01', 1),
('CS', '157A', 2025, 'Fall', '02', 2),
('CS', '157A', 2026, 'Fall', '02', 2),
('CS', '157A', 2025, 'Fall', '03', 3),
('CS', '157A', 2026, 'Fall', '03', 3);

INSERT INTO Review (professor_id, subject_code, course_number, year, semester, quality_rating, difficulty_rating, review_text, review_date) VALUES
(1, 'CS', '157A', 2025, 'Fall', 3.5, 3.4, 'Disorganized at first.', '2025-12-02'),
(1, 'CS', '157A', 2025, 'Fall', 3.7, 3.3, 'Improving, but slides were rough.', '2025-12-06'),
(1, 'CS', '157A', 2026, 'Fall', 4.3, 3.0, 'Much clearer than before.', '2026-12-04'),
(2, 'CS', '157A', 2025, 'Fall', 4.5, 3.0, 'Engaging and fair.', '2025-12-03'),
(2, 'CS', '157A', 2025, 'Fall', 4.4, 3.1, 'Great examples.', '2025-12-07'),
(2, 'CS', '157A', 2026, 'Fall', 3.6, 3.8, 'Quality dropped, harder exams.', '2026-12-02'),
(2, 'CS', '157A', 2026, 'Fall', 3.8, 3.7, 'Fast pace.', '2026-12-06'),
(3, 'CS', '157A', 2025, 'Fall', 4.0, 3.2, 'Consistent and clear.', '2025-12-04'),
(3, 'CS', '157A', 2026, 'Fall', 4.0, 3.2, 'Same as last year.', '2026-12-03'),
(3, 'CS', '157A', 2026, 'Fall', 3.9, 3.3, 'Solid course.', '2026-12-07');