parent = (
SELECT parent_candidate.uuid
FROM tasks AS parent_candidate
WHERE
parent_candidate.tags ~ 'category|megatask'
AND parent_candidate.uuid != t.uuid
AND LOWER(parent_candidate.description) = LOWER(t.description)
)
