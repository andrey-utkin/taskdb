REPLACE FUNCTION public.update_modified_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF (NEW.modified IS NOT DISTINCT FROM OLD.modified) THEN
  NEW.modified := CURRENT_TIMESTAMP;
 END IF;
 RETURN NEW;
END;
$$;
