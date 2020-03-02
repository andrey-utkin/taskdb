--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: task_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.task_status AS ENUM (
    'completed',
    'pending',
    'recurring',
    'deleted',
    'waiting',
    'cancelled'
);


--
-- Name: changes_notify_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.changes_notify_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--DECLARE
-- variables
BEGIN
 PERFORM pg_notify('CHANGES', replace(current_query(), E'\n', '\n'));
 RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    scheduled timestamp with time zone,
    description text,
    annotation text,
    project text,
    priority text,
    due timestamp with time zone,
    duration integer,
    tags text,
    parent uuid,
    dependencies text,
    entry timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    modified timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    ended timestamp with time zone,
    status public.task_status DEFAULT 'pending'::public.task_status NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    alias text
);


--
-- Name: depgraph(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.depgraph(head_uuid uuid) RETURNS SETOF public.tasks
    LANGUAGE sql
    AS $$

WITH RECURSIVE depgraph AS
(
	(
		SELECT *
		FROM tasks
		WHERE tasks.uuid = head_uuid
	)
	UNION ALL
	(
		SELECT n.*
		FROM tasks AS n, depgraph AS r
		WHERE (
		       n.parent = r.uuid
		       OR
		       r.dependencies ~ n.uuid::text
		      )
		      AND n.status IN ('pending', 'completed')
	)
)
SELECT * FROM depgraph
$$;


--
-- Name: graph(public.tasks[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.graph(selection_array public.tasks[]) RETURNS TABLE(value text, order_ integer)
    LANGUAGE sql
    AS $$

WITH
selection AS (
SELECT * FROM unnest(selection_array.*)
),
nodes AS (
SELECT '"' || selection.uuid || '" [label="' || COALESCE(selection.alias, selection.description) || '"]' AS value, 1 AS order_
FROM selection
),
edges AS (
SELECT '"' || s1.uuid || '" -> "' || dep || '"' AS value, 2 AS order_
FROM selection s1,
     LATERAL (
      SELECT unnest(string_to_array(s1.dependencies, E'\n'))
      INTERSECT
      SELECT uuid::text FROM selection
     ) AS dep
UNION
SELECT '"' || selection.parent || '" -> "' || selection.uuid || '"' AS value, 2 AS order_
FROM selection
WHERE selection.parent IN (SELECT uuid FROM selection)
),
full_graph AS (
SELECT 'digraph G {' AS value, 0 AS order_
UNION
SELECT * FROM nodes
UNION
SELECT * FROM edges
UNION
SELECT '}' AS value, 3 AS order_
)

SELECT * FROM full_graph ORDER BY order_

$$;


--
-- Name: update_ended_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_ended_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF NEW.status in ('completed', 'deleted', 'cancelled') and (TG_OP = 'INSERT' or OLD.status != NEW.status) THEN
  NEW.ended := CURRENT_TIMESTAMP;
 END IF;
 RETURN NEW;
END;
$$;


--
-- Name: update_modified_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_modified_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF (NEW.modified IS NOT DISTINCT FROM OLD.modified) THEN
  NEW.modified := CURRENT_TIMESTAMP;
 END IF;
 RETURN NEW;
END;
$$;


--
-- Name: conflicting; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.conflicting AS
 SELECT t.scheduled,
    t.description,
    t.annotation,
    t.project,
    t.priority,
    t.due,
    t.duration,
    t.tags,
    t.parent,
    t.dependencies,
    t.entry,
    t.modified,
    t.ended,
    t.status,
    t.uuid,
    t.alias
   FROM public.tasks t
  WHERE ((t.scheduled IS NOT NULL) AND (t.status = 'pending'::public.task_status) AND (t.duration > 0) AND (EXISTS ( SELECT another_task.scheduled,
            another_task.description,
            another_task.annotation,
            another_task.project,
            another_task.priority,
            another_task.due,
            another_task.duration,
            another_task.tags,
            another_task.parent,
            another_task.dependencies,
            another_task.entry,
            another_task.modified,
            another_task.ended,
            another_task.status,
            another_task.uuid,
            another_task.alias
           FROM public.tasks another_task
          WHERE ((another_task.uuid <> t.uuid) AND (another_task.status = 'pending'::public.task_status) AND (another_task.duration > 0) AND (t.scheduled < (another_task.scheduled + ((another_task.duration)::double precision * '00:00:01'::interval))) AND ((t.scheduled + ((t.duration)::double precision * '00:00:01'::interval)) > another_task.scheduled))
         LIMIT 1)))
  ORDER BY t.scheduled;


--
-- Name: megatasks; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.megatasks AS
 SELECT megatask.scheduled,
    megatask.description,
    megatask.annotation,
    megatask.project,
    megatask.priority,
    megatask.due,
    megatask.duration,
    megatask.tags,
    megatask.parent,
    megatask.dependencies,
    megatask.entry,
    megatask.modified,
    megatask.ended,
    megatask.status,
    megatask.uuid,
    megatask.alias
   FROM public.tasks megatask
  WHERE ((megatask.status = 'pending'::public.task_status) AND (megatask.parent IS NULL) AND ((EXISTS ( SELECT child.scheduled,
            child.description,
            child.annotation,
            child.project,
            child.priority,
            child.due,
            child.duration,
            child.tags,
            child.parent,
            child.dependencies,
            child.entry,
            child.modified,
            child.ended,
            child.status,
            child.uuid,
            child.alias
           FROM public.tasks child
          WHERE (child.parent = megatask.uuid))) OR ((megatask.dependencies IS NOT NULL) AND (NOT (EXISTS ( SELECT rdep.scheduled,
            rdep.description,
            rdep.annotation,
            rdep.project,
            rdep.priority,
            rdep.due,
            rdep.duration,
            rdep.tags,
            rdep.parent,
            rdep.dependencies,
            rdep.entry,
            rdep.modified,
            rdep.ended,
            rdep.status,
            rdep.uuid,
            rdep.alias
           FROM public.tasks rdep
          WHERE ((megatask.uuid)::text = ANY (string_to_array(rdep.dependencies, '
'::text)))))))))
  ORDER BY megatask.scheduled;


--
-- Name: overdue; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.overdue AS
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
    tasks.uuid,
    tasks.alias
   FROM public.tasks
  WHERE ((tasks.status = 'pending'::public.task_status) AND (((tasks.scheduled + ((COALESCE(tasks.duration, 0))::double precision * '00:00:01'::interval)) < CURRENT_TIMESTAMP) OR (tasks.due < CURRENT_TIMESTAMP)))
  ORDER BY tasks.scheduled;


--
-- Name: tdt; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdt AS
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
    tasks.uuid,
    tasks.alias
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
    tdt.uuid,
    tdt.alias
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


--
-- Name: tdtw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtw AS
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
    tdt.uuid,
    tdt.alias
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


--
-- Name: tasks alias_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT alias_unique UNIQUE (alias);


--
-- Name: tasks no_recur_dup; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT no_recur_dup UNIQUE (parent, due, scheduled, description);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (uuid);


--
-- Name: tasks changes_notify_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER changes_notify_trigger AFTER INSERT OR DELETE OR UPDATE ON public.tasks FOR EACH STATEMENT EXECUTE PROCEDURE public.changes_notify_fn();


--
-- Name: tasks update_ended_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ended_trigger BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.update_ended_fn();


--
-- Name: tasks update_modified_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_modified_trigger BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.update_modified_fn();


--
-- Name: tasks tasks_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_parent_fkey FOREIGN KEY (parent) REFERENCES public.tasks(uuid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: TABLE tasks; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tasks TO taskdb_grafana;


--
-- Name: TABLE conflicting; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.conflicting TO taskdb_grafana;


--
-- Name: TABLE megatasks; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.megatasks TO taskdb_grafana;


--
-- Name: TABLE overdue; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.overdue TO taskdb_grafana;


--
-- Name: TABLE tdt; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdt TO taskdb_grafana;


--
-- Name: TABLE tdt_report; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdt_report TO taskdb_grafana;


--
-- Name: TABLE tdtnw; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdtnw TO taskdb_grafana;


--
-- Name: TABLE tdtnw_report; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdtnw_report TO taskdb_grafana;


--
-- Name: TABLE tdtw; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdtw TO taskdb_grafana;


--
-- Name: TABLE tdtw_report; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.tdtw_report TO taskdb_grafana;


--
-- PostgreSQL database dump complete
--

