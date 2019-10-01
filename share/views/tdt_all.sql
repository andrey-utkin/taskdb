CREATE OR REPLACE VIEW public.tdt AS
 SELECT *
   FROM public.tasks
  WHERE ((tasks.status = 'pending'::public.task_status) AND ((tasks.scheduled < (CURRENT_DATE + '24:00:00'::interval)) OR (tasks.due < (CURRENT_DATE + '24:00:00'::interval))))
  ORDER BY tasks.scheduled, tasks.due;


CREATE OR REPLACE VIEW public.tdt_report AS
 SELECT concat((('['::text || tdt.project) || '] '::text), tdt.description) AS title,
    concat((('SCHED '::text || to_char(tdt.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdt.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdt.annotation AS annot,
    tdt.uuid
   FROM public.tdt;


CREATE OR REPLACE VIEW public.tdtnw AS
 SELECT *
   FROM public.tdt
  WHERE ((tdt.project IS NULL) OR (tdt.project <> 'undo'::text));


CREATE OR REPLACE VIEW public.tdtnw_report AS
 SELECT tdtnw.description AS title,
    concat((('SCHED '::text || to_char(tdtnw.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdtnw.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdtnw.annotation AS annot,
    tdtnw.uuid
   FROM public.tdtnw;


CREATE OR REPLACE VIEW public.tdtw AS
 SELECT *
   FROM public.tdt
  WHERE (tdt.project = 'undo'::text);


CREATE OR REPLACE VIEW public.tdtw_report AS
 SELECT tdtw.description AS title,
    concat((('SCHED '::text || to_char(tdtw.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdtw.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdtw.annotation AS annot,
    tdtw.uuid
   FROM public.tdtw;
