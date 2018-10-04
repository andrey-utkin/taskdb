CREATE OR REPLACE VIEW public.tdt AS
 SELECT tasks.scheduled,
    tasks.description,
    tasks.annotation,
    tasks.project,
    tasks.priority,
    tasks.due,
    tasks.duration,
    tasks.tags,
    tasks.parent,
    tasks.dependencies,
    tasks.entry,
    tasks.modified,
    tasks.ended,
    tasks.status,
    tasks.uuid
   FROM tasks
  WHERE ((tasks.status = 'pending'::task_status) AND ((tasks.scheduled < (CURRENT_TIMESTAMP + '24:00:00'::interval)) OR (tasks.due < (CURRENT_TIMESTAMP + '24:00:00'::interval))))
  ORDER BY tasks.scheduled, tasks.due;
