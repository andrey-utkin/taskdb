DROP VIEW conflicting;
DROP VIEW megatasks;
DROP VIEW overdue;

DROP VIEW tdtw_report;
DROP VIEW tdtw;
DROP VIEW tdtnw_report;
DROP VIEW tdtnw;
DROP VIEW tdt_report;
DROP VIEW tdt;

ALTER TABLE tasks ADD alias text DEFAULT NULL;
ALTER TABLE tasks ADD CONSTRAINT alias_unique UNIQUE (alias);

\i ../views/conflicting.sql
\i ../views/megatasks.sql
\i ../views/overdue.sql
\i ../views/tdt_all.sql

-- Re-apply perms for newly created views
GRANT SELECT ON ALL TABLES IN SCHEMA public TO taskdb_grafana;
