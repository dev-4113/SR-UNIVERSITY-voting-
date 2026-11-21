-- LOCAL PRODUCT-REVIEW WORKFLOW ONLY.
-- Use fictional test student details. These tables are not approved for official elections.
-- This schema links a review ballot to its test student; it is NOT a secret-ballot design.

CREATE DATABASE IF NOT EXISTS sr_university_voting_demo
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sr_university_voting_demo;

CREATE TABLE IF NOT EXISTS review_students (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(80) NOT NULL,
  roll_number VARCHAR(30) NOT NULL UNIQUE,
  department VARCHAR(20) NOT NULL,
  study_year VARCHAR(20) NOT NULL,
  registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS review_ballots (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT UNSIGNED NOT NULL UNIQUE,
  candidate_name VARCHAR(40) NOT NULL,
  cast_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_review_ballot_student
    FOREIGN KEY (student_id) REFERENCES review_students(id) ON DELETE RESTRICT,
  CONSTRAINT chk_review_candidate
    CHECK (candidate_name IN ('Candidate A', 'Candidate B', 'Candidate C'))
) ENGINE=InnoDB;
