-- Add survey boundary polygon to jobs table
ALTER TABLE jobs
ADD COLUMN IF NOT EXISTS survey_boundary_polygon JSONB;

CREATE INDEX IF NOT EXISTS idx_jobs_boundary ON jobs USING GIN (survey_boundary_polygon);
