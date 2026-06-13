-- Track NDA acceptance for jobs
-- Surveyors must accept NDA before claiming a job

CREATE TABLE job_nda_acceptance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  surveyor_id UUID NOT NULL REFERENCES surveyors(id) ON DELETE CASCADE,
  accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  ip_address TEXT,
  user_agent TEXT
);

CREATE INDEX idx_job_nda_job_surveyor
  ON job_nda_acceptance(job_id, surveyor_id);

CREATE INDEX idx_job_nda_surveyor
  ON job_nda_acceptance(surveyor_id);

-- Enable RLS
ALTER TABLE job_nda_acceptance ENABLE ROW LEVEL SECURITY;

-- Policy: Surveyors can view their own NDA acceptances
CREATE POLICY "Surveyors view own NDA" ON job_nda_acceptance
  FOR SELECT
  USING (
    surveyor_id IN (
      SELECT id FROM surveyors
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Surveyors can insert their own NDA acceptance
CREATE POLICY "Surveyors accept own NDA" ON job_nda_acceptance
  FOR INSERT
  WITH CHECK (
    surveyor_id IN (
      SELECT id FROM surveyors
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Admins can view all NDA acceptances
CREATE POLICY "Admins view all NDA" ON job_nda_acceptance
  FOR SELECT
  USING (auth.role() = 'authenticated');
