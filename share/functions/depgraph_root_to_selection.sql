-- Usage:
--
-- SELECT value FROM graph((
-- SELECT ARRAY_AGG(depgraph_root_to_selection) FROM depgraph_root_to_selection
-- (
--  (SELECT uuid FROM tasks WHERE alias = 'root'),
--  (
--   SELECT array_agg(tasks) FROM tasks
--   WHERE
--   status IN ('pending', 'completed')
--   AND scheduled >= date_trunc('day', current_date) + INTERVAL '7:30:00'
--   AND scheduled < date_trunc('day', current_date) +  INTERVAL '1 days'
--  )
-- )
-- 
-- ))
-- ORDER BY order_
--
-- psql -qtAX -f query.sql > graph.dot
-- dot -Tpng graph.dot -o graph.png

CREATE OR REPLACE FUNCTION depgraph_root_to_selection(root uuid, selection_array tasks[])
RETURNS SETOF tasks
AS $$

WITH
minimal_dataset AS (
 SELECT * FROM unnest(selection_array)
),

conservative_dataset AS (
 SELECT * FROM depgraph(root)
),

challenged_subset AS (
SELECT * FROM conservative_dataset
EXCEPT
SELECT * FROM minimal_dataset
),

data AS (
SELECT * FROM minimal_dataset
UNION
SELECT * FROM challenged_subset
WHERE EXISTS(
 SELECT * FROM depgraph(challenged_subset.uuid)
 INTERSECT
 SELECT * FROM minimal_dataset
)
)

SELECT * FROM data

$$
LANGUAGE SQL
