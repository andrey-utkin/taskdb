CREATE VIEW conflicting AS
SELECT * FROM tasks t
WHERE
scheduled IS NOT NULL
AND status = 'pending'
AND duration > 0
AND EXISTS(
	SELECT * FROM tasks AS another_task
	WHERE
	another_task.uuid != t.uuid
	AND another_task.status = 'pending'
	AND another_task.duration > 0
	-- (StartA < EndB) and (EndA > StartB)
	-- Based on https://stackoverflow.com/a/325964
	AND t.scheduled < another_task.scheduled + (another_task.duration * '1 second'::interval)
	AND t.scheduled + (t.duration * '1 second'::interval) > another_task.scheduled
	LIMIT 1
)
ORDER BY scheduled
