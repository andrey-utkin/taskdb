REPLACE FUNCTION public.update_modified_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF (NEW.modified IS NULL) THEN
  NEW.modified := CURRENT_TIMESTAMP;
 END IF;
 RETURN NEW;
END;
$$;
