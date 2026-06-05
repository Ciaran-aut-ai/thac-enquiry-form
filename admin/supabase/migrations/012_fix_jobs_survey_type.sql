-- Fix survey_type column in jobs table to accept all survey types
-- Change from ENUM to TEXT to match enquiries table flexibility

ALTER TABLE jobs
ALTER COLUMN survey_type TYPE TEXT;
