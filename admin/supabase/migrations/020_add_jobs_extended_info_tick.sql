-- Add extended_info_received tick columns to jobs table
-- Tracks whether the customer has submitted their acceptance-form details (parking, billing, T&Cs)

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS extended_info_received boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS extended_info_received_at timestamptz;
