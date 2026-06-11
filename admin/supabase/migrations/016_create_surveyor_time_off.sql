-- Surveyor time off: track when surveyors are unavailable
-- Surveyors can set their own time off dates (no approval needed)

CREATE TABLE surveyor_time_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  surveyor_id UUID NOT NULL REFERENCES surveyors(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_surveyor_time_off_surveyor
  ON surveyor_time_off(surveyor_id);

CREATE INDEX idx_surveyor_time_off_dates
  ON surveyor_time_off(start_date, end_date);

-- Enable RLS
ALTER TABLE surveyor_time_off ENABLE ROW LEVEL SECURITY;

-- Policy: Surveyors can manage their own time off
CREATE POLICY "Surveyors manage own time off" ON surveyor_time_off
  FOR ALL
  USING (
    surveyor_id IN (
      SELECT id FROM surveyors
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Admins can read all time off
CREATE POLICY "Admins read all time off" ON surveyor_time_off
  FOR SELECT
  USING (auth.role() = 'authenticated');
