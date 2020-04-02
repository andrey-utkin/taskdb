-- Usage:

-- SELECT * FROM deps(<uuid>)

DROP FUNCTION deps(uuid);
CREATE OR REPLACE FUNCTION deps(arg uuid)
RETURNS SETOF tasks
LANGUAGE SQL
AS $$

WITH strictly_deps AS (
 SELECT dependencies FROM tasks WHERE uuid = arg
)

SELECT n.*
FROM tasks AS n
WHERE
n.status IN ('pending', 'completed')
AND n.parent = arg

UNION

SELECT n.*
FROM tasks as n, strictly_deps
WHERE
n.status IN ('pending', 'completed')
AND n.uuid::text IN (SELECT unnest(string_to_array(strictly_deps.dependencies, E'\n')) AS uuid)

$$
