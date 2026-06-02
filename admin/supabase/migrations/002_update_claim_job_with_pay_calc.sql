-- Update claim_job RPC to auto-calculate surveyor pay
-- Formula: (1 hour travel + survey_hours) × surveyor_hourly_rate
-- Apply 20% bonus if job is next-day urgent (urgency_state = 'red')

CREATE OR REPLACE FUNCTION claim_job(p_job_id uuid, p_surveyor_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_survey_type TEXT;
  v_urgency_state TEXT;
  v_hourly_rate NUMERIC;
  v_survey_hours NUMERIC;
  v_base_pay NUMERIC;
  v_final_pay NUMERIC;
BEGIN
  -- Fetch job details and surveyor hourly rate
  SELECT j.survey_type, j.urgency_state, s.hourly_rate
  INTO v_survey_type, v_urgency_state, v_hourly_rate
  FROM jobs j
  JOIN surveyors s ON s.id = p_surveyor_id
  WHERE j.id = p_job_id
    AND j.dispatch_state = 'red'
    AND j.surveyor_id IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job is no longer available or surveyor not found';
  END IF;

  -- Fetch survey time (default to 1 hour if not found)
  SELECT COALESCE(hours_on_site, 1)
  INTO v_survey_hours
  FROM survey_types
  WHERE survey_type = v_survey_type;

  -- Calculate pay: (1 travel + survey_hours) × hourly_rate
  v_base_pay := (1 + COALESCE(v_survey_hours, 1)) * COALESCE(v_hourly_rate, 0);

  -- Apply 20% bonus if urgent (next-day)
  v_final_pay := CASE
    WHEN v_urgency_state = 'red' THEN v_base_pay * 1.2
    ELSE v_base_pay
  END;

  -- Update job with surveyor and calculated pay
  UPDATE public.jobs
  SET
    surveyor_id         = p_surveyor_id,
    surveyor_pay_amount = v_final_pay,
    dispatch_state      = 'orange',
    claimed_at          = now(),
    handed_back_at      = NULL,
    handed_back_note    = NULL
  WHERE id = p_job_id;
END;
$$;
