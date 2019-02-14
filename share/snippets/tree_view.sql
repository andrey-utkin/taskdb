WITH RECURSIVE task_tree (uuid, rank) AS
(
	(
		SELECT tasks.uuid, 1 as rank, tasks.description, tasks.scheduled, tasks.duration
		FROM tasks
		WHERE uuid = 'f4bbff9c-8899-4ae2-bd51-7f044885384d'
		ORDER BY scheduled
	)
	UNION ALL
	(
		SELECT tasks.uuid, (task_tree.rank + 1) as rank, tasks.description, tasks.scheduled, tasks.duration
		FROM tasks, task_tree
		WHERE tasks.parent = task_tree.uuid
		      AND tasks.status = 'pending'
		ORDER BY scheduled
	)
)
SELECT REPEAT('*', rank) as rk, description, to_char(scheduled, 'MM-DD HH24:MI'::text) as scheduled, duration, uuid
FROM task_tree
-- JOINing at this point messes up rows ordering, avoiding it.
