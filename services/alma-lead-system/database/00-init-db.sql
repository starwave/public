-- =============================================================
-- Alma Lead System – Database & Role Initialization
-- Target: PostgreSQL 16+
-- Run as: superuser (e.g. postgres)
-- Safe to re-run: all statements are idempotent
--
-- NOTE: The Docker postgres image automatically creates the
--       database and user from POSTGRES_DB / POSTGRES_USER /
--       POSTGRES_PASSWORD env vars. This script is provided
--       for manual / bare-metal PostgreSQL setups.
--
-- Usage:
--   sudo -u postgres psql
--   psql -U postgres -f 00-init-db.sql
--   psql -U alma_user -d alma_db -f ddl.sql
-- =============================================================

-- Create role if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'alma_user') THEN
        CREATE ROLE alma_user WITH LOGIN PASSWORD 'alma_passwd';
    END IF;
END
$$;

-- Create database if it does not exist
-- (CREATE DATABASE cannot run inside a DO block or transaction,
--  so we use dblink to execute it in a separate connection)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'alma_db') THEN
        PERFORM dblink_exec('dbname=postgres', 'CREATE DATABASE alma_db OWNER alma_user');
    END IF;
END
$$;

-- Grant privileges (safe to re-run)
GRANT ALL PRIVILEGES ON DATABASE alma_db TO alma_user;
