-- Extra sections and reviews so professor trends (requirement 8) have data to show.
-- Run AFTER courselanedb_schema.sql:
-- Result: Wu = Steady, Andreopoulos = Declining, Sanghera = Improving.

USE CourseLaneDB;
INSERT INTO Section (subject_code, course_number, year, semester, section_number, professor_id) VALUES
('CS', '157A', 2024, 'Spring', '01', 1),
('CS', '157A', 2024, 'Fall',   '01', 1),
('CS', '157A', 2025, 'Spring', '01', 1),
('CS', '146',  2025, 'Fall',   '01', 1),
('CS', '157A', 2026, 'Spring', '01', 1),
('CS', '151',  2024, 'Spring', '01', 2),
('CS', '151',  2024, 'Fall',   '01', 2),
('CS', '151',  2025, 'Spring', '01', 2),
('CS', '151',  2025, 'Fall',   '01', 2),
('CS', '151',  2026, 'Spring', '01', 2),
('CS', '160',  2024, 'Spring', '01', 3),
('CS', '160',  2024, 'Fall',   '01', 3),
('CS', '160',  2025, 'Spring', '01', 3),
('CS', '160',  2025, 'Fall',   '01', 3);

INSERT INTO Review (professor_id, subject_code, course_number, year, semester, quality_rating, difficulty_rating, review_text, review_date) VALUES
(1, 'CS', '157A', 2024, 'Spring', 4.0, 3.5, 'Solid intro to relational design.', '2024-05-14'),
(1, 'CS', '157A', 2024, 'Fall',   4.5, 3.0, 'Explains normalization clearly.', '2024-12-10'),
(1, 'CS', '157A', 2025, 'Spring', 4.0, 3.5, 'Fair exams and lots of SQL practice.', '2025-05-12'),
(1, 'CS', '146',  2025, 'Fall',   4.5, 3.5, 'Great pacing for a hard course.', '2025-12-09'),
(1, 'CS', '157A', 2026, 'Spring', 4.0, 3.0, 'Helpful in office hours.', '2026-05-13'),
(2, 'CS', '151',  2024, 'Spring', 4.5, 3.0, 'Engaging OOP examples.', '2024-05-15'),
(2, 'CS', '151',  2024, 'Fall',   4.5, 3.0, 'Approachable and organized.', '2024-12-11'),
(2, 'CS', '151',  2025, 'Spring', 4.5, 3.0, 'Great design pattern walkthroughs.', '2025-05-13'),
(2, 'CS', '151',  2025, 'Fall',   4.0, 3.5, 'Workload picked up this term.', '2025-12-10'),
(2, 'CS', '151',  2026, 'Spring', 4.5, 3.5, 'Still one of the best CS instructors.', '2026-05-14'),
(3, 'CS', '160',  2024, 'Spring', 2.5, 4.0, 'Lectures felt disorganized.', '2024-05-16'),
(3, 'CS', '160',  2024, 'Fall',   3.0, 4.0, 'Grading criteria were unclear.', '2024-12-12'),
(3, 'CS', '160',  2025, 'Spring', 3.0, 3.5, 'Better than expected.', '2025-05-14'),
(3, 'CS', '160',  2025, 'Fall',   3.5, 3.0, 'Noticeably improved structure.', '2025-12-11');
