-- Ensure site_location_tag column exists on jobs table
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS site_location_tag text;
