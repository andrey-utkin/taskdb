-- Usage:

-- SELECT * FROM depgraph(<uuid>)

-- SELECT value
-- FROM graph((SELECT ARRAY_AGG(depgraph) FROM depgraph(<uuid>)))
-- ORDER BY order_

DROP FUNCTION depgraph(uuid);
CREATE OR REPLACE FUNCTION depgraph(head_uuid uuid)
RETURNS SETOF tasks
LANGUAGE SQL
AS $$

WITH RECURSIVE depgraph AS
(
	(
		SELECT *
		FROM tasks
		WHERE tasks.uuid = head_uuid
	)
	UNION ALL
	(
		SELECT n.*
		FROM tasks AS n, depgraph AS r
		WHERE (
		       n.parent = r.uuid
		       OR
		       r.dependencies ~ n.uuid::text
		      )
		      AND n.status IN ('pending', 'completed')
	)
)
SELECT * FROM depgraph
$$
