-- Create survey_types table with default 1 hour per survey type
-- This is used to calculate surveyor pay: (1 hour travel + survey_hours) × hourly_rate

CREATE TABLE survey_types (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  survey_type TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  hours_on_site NUMERIC(5, 2) NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert all 8 survey types with 1 hour default
INSERT INTO survey_types (survey_type, label, hours_on_site) VALUES
  ('planning_stage1', 'Planning — Stage 1', 1),
  ('planning_stage2', 'Planning — Stage 2', 1),
  ('health_safety', 'Tree Condition / Risk Survey', 1),
  ('insurer_mortgage', 'Insurer / Mortgage Lender', 1),
  ('subsidence', 'Building Damage / Subsidence', 1),
  ('nhbc', 'Foundation Depths (NHBC)', 1),
  ('site_visit', 'Site Visit & Advice', 1),
  ('resistograph', 'Resistograph Testing', 1);

-- Enable RLS
ALTER TABLE survey_types ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read (public data)
CREATE POLICY "Allow public read" ON survey_types
  FOR SELECT USING (true);

-- Policy: Only authenticated users can update (admin only, in practice)
CREATE POLICY "Allow authenticated update" ON survey_types
  FOR UPDATE USING (auth.role() = 'authenticated');
