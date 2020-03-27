status = 'pending'
AND scheduled::date <= (CURRENT_TIMESTAMP - '1 day'::interval)::date
