CREATE VIEW overdue AS
SELECT * FROM tasks
WHERE
status = 'pending'
AND (
	scheduled + (COALESCE(duration, 0) * '1 second'::interval) < CURRENT_TIMESTAMP
	OR
	due < CURRENT_TIMESTAMP
)
ORDER BY scheduled
