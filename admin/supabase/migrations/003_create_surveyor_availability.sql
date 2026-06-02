-- Surveyor availability calendar: track which days each surveyor is available
-- One record per surveyor per day for the next 12+ months

CREATE TABLE surveyor_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  surveyor_id UUID NOT NULL REFERENCES surveyors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(surveyor_id, date)
);

CREATE INDEX idx_surveyor_availability_surveyor_date
  ON surveyor_availability(surveyor_id, date);

-- Enable RLS
ALTER TABLE surveyor_availability ENABLE ROW LEVEL SECURITY;

-- Policy: Surveyors can read/update their own availability
CREATE POLICY "Surveyors manage own availability" ON surveyor_availability
  FOR ALL
  USING (
    surveyor_id IN (
      SELECT id FROM surveyors
      WHERE user_id = auth.uid()
    )
  );

-- Policy: Admins can read all availability
CREATE POLICY "Admins read all availability" ON surveyor_availability
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Function to initialize availability for next 12 months
CREATE OR REPLACE FUNCTION init_surveyor_availability(p_surveyor_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO surveyor_availability (surveyor_id, date, is_available)
  SELECT
    p_surveyor_id,
    CURRENT_DATE + INTERVAL '1 day' * (seq - 1),
    true
  FROM generate_series(0, 364) AS t(seq)
  ON CONFLICT (surveyor_id, date) DO NOTHING;
END;
$$;
