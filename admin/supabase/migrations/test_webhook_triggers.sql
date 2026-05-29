-- This test script is designed for Supabase SQL Editor.
-- Replace placeholder values (especially JOB_ID) as needed.

-- 1) Verify webhook queue and trigger objects exist.
SELECT
  to_regclass('public.webhook_events') AS webhook_events_table,
  EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') AS pgcrypto_installed;

SELECT
  event_object_table,
  trigger_name,
  action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('jobs', 'enquiries')
ORDER BY event_object_table, trigger_name;

-- 2) Safe insert test for a new enquiry.
-- This uses a transaction and rolls back, so no permanent data is created.
BEGIN;

INSERT INTO enquiries (
  enquiry_type,
  survey_type,
  tree_count_band,
  site_postcode,
  deadline_tier,
  contact_name,
  contact_email,
  contact_phone,
  company,
  status,
  submitted_at
)
VALUES (
  'new',
  'arboricultural',
  '1-3',
  'SW1A 1AA',
  '1day',
  'Test User',
  'test@example.com',
  '+441234567890',
  'Test Company Ltd',
  'new',
  now()
)
RETURNING id;

SELECT 'enquiry_inserted' AS test_case, count(*) AS webhook_events_created
FROM public.webhook_events
WHERE created_at >= now() - interval '1 minute'
  AND event_type = 'new_enquiry';

ROLLBACK;

-- 3) Safe update test for an existing job, using a placeholder JOB_ID.
-- Replace <JOB_ID> before running.
BEGIN;

-- Confirm the job ID exists for your environment first.
SELECT id, dispatch_state, field_data_uploaded, report_finalised
FROM jobs
WHERE id = '<JOB_ID>'
LIMIT 1;

-- Test dispatch_state -> red
UPDATE jobs
SET dispatch_state = 'red'
WHERE id = '<JOB_ID>';

SELECT 'dispatch_state_red' AS test_case, count(*) AS webhook_events_created
FROM public.webhook_events
WHERE created_at >= now() - interval '1 minute'
  AND event_type = 'dispatch_red';

-- Test field_data_uploaded -> true
UPDATE jobs
SET field_data_uploaded = true
WHERE id = '<JOB_ID>';

SELECT 'field_data_uploaded' AS test_case, count(*) AS webhook_events_created
FROM public.webhook_events
WHERE created_at >= now() - interval '1 minute'
  AND event_type = 'field_data_uploaded';

-- Test report_finalised -> true
UPDATE jobs
SET report_finalised = true
WHERE id = '<JOB_ID>';

SELECT 'report_finalised' AS test_case, count(*) AS webhook_events_created
FROM public.webhook_events
WHERE created_at >= now() - interval '1 minute'
  AND event_type = 'report_sent';

ROLLBACK;

-- 4) Optional: list the Webhook trigger functions installed in public schema.
SELECT proname
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND proname IN (
    'trigger_notify_new_enquiry',
    'trigger_notify_job_created',
    'trigger_notify_job_approved',
    'trigger_notify_surveyor_claimed',
    'trigger_notify_field_data_uploaded',
    'trigger_notify_report_sent'
  );
