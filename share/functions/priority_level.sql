CREATE OR REPLACE FUNCTION priority_level(priority text) RETURNS int
LANGUAGE sql
AS $$
SELECT
CASE priority
WHEN 'customer-blocked' THEN 9
WHEN 'typical-usecase-blocked' THEN 8

WHEN 'commitment' THEN 7
WHEN 'quality-strategy' THEN 6

WHEN 'growth-blocked' THEN 5
WHEN 'unique-usecase-blocked' THEN 4

WHEN 'customer-value-improvement' THEN 3
WHEN 'internal-productivity' THEN 2

WHEN 'workaround-required' THEN 1
ELSE 0
END
$$;
