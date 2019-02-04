WITH RECURSIVE task_tree (uuid, rank) AS
(
	(
		SELECT tasks.uuid, 1 as rank, tasks.description
		FROM tasks
		WHERE uuid = 'f4bbff9c-8899-4ae2-bd51-7f044885384d'
		ORDER BY scheduled
	)
	UNION ALL
	(
		SELECT tasks.uuid, (task_tree.rank + 1) as rank, tasks.description
		FROM tasks, task_tree
		WHERE tasks.parent = task_tree.uuid
		      AND tasks.status = 'pending'
		ORDER BY scheduled
	)
)
SELECT uuid, REPEAT('*', rank) as rank, description
FROM task_tree
