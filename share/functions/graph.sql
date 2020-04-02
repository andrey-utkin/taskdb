-- Usage:
--
-- SELECT value
-- FROM graph((SELECT ARRAY_AGG(tasks) FROM tasks WHERE <criteria>))
-- ORDER BY order_
--
-- psql -qtAX -f query.sql > graph.dot
-- dot -Tpng graph.dot -o graph.png

CREATE OR REPLACE FUNCTION graph(selection_array tasks[])
RETURNS TABLE (value text, order_ int)
AS $$

WITH
selection AS (
SELECT * FROM unnest(selection_array.*)
),
nodes AS (
SELECT graph_node_repr(selection) AS value, 1 AS order_
FROM selection
),
edges AS (
SELECT '"' || s1.uuid || '" -> "' || dep.uuid || '"' AS value, 2 AS order_
FROM selection s1,
     LATERAL (
      SELECT unnest(string_to_array(s1.dependencies, E'\n')) AS uuid
      INTERSECT
      SELECT uuid::text FROM selection AS uuid
     ) AS dep
UNION
SELECT '"' || selection.parent || '" -> "' || selection.uuid || '"' AS value, 2 AS order_
FROM selection
WHERE selection.parent IN (SELECT uuid FROM selection)
),
full_graph AS (
SELECT 'digraph G {' AS value, 0 AS order_
UNION
SELECT * FROM nodes
UNION
SELECT * FROM edges
UNION
SELECT '}' AS value, 3 AS order_
)

SELECT * FROM full_graph ORDER BY order_

$$
LANGUAGE SQL
