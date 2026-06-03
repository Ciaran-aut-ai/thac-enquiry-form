-- Add job allocation tracking for manual surveyor assignment with timeout
ALTER TABLE jobs
ADD COLUMN allocated_surveyor_id UUID REFERENCES surveyors(id) ON DELETE SET NULL,
ADD COLUMN allocated_at TIMESTAMP,
ADD COLUMN allocation_timeout_hours INTEGER DEFAULT 48,
ADD COLUMN allocation_rejected_at TIMESTAMP;

-- Create index for querying allocated jobs
CREATE INDEX idx_jobs_allocated_surveyor ON jobs(allocated_surveyor_id, allocated_at DESC)
WHERE allocated_surveyor_id IS NOT NULL;

-- Create index for expired allocations
CREATE INDEX idx_jobs_allocation_expired ON jobs(allocated_at, allocation_timeout_hours)
WHERE allocated_surveyor_id IS NOT NULL AND allocation_rejected_at IS NULL;
