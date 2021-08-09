CREATE ROLE rds_iam;

CREATE USER "iam_db_user";

GRANT rds_iam TO "iam_db_user";

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO rds_iam;