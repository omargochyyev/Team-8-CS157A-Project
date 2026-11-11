-- Extra future terms so the roadmap generator has room to plan.
-- Run: mysql -u root -p CourseLaneDB < roadmap_terms_seed.sql
INSERT INTO Term (year, semester, start_date, end_date) VALUES
(2027, 'Fall',   '2027-08-16', '2027-12-10'),
(2028, 'Spring', '2028-01-18', '2028-05-12'),
(2028, 'Fall',   '2028-08-21', '2028-12-15');
