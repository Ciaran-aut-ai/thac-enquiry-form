-- Add enquiry_id to jobs table to link jobs back to their source enquiries
ALTER TABLE jobs
ADD COLUMN enquiry_id UUID REFERENCES enquiries(id) ON DELETE SET NULL;

-- Create index for faster lookups
CREATE INDEX idx_jobs_enquiry_id ON jobs(enquiry_id);
