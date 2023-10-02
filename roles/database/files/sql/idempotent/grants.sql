-- settings backup permissions
GRANT USAGE ON SCHEMA public TO dbbackupusers; 
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO group "dbbackupusers";
Grant select on ALL TABLES in SCHEMA public to group dbbackupusers;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO group "dbbackupusers";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO group dbbackupusers;
