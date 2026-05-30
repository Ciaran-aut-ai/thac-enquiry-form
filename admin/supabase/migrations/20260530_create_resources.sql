-- Sprint 5: Resource library — survey instructions, templates, standard terms.
-- Admin manages; surveyors access via mobile app when claiming a job.

CREATE TABLE IF NOT EXISTS public.resources (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text        NOT NULL,
  category    text        NOT NULL DEFAULT 'other',
  description text,
  url         text,
  is_active   boolean     NOT NULL DEFAULT true,
  sort_order  integer     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Seed with placeholder categories so the page isn't empty on first load
INSERT INTO public.resources (title, category, description, sort_order) VALUES
  ('BS5837 Survey Methodology Guide',   'survey_instructions', 'Standard field methodology for BS5837 tree surveys.', 1),
  ('VTA Field Assessment Sheet',        'survey_instructions', 'Visual Tree Assessment checklist and scoring sheet.', 2),
  ('Standard Report Template',          'report_templates',    'Word template for BS5837 reports.', 1),
  ('Standard Terms & Conditions',       'standard_terms',      'THAC standard terms for client engagements.', 1)
ON CONFLICT DO NOTHING;
