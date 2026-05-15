-- Add specialty column to users table
ALTER TABLE users ADD COLUMN specialty VARCHAR(255) DEFAULT NULL AFTER role;
