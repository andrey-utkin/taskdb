parent IS NULL
AND (project IS NULL OR project = '')
AND scheduled >= '2020-02-24'
AND EXISTS (
SELECT parent_candidate.uuid
FROM tasks AS parent_candidate
WHERE
parent_candidate.uuid != t.uuid
AND parent_candidate.alias IS NOT NULL
AND parent_candidate.alias != ''
AND t.description ~* ('^' || parent_candidate.alias || '([ :]|$)')
)
