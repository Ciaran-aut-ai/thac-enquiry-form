-- Add acceptance details and new fields for quote acceptance form
ALTER TABLE enquiries
ADD COLUMN report_title TEXT,
ADD COLUMN access_details TEXT,
ADD COLUMN parking_details TEXT,
ADD COLUMN tc_accepted BOOLEAN DEFAULT false,
ADD COLUMN tc_accepted_at TIMESTAMP;

-- Create index for tracking T&C acceptances
CREATE INDEX idx_enquiries_tc_accepted ON enquiries(tc_accepted, tc_accepted_at DESC)
WHERE tc_accepted = true;
