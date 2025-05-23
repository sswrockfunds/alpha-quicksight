-- Grant the role to users
GRANT quicksight_readonly TO quicksight_admin, quicksight_connect;
GRANT quicksight_write TO quicksight_admin;


-- Full access to everything in QuickSight Schema
GRANT USAGE, CREATE ON SCHEMA quicksight TO quicksight_write;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA quicksight TO quicksight_write;
ALTER DEFAULT PRIVILEGES IN SCHEMA quicksight GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO quicksight_write;

-- READONLY Permissions
GRANT USAGE ON SCHEMA quicksight TO quicksight_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA quicksight TO quicksight_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA quicksight GRANT SELECT ON TABLES TO quicksight_readonly;

GRANT USAGE ON SCHEMA cryptostruct TO quicksight_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA cryptostruct TO quicksight_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA cryptostruct GRANT SELECT ON TABLES TO quicksight_readonly;

GRANT USAGE ON SCHEMA alpha TO quicksight_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA alpha TO quicksight_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA alpha GRANT SELECT ON TABLES TO quicksight_readonly;

-- Permissions for views
GRANT SELECT ON quicksight.intraday_top_instruments TO quicksight_readonly;
