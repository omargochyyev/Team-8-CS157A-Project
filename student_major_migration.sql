-- FR1: Student.major support (additive, safe to run on existing CourseLaneDB).
-- Run: mysql -u root -p CourseLaneDB < student_major_migration.sql
-- Fresh setups: courselanedb_schema.sql already includes `major`; this file is
-- only needed for databases created before the major column was added.
ALTER TABLE Student ADD COLUMN major VARCHAR(100) DEFAULT 'Computer Science';
UPDATE Student SET major = 'Computer Science' WHERE major IS NULL;
