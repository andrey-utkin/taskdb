parent IS NULL
AND (project IS NULL OR project = '')
AND scheduled >= '2020-02-24'
AND EXISTS (
SELECT parent_candidate.uuid
FROM tasks AS parent_candidate
WHERE
parent_candidate.tags ~ 'category|megatask'
AND parent_candidate.uuid != t.uuid
AND LOWER(parent_candidate.description) = LOWER(t.description)
)
