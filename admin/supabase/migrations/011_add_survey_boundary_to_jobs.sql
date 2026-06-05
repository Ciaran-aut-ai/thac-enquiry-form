-- Add site boundary polygon to jobs table
ALTER TABLE jobs
ADD COLUMN IF NOT EXISTS site_boundary_polygon JSONB;

CREATE INDEX IF NOT EXISTS idx_jobs_boundary ON jobs USING GIN (site_boundary_polygon);
