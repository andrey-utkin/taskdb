CREATE OR REPLACE FUNCTION public.changes_notify_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 PERFORM pg_notify('CHANGES', substring(replace(current_query(), E'\n', '\n') FROM 0 FOR 8000));
 RETURN NEW;
END;
$$;

