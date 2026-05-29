# Supabase Migrations

## Webhook trigger migration

Run the following file in the Supabase SQL Editor to create the webhook trigger functions and ensure the `supabase_functions` helper schema is present:

- `admin/supabase/migrations/000_create_webhooks_and_schema.sql`

> Important: Supabase SQL Editor requires the SQL script text itself, not a file path. Copy the contents of the file into the editor and then execute it.
>
This is the updated migration that defines `supabase_functions.http_request` and installs the trigger functions for:

- `notify-new-enquiry`
- `notify-job-created`
- `notify-job-approved`
- `notify-surveyor-claimed`
- `notify-field-data-uploaded`
- `notify-report-sent`

Ignore `20260528_create_webhooks_v2.sql` — it is a placeholder/test variant and not the file to run.

If you see `schema "supabase_functions" does not exist`, run:

```sql
admin/supabase/migrations/000_create_supabase_functions_schema.sql
```

Then re-run:

```sql
admin/supabase/migrations/000_create_webhooks_and_schema.sql
```

> If you have already inserted data successfully but emails are not firing, this migration must be executed or re-run in the Supabase SQL Editor.
>
> After running the migration, verify that the trigger functions and triggers exist:
>
> ```sql
> SELECT n.nspname, p.proname
> FROM pg_proc p
> JOIN pg_namespace n ON n.oid = p.pronamespace
> WHERE p.proname LIKE 'trigger_notify_%'
> ORDER BY p.proname;
>
> SELECT tgname, tgrelid::regclass, pg_get_triggerdef(oid)
> FROM pg_trigger
> WHERE NOT tgisinternal
>   AND tgrelid::regclass::text IN ('public.enquiries', 'public.jobs')
> ORDER BY tgname;
> ```
>
> Then review any webhook delivery failures using:
>
> ```sql
> SELECT *
> FROM supabase_functions.webhook_request_logs
> ORDER BY created_at DESC
> LIMIT 20;
> ```

You can also inspect webhook delivery failures in Supabase with:

```sql
SELECT *
FROM supabase_functions.webhook_request_logs
ORDER BY created_at DESC
LIMIT 20;
```

If a request failed, verify that the Edge Function is deployed and that `RESEND_API_KEY` is set in Supabase project secrets.
