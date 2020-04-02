CREATE OR REPLACE VIEW megatasks AS
SELECT * FROM tasks AS megatask
WHERE
status = 'pending'
AND megatask.scheduled IS NOT NULL
AND COALESCE(megatask.duration, 0) = 0
AND EXISTS ((SELECT deps(megatask.uuid)))
AND NOT EXISTS
((
SELECT * FROM rdeps(megatask.uuid) AS parent
WHERE parent.scheduled IS NOT NULL
))
ORDER BY scheduled
