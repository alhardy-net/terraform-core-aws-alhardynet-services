CREATE ROLE rds_iam;

CREATE USER "iam_db_user";

GRANT rds_iam TO "iam_db_user";

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO rds_iam;

ALTER DEFAULT PRIVILEGES
    FOR USER "alhardynet_admin"
    IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "iam_db_user";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, USAGE ON sequences TO "iam_db_user";