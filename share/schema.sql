--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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
 NEW.modified := CURRENT_TIMESTAMP;
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
    priority character varying(1),
    due timestamp with time zone,
    duration integer,
    tags text,
    parent uuid,
    dependencies text,
    entry timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    modified timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    ended timestamp with time zone,
    status public.task_status DEFAULT 'pending'::public.task_status NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


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
    tasks.uuid
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
    tdt.uuid
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
-- PostgreSQL database dump complete
--

