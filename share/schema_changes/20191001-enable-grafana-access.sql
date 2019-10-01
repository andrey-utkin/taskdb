CREATE USER taskdb_grafana PASSWORD 'taskdb_grafana';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO taskdb_grafana;
