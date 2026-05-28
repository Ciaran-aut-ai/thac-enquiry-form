-- Migration: create webhook_events table and triggers
-- Created: 2026-05-28
-- Purpose: Insert webhook events into `webhook_events` on relevant DB changes

-- Ensure gen_random_uuid is available (pgcrypto)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create webhook_events table
CREATE TABLE IF NOT EXISTS public.webhook_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for querying by event_type and time
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_type_created_at
  ON public.webhook_events (event_type, created_at DESC);

-- Helper: function to insert a webhook event
CREATE OR REPLACE FUNCTION public.enqueue_webhook(p_event_type text, p_payload jsonb)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.webhook_events(event_type, payload) VALUES (p_event_type, p_payload);
EXCEPTION WHEN OTHERS THEN
  -- swallow errors to avoid failing the originating transaction; log if needed
  RAISE NOTICE 'enqueue_webhook error: %', SQLERRM;
END;
$$;

-- 1) New enquiry created -> enqueue 'new_enquiry'
CREATE OR REPLACE FUNCTION public.tr_new_enquiry()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.enqueue_webhook('new_enquiry', row_to_json(NEW)::jsonb);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_enquiry ON public.enquiries;
CREATE TRIGGER trg_new_enquiry
AFTER INSERT ON public.enquiries
FOR EACH ROW EXECUTE FUNCTION public.tr_new_enquiry();

-- 2) Job created (insert into jobs) -> enqueue 'job_created'
CREATE OR REPLACE FUNCTION public.tr_job_created()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.enqueue_webhook('job_created', row_to_json(NEW)::jsonb);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_job_created ON public.jobs;
CREATE TRIGGER trg_job_created
AFTER INSERT ON public.jobs
FOR EACH ROW EXECUTE FUNCTION public.tr_job_created();

-- 3) Job approved -> enqueue 'job_approved'
-- Note: this project uses `dispatch_state` / booleans rather than a `status` column.
-- The explicit HTTP-trigger-based notify functions below handle dispatch_state changes,
-- so we avoid creating a trigger on a non-existent `status` column here.

-- 4) Surveyor claimed -> enqueue 'surveyor_claimed' when surveyor_id becomes non-null
CREATE OR REPLACE FUNCTION public.tr_surveyor_claimed()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (OLD.surveyor_id IS NULL) AND (NEW.surveyor_id IS NOT NULL) THEN
    PERFORM public.enqueue_webhook('surveyor_claimed', jsonb_build_object('job_id', NEW.id, 'surveyor_id', NEW.surveyor_id, 'job', row_to_json(NEW)::jsonb));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_surveyor_claimed ON public.jobs;
CREATE TRIGGER trg_surveyor_claimed
AFTER UPDATE OF surveyor_id ON public.jobs
FOR EACH ROW EXECUTE FUNCTION public.tr_surveyor_claimed();

-- 5) Field data uploaded -> enqueue 'field_data_uploaded' when field_data_uploaded flag toggles true
CREATE OR REPLACE FUNCTION public.tr_field_data_uploaded()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND COALESCE(OLD.field_data_uploaded, false) = false AND COALESCE(NEW.field_data_uploaded, false) = true THEN
    PERFORM public.enqueue_webhook('field_data_uploaded', jsonb_build_object('job_id', NEW.id, 'job', row_to_json(NEW)::jsonb));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_field_data_uploaded ON public.jobs;
CREATE TRIGGER trg_field_data_uploaded
AFTER UPDATE OF field_data_uploaded ON public.jobs
FOR EACH ROW EXECUTE FUNCTION public.tr_field_data_uploaded();

-- 6) Report sent -> enqueue 'report_sent'
-- Note: report delivery is signalled by `report_finalised` boolean in this schema.
-- The HTTP-trigger-based notify functions below handle that condition.

-- 7) Dispatch state critical (example: dispatch_state -> 'red') -> enqueue 'dispatch_red'
CREATE OR REPLACE FUNCTION public.tr_dispatch_state_red()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.dispatch_state = 'red' AND COALESCE(OLD.dispatch_state, '') <> 'red' THEN
    PERFORM public.enqueue_webhook('dispatch_red', jsonb_build_object('job_id', NEW.id, 'old_state', OLD.dispatch_state, 'new_state', NEW.dispatch_state, 'job', row_to_json(NEW)::jsonb));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dispatch_state_red ON public.jobs;
CREATE TRIGGER trg_dispatch_state_red
AFTER UPDATE OF dispatch_state ON public.jobs
FOR EACH ROW EXECUTE FUNCTION public.tr_dispatch_state_red();

-- Cleanup function (optional) — keep webhook queue small by removing processed items
CREATE OR REPLACE FUNCTION public.cleanup_webhook_events(p_older_than interval)
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
  _count integer;
BEGIN
  DELETE FROM public.webhook_events WHERE created_at < now() - p_older_than RETURNING 1 INTO _count;
  GET DIAGNOSTICS _count = ROW_COUNT;
  RETURN COALESCE(_count,0);
END;
$$;

-- Grant minimal privileges so edge functions (service role) can read/insert into webhook_events
GRANT INSERT, SELECT ON public.webhook_events TO authenticated;
GRANT INSERT, SELECT ON public.webhook_events TO anon;
-- End of migration
-- ============================================================
-- THAC CRM — Database Webhooks
-- Creates triggers that fire Supabase Edge Functions
-- ============================================================

-- 1. notify-new-enquiry
--    Fires: INSERT on enquiries
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_new_enquiry()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM supabase_functions.http_request(
    'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-new-enquiry',
    'POST',
    '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
    jsonb_build_object('type','INSERT','table','enquiries','record',row_to_json(NEW)),
    5000
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_enquiry_insert ON enquiries;
CREATE TRIGGER on_enquiry_insert
  AFTER INSERT ON enquiries
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_new_enquiry();


-- 2. notify-job-created
--    Fires: INSERT on jobs
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_job_created()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM supabase_functions.http_request(
    'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-job-created',
    'POST',
    '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
    jsonb_build_object('type','INSERT','table','jobs','record',row_to_json(NEW)),
    5000
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_job_insert ON jobs;
CREATE TRIGGER on_job_insert
  AFTER INSERT ON jobs
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_job_created();


-- 3. notify-job-approved
--    Fires: UPDATE on jobs where dispatch_state changes to 'red' (live/unallocated)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_job_approved()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.dispatch_state IS DISTINCT FROM NEW.dispatch_state
     AND NEW.dispatch_state = 'red' THEN
    PERFORM supabase_functions.http_request(
      'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-job-approved',
      'POST',
      '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
      jsonb_build_object('type','UPDATE','table','jobs','record',row_to_json(NEW),'old_record',row_to_json(OLD)),
      5000
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_job_approved ON jobs;
CREATE TRIGGER on_job_approved
  AFTER UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_job_approved();


-- 4. notify-surveyor-claimed
--    Fires: UPDATE on jobs where dispatch_state changes to 'claimed'
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_surveyor_claimed()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.dispatch_state IS DISTINCT FROM NEW.dispatch_state
     AND NEW.dispatch_state = 'claimed' THEN
    PERFORM supabase_functions.http_request(
      'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-surveyor-claimed',
      'POST',
      '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
      jsonb_build_object('type','UPDATE','table','jobs','record',row_to_json(NEW),'old_record',row_to_json(OLD)),
      5000
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_surveyor_claimed ON jobs;
CREATE TRIGGER on_surveyor_claimed
  AFTER UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_surveyor_claimed();


-- 5. notify-field-data-uploaded
--    Fires: UPDATE on jobs where field_data_uploaded flips to true
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_field_data_uploaded()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (OLD.field_data_uploaded = false OR OLD.field_data_uploaded IS NULL)
     AND NEW.field_data_uploaded = true THEN
    PERFORM supabase_functions.http_request(
      'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-field-data-uploaded',
      'POST',
      '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
      jsonb_build_object('type','UPDATE','table','jobs','record',row_to_json(NEW),'old_record',row_to_json(OLD)),
      5000
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_field_data_uploaded ON jobs;
CREATE TRIGGER on_field_data_uploaded
  AFTER UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_field_data_uploaded();


-- 6. notify-report-sent
--    Fires: UPDATE on jobs where report_finalised flips to true
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_notify_report_sent()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (OLD.report_finalised = false OR OLD.report_finalised IS NULL)
     AND NEW.report_finalised = true THEN
    PERFORM supabase_functions.http_request(
      'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-report-sent',
      'POST',
      '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxlbXBwYXFncG50YWRleWx6enduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMTUzOTMsImV4cCI6MjA5NDg5MTM5M30.SU2M7e5OSwqIjRJfM15uKLHTqSrLadcY46MR51twosU"}'::jsonb,
      jsonb_build_object('type','UPDATE','table','jobs','record',row_to_json(NEW),'old_record',row_to_json(OLD)),
      5000
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_report_sent ON jobs;
CREATE TRIGGER on_report_sent
  AFTER UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_report_sent();
