CREATE VIEW megatasks AS
SELECT * FROM tasks as megatask
WHERE status = 'pending'
AND scheduled IS NOT NULL
AND parent IS NULL
AND (
	-- has child tasks
	EXISTS(SELECT * FROM tasks AS child WHERE child.parent = megatask.uuid)
	OR (
		-- has deps and is not a dep of anyone
		dependencies IS NOT NULL
		AND
		NOT EXISTS(
			SELECT * FROM tasks AS rdep
			WHERE megatask.uuid::text = ANY(string_to_array(rdep.dependencies, E'\n'))
		)
	)
)
ORDER BY scheduled
