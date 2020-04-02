CREATE OR REPLACE FUNCTION alias(alias_ text)
RETURNS uuid
LANGUAGE SQL
AS $$
SELECT uuid FROM tasks WHERE tasks.alias = alias_
$$
