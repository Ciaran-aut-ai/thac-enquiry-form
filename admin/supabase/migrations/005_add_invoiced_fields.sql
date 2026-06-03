-- Add invoiced tracking to jobs
ALTER TABLE jobs
ADD COLUMN invoiced BOOLEAN DEFAULT false,
ADD COLUMN invoiced_at TIMESTAMP;

-- Create index for querying invoiced jobs
CREATE INDEX idx_jobs_invoiced ON jobs(invoiced, invoiced_at DESC);
