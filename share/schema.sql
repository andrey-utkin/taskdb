--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

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
-- Name: update_ended_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_ended_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF NEW.status in ('completed', 'deleted', 'cancelled') THEN
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
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    status public.task_status DEFAULT 'pending'::public.task_status NOT NULL,
    project text,
    tags text,
    description text,
    entry timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    modified timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    started timestamp with time zone,
    ended timestamp with time zone,
    scheduled timestamp with time zone,
    due timestamp with time zone,
    recur text,
    annotation text,
    parent uuid,
    dependencies text,
    duration text,
    priority character varying(1)
);


--
-- Name: tdt; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdt AS
 SELECT tasks.uuid,
    tasks.status,
    tasks.project,
    tasks.tags,
    tasks.description,
    tasks.entry,
    tasks.modified,
    tasks.started,
    tasks.ended,
    tasks.scheduled,
    tasks.due,
    tasks.recur,
    tasks.annotation,
    tasks.parent,
    tasks.dependencies,
    tasks.duration,
    tasks.priority
   FROM public.tasks
  WHERE ((tasks.status = 'pending'::public.task_status) AND ((tasks.scheduled < (CURRENT_DATE + '24:00:00'::interval)) OR (tasks.due < (CURRENT_DATE + '24:00:00'::interval))))
  ORDER BY tasks.scheduled, tasks.due;


--
-- Name: tdt_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdt_report AS
 SELECT ((('['::text || tdt.project) || '] '::text) || tdt.description) AS title,
    concat('SCHED ', to_char(tdt.scheduled, 'MM-DD HH24:MI'::text), ' DUE ', to_char(tdt.due, 'MM-DD HH24:MI'::text)) AS sched,
    tdt.annotation AS annot,
    tdt.uuid
   FROM public.tdt;


--
-- Name: tdtw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtw AS
 SELECT tdt.uuid,
    tdt.status,
    tdt.project,
    tdt.tags,
    tdt.description,
    tdt.entry,
    tdt.modified,
    tdt.started,
    tdt.ended,
    tdt.scheduled,
    tdt.due,
    tdt.recur,
    tdt.annotation,
    tdt.parent,
    tdt.dependencies,
    tdt.duration,
    tdt.priority
   FROM public.tdt
  WHERE (tdt.project = 'undo'::text);


--
-- Name: tdtw_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tdtw_report AS
 SELECT tdtw.description AS title,
    to_char(tdtw.scheduled, 'MM-DD HH24:MI'::text) AS sched,
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

