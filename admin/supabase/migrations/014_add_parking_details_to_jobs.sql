-- Add parking_details column to jobs table
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS parking_details text;
