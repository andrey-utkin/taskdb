alias IS NULL
AND COALESCE(duration, 0) = 0
AND description ~ '[[]([^\[\]]+)[]]$'
AND scheduled > '2020-03-20'
