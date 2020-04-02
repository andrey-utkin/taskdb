-- Usage:
--
-- SELECT value
-- FROM graph((SELECT ARRAY_AGG(tasks) FROM tasks WHERE <criteria>))
-- ORDER BY order_
--
-- psql -qtAX -f query.sql > graph.dot
-- dot -Tpng graph.dot -o graph.png

CREATE OR REPLACE FUNCTION graph_node_repr(t tasks)
RETURNS text
AS $$

WITH status AS (
 SELECT
  CASE
   WHEN t.scheduled IS NULL
    THEN 'unscheduled'
   WHEN t.scheduled IS NOT NULL
        AND (t.scheduled + COALESCE(t.duration, 0) * '1 second'::interval) < NOW()
    THEN 'completed'
   WHEN t.scheduled IS NOT NULL
        AND NOW() BETWEEN t.scheduled AND (t.scheduled + COALESCE(t.duration, 0) * '1 second'::interval)
    THEN 'current'
   ELSE 'pending'
  END
  AS status
),

repr AS (
 SELECT
  t.uuid,
  COALESCE(t.alias, REPLACE(t.description, '"', E'\\"')) AS label,
  -- color
  CASE
   WHEN status.status = 'unscheduled'
    THEN 'grey'
   WHEN status.status = 'completed'
    THEN 'green'
   WHEN status.status = 'current'
    THEN 'orange'
   WHEN status.status = 'pending'
    THEN 'red'
   END
   AS color
  FROM status
)

SELECT
 '"' || repr.uuid || '" [label="' || repr.label || '" color="' || repr.color || '"]'
FROM repr

$$
LANGUAGE SQL
