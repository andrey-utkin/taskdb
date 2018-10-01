-- Run these one by one.

CREATE TABLE tasks_v2 (
    scheduled timestamp with time zone,
    description text,
    annotation text,
    project text,

    priority character varying(1),
    due timestamp with time zone,
    duration text,
    tags text,

    parent uuid,
    dependencies text,
    entry timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    modified timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    ended timestamp with time zone,

    status public.task_status DEFAULT 'pending'::public.task_status NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL

-- these are being dropped
--    started timestamp with time zone,
--    recur text,
);


INSERT INTO tasks_v2 (
scheduled,
description,
annotation,
project,
priority,
due,
duration,
tags,
parent,
dependencies,
entry,
modified,
ended,
status,
uuid
) SELECT 
scheduled,
description,
annotation,
project,
priority,
due,
duration,
tags,
parent,
dependencies,
entry,
modified,
ended,
status,
uuid
FROM tasks;

-- renames
alter table tasks rename to tasks_old_schema_20181001;
alter table tasks_v2 rename to tasks;

-- constraints and triggers track the original table across renames.
-- drop and recreate them.

ALTER TABLE ONLY public.tasks_old_schema_20181001 rename constraint tasks_pkey to tasks_pkey_old_schema_20181001;
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (uuid);

ALTER TABLE ONLY public.tasks_old_schema_20181001 rename constraint no_recur_dup to no_recur_dup_old_schema_20181001;
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT no_recur_dup UNIQUE (parent, due, scheduled, description);

ALTER TABLE ONLY public.tasks_old_schema_20181001 rename constraint tasks_parent_fkey to tasks_parent_fkey_old_schema_20181001;
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_parent_fkey FOREIGN KEY (parent) REFERENCES public.tasks(uuid) DEFERRABLE INITIALLY DEFERRED;

drop trigger changes_notify_trigger on tasks_old_schema_20181001;
CREATE TRIGGER changes_notify_trigger AFTER INSERT OR DELETE OR UPDATE ON public.tasks FOR EACH STATEMENT EXECUTE PROCEDURE public.changes_notify_fn();

drop trigger update_ended_trigger on tasks_old_schema_20181001;
CREATE TRIGGER update_ended_trigger BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.update_ended_fn();

drop trigger update_modified_trigger on tasks_old_schema_20181001;
CREATE TRIGGER update_modified_trigger BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.update_modified_fn();

drop view tdtw_report;
drop view tdtw;
drop view tdt_report;
drop view tdt;

CREATE VIEW public.tdt AS
SELECT *
   FROM public.tasks
  WHERE ((tasks.status = 'pending'::public.task_status) AND ((tasks.scheduled < (CURRENT_DATE + '24:00:00'::interval)) OR (tasks.due < (CURRENT_DATE + '24:00:00'::interval))))
  ORDER BY tasks.scheduled, tasks.due;


--
-- Name: tdt_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdt_report AS
 SELECT concat((('['::text || tdt.project) || '] '::text), tdt.description) AS title,
    concat((('SCHED '::text || to_char(tdt.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdt.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdt.annotation AS annot,
    tdt.uuid
   FROM public.tdt;


--
-- Name: tdtw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtw AS
 SELECT *
   FROM public.tdt
  WHERE (tdt.project = 'undo'::text);


--
-- Name: tdtw_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtw_report AS
 SELECT tdtw.description AS title,
    concat((('SCHED '::text || to_char(tdtw.scheduled, 'MM-DD HH24:MI'::text)) || ' '::text), ('DUE '::text || to_char(tdtw.due, 'MM-DD HH24:MI'::text))) AS sched,
    tdtw.annotation AS annot,
    tdtw.uuid
   FROM public.tdtw;



drop table tasks_old_schema_20181001;
