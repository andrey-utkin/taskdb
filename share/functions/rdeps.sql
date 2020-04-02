-- Usage:

-- SELECT * FROM rdeps(<uuid>)

DROP FUNCTION rdeps(uuid);
CREATE OR REPLACE FUNCTION rdeps(arg uuid)
RETURNS SETOF tasks
LANGUAGE SQL
AS $$

WITH arg_task AS (
 SELECT parent FROM tasks WHERE uuid = arg
)

SELECT n.*
FROM tasks AS n, arg_task
WHERE
n.status IN ('pending', 'completed')
AND uuid = arg_task.parent

UNION

SELECT n.*
FROM tasks as n
WHERE
n.status IN ('pending', 'completed')
AND arg::text IN (SELECT unnest(string_to_array(n.dependencies, E'\n')) AS uuid)

$$
