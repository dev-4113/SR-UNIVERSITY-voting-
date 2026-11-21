-- LOCAL PRODUCT-REVIEW DEMO ONLY. This schema stores OTP verification state,
-- not student roster data and not ballots. Official voting remains disabled.
CREATE DATABASE IF NOT EXISTS sr_university_voting_demo
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sr_university_voting_demo;

CREATE TABLE IF NOT EXISTS demo_email_otps (
  email VARCHAR(254) NOT NULL PRIMARY KEY,
  code_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verified_at DATETIME NULL,
  INDEX idx_demo_otp_expiry (expires_at)
) ENGINE=InnoDB;
