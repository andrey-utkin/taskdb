--
-- Name: tdtnw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtnw AS
 SELECT tdt.scheduled,
    tdt.description,
    tdt.annotation,
    tdt.project,
    tdt.priority,
    tdt.due,
    tdt.duration,
    tdt.tags,
    tdt.parent,
    tdt.dependencies,
    tdt.entry,
    tdt.modified,
    tdt.ended,
    tdt.status,
    tdt.uuid
   FROM public.tdt
  WHERE ((tdt.project IS NULL) OR (tdt.project <> 'undo'::text));


--
-- Name: tdtnw_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtnw_report AS
 SELECT tdtnw.description AS title,
    concat((('SCHED '::text || to_char(tdtnw.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdtnw.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdtnw.annotation AS annot,
    tdtnw.uuid
   FROM public.tdtnw;
