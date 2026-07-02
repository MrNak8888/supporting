-- =============================================================================
-- IT Management System - Master Installer
-- =============================================================================
-- Run this file to set up the complete database in order.
-- Usage:
--   SOURCE install_all.sql;
--   mysql -u root -p < install_all.sql
-- =============================================================================

-- Step 1: Create the database
SOURCE 01_create_database.sql;

-- Step 2: Create all tables (uses CREATE TABLE IF NOT EXISTS)
SOURCE 02_tables.sql;

-- Step 3: Add foreign key constraints
SOURCE 03_foreign_keys.sql;

-- Step 4: Add performance indexes
SOURCE 04_indexes.sql;

-- Step 5: Create reporting views
SOURCE 05_views.sql;

-- Step 6: Create audit and business rule triggers
SOURCE 06_triggers.sql;

-- Step 7: Seed reference and sample data
SOURCE 07_seed_data.sql;

-- Step 8: Set up RBAC permissions catalog and role-permission mappings
SOURCE 08_permissions.sql;

-- Step 9: Create stored procedures
SOURCE 09_stored_procedures.sql;

-- Step 10: Create helper functions
SOURCE 10_functions.sql;

-- Step 11: Run safe migrations for upgrading existing databases
SOURCE 11_migrations.sql;

-- =============================================================================
-- Verify installation
-- =============================================================================
SELECT 'Installation Complete' AS status;
SELECT CONCAT(TABLE_SCHEMA, '.', TABLE_NAME) AS 'Tables Created'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'support_system1'
ORDER BY TABLE_NAME;
