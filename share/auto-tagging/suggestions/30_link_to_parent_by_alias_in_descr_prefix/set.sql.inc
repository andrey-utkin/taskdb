parent = (
SELECT parent_candidate.uuid
FROM tasks AS parent_candidate
WHERE
parent_candidate.uuid != t.uuid
AND parent_candidate.alias IS NOT NULL
AND parent_candidate.alias != ''
AND t.description ~* ('^' || parent_candidate.alias || '([ :]|$)')
)
