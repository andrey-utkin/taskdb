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
SELECT '"' || selection.uuid || '" [label="' || COALESCE(selection.alias, selection.description) || '"]' AS value, 1 AS order_
FROM selection
),
edges AS (
SELECT '"' || selection.uuid || '" -> "' || dep || '"' AS value, 2 AS order_
FROM selection, unnest(string_to_array(selection.dependencies, E'\n')) AS dep
UNION
SELECT '"' || selection.parent || '" -> "' || selection.uuid || '"' AS value, 2 AS order_
FROM selection
WHERE selection.parent IS NOT NULL
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
