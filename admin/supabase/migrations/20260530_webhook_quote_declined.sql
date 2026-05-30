-- Webhook: fire notify-quote-declined when enquiry status flips to 'declined'.

CREATE OR REPLACE FUNCTION trigger_notify_quote_declined()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (OLD.status IS DISTINCT FROM 'declined') AND NEW.status = 'declined' THEN
    PERFORM net.http_post(
      url     := 'https://lemppaqgpntadeylzzwn.supabase.co/functions/v1/notify-quote-declined',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key', true)
      ),
      body    := jsonb_build_object('record', row_to_json(NEW), 'old_record', row_to_json(OLD))
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_quote_declined ON public.enquiries;
CREATE TRIGGER on_quote_declined
  AFTER UPDATE ON public.enquiries
  FOR EACH ROW EXECUTE FUNCTION trigger_notify_quote_declined();
