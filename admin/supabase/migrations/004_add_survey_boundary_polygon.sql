-- Add survey boundary polygon column to enquiries table
-- Stores GeoJSON polygon coordinates drawn by customer

ALTER TABLE enquiries
ADD COLUMN survey_boundary_polygon JSONB;

-- Create index for faster queries
CREATE INDEX idx_enquiries_has_polygon
  ON enquiries(id)
  WHERE survey_boundary_polygon IS NOT NULL;
