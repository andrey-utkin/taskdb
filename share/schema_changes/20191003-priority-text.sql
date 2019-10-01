DROP VIEW conflicting;
DROP VIEW megatasks;
DROP VIEW overdue;

DROP VIEW tdtw_report;
DROP VIEW tdtw;
DROP VIEW tdtnw_report;
DROP VIEW tdtnw;
DROP VIEW tdt_report;
DROP VIEW tdt;

ALTER TABLE tasks ALTER priority TYPE text USING priority::text;

\i ../views/conflicting.sql
\i ../views/megatasks.sql
\i ../views/overdue.sql
\i ../views/tdt_all.sql

-- Re-apply perms for newly created views
GRANT SELECT ON ALL TABLES IN SCHEMA public TO taskdb_grafana;
