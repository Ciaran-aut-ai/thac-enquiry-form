-- Add deadline_tier column to jobs table
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS deadline_tier text;
