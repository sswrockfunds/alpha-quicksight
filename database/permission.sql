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

GRANT USAGE ON SCHEMA exposure TO quicksight_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA exposure TO quicksight_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA exposure GRANT SELECT ON TABLES TO quicksight_readonly;

GRANT USAGE ON SCHEMA account TO quicksight_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA account TO quicksight_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA account GRANT SELECT ON TABLES TO quicksight_readonly;


-- Acccount write
GRANT USAGE ON SCHEMA account TO quicksight_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON account.current TO quicksight_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON account.history TO quicksight_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA account GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO quicksight_admin;


-- Permissions for views
GRANT SELECT ON quicksight.intraday TO quicksight_readonly;
GRANT SELECT ON quicksight.intraday_by_account TO quicksight_readonly;
GRANT SELECT ON quicksight.intraday_by_exchange TO quicksight_readonly;
GRANT SELECT ON quicksight.intraday_top_instruments TO quicksight_readonly;

GRANT SELECT ON quicksight.summary TO quicksight_readonly;

GRANT SELECT ON quicksight.daily TO quicksight_readonly;
GRANT SELECT ON quicksight.daily_by_exchange TO quicksight_readonly;
GRANT SELECT ON quicksight.daily_by_account TO quicksight_readonly;

GRANT SELECT ON quicksight.weekly TO quicksight_readonly;
GRANT SELECT ON quicksight.weekly_by_exchange TO quicksight_readonly;

GRANT SELECT ON quicksight.monthly TO quicksight_readonly;
GRANT SELECT ON quicksight.monthly_by_exchange TO quicksight_readonly;
