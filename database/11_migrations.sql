-- =============================================================================
-- IT Management System - Database Migrations
-- Safe ALTER TABLE scripts for upgrading existing databases.
-- All statements use IF NOT EXISTS or are idempotent.
-- =============================================================================

USE support_system;

-- =============================================================================
-- PART 1: ADD MISSING COLUMNS TO EXISTING TABLES
-- =============================================================================

-- 1.1 roles
ALTER TABLE roles
    ADD COLUMN IF NOT EXISTS deleted_at DATETIME DEFAULT NULL AFTER permissions,
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.2 users
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS last_login_at DATETIME DEFAULT NULL AFTER is_active,
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.3 departments
ALTER TABLE departments
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by,
    ADD COLUMN IF NOT EXISTS code VARCHAR(50) DEFAULT NULL AFTER name;

-- 1.4 positions
ALTER TABLE positions
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by,
    ADD COLUMN IF NOT EXISTS code VARCHAR(50) DEFAULT NULL AFTER name;

-- 1.5 route_requests
ALTER TABLE route_requests
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.6 transport_requests
ALTER TABLE transport_requests
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.7 employee_penalties
ALTER TABLE employee_penalties
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS reviewed_by_user INT DEFAULT NULL AFTER created_by,
    ADD COLUMN IF NOT EXISTS is_recurring TINYINT(1) DEFAULT 0 AFTER status;

-- 1.8 trip_operation_reports
ALTER TABLE trip_operation_reports
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS trip_date DATE DEFAULT NULL AFTER destination,
    ADD COLUMN IF NOT EXISTS fuel_consumption DECIMAL(10,2) DEFAULT NULL AFTER passenger_count,
    ADD COLUMN IF NOT EXISTS odometer_start INT DEFAULT NULL AFTER fuel_consumption,
    ADD COLUMN IF NOT EXISTS odometer_end INT DEFAULT NULL AFTER odometer_start;

-- 1.9 kpi_evaluations
ALTER TABLE kpi_evaluations
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS evaluated_date DATE DEFAULT NULL AFTER performance_rating;

-- 1.10 daily_performance_reports
ALTER TABLE daily_performance_reports
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS time_check_in TIME DEFAULT NULL AFTER remarks,
    ADD COLUMN IF NOT EXISTS time_check_out TIME DEFAULT NULL AFTER time_check_in,
    ADD COLUMN IF NOT EXISTS attendance_status VARCHAR(20) DEFAULT NULL AFTER time_check_out;

-- 1.11 telegram_settings
ALTER TABLE telegram_settings
    ADD COLUMN IF NOT EXISTS deleted_at DATETIME DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER deleted_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.12 config_module
ALTER TABLE config_module
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.13 config_field
ALTER TABLE config_field
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.14 config_validation
ALTER TABLE config_validation
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.15 config_dropdown_option
ALTER TABLE config_dropdown_option
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by;

-- 1.16 config_module_permission
ALTER TABLE config_module_permission
    ADD COLUMN IF NOT EXISTS created_by INT DEFAULT NULL AFTER updated_at,
    ADD COLUMN IF NOT EXISTS updated_by INT DEFAULT NULL AFTER created_by,
    ADD COLUMN IF NOT EXISTS role_id INT DEFAULT NULL AFTER role;

-- 1.17 dynamic_record
ALTER TABLE dynamic_record
    ADD COLUMN IF NOT EXISTS deleted_at DATETIME DEFAULT NULL AFTER updated_at;

-- =============================================================================
-- PART 2: ADD MISSING FOREIGN KEY CONSTRAINTS
-- =============================================================================

ALTER TABLE route_requests ADD CONSTRAINT IF NOT EXISTS fk_route_requests_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE route_requests ADD CONSTRAINT IF NOT EXISTS fk_route_requests_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE transport_requests ADD CONSTRAINT IF NOT EXISTS fk_transport_requests_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE transport_requests ADD CONSTRAINT IF NOT EXISTS fk_transport_requests_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE employee_penalties ADD CONSTRAINT IF NOT EXISTS fk_employee_penalties_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE employee_penalties ADD CONSTRAINT IF NOT EXISTS fk_employee_penalties_reviewed_by_user FOREIGN KEY (reviewed_by_user) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE trip_operation_reports ADD CONSTRAINT IF NOT EXISTS fk_trip_operation_reports_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE kpi_evaluations ADD CONSTRAINT IF NOT EXISTS fk_kpi_evaluations_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE daily_performance_reports ADD CONSTRAINT IF NOT EXISTS fk_daily_performance_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE departments ADD CONSTRAINT IF NOT EXISTS fk_departments_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE departments ADD CONSTRAINT IF NOT EXISTS fk_departments_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE positions ADD CONSTRAINT IF NOT EXISTS fk_positions_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE positions ADD CONSTRAINT IF NOT EXISTS fk_positions_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE roles ADD CONSTRAINT IF NOT EXISTS fk_roles_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE roles ADD CONSTRAINT IF NOT EXISTS fk_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE telegram_settings ADD CONSTRAINT IF NOT EXISTS fk_telegram_settings_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE telegram_settings ADD CONSTRAINT IF NOT EXISTS fk_telegram_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_module ADD CONSTRAINT IF NOT EXISTS fk_config_module_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_module ADD CONSTRAINT IF NOT EXISTS fk_config_module_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_field ADD CONSTRAINT IF NOT EXISTS fk_config_field_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_field ADD CONSTRAINT IF NOT EXISTS fk_config_field_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_validation ADD CONSTRAINT IF NOT EXISTS fk_config_validation_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_validation ADD CONSTRAINT IF NOT EXISTS fk_config_validation_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_dropdown_option ADD CONSTRAINT IF NOT EXISTS fk_config_dropdown_option_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_dropdown_option ADD CONSTRAINT IF NOT EXISTS fk_config_dropdown_option_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_module_permission ADD CONSTRAINT IF NOT EXISTS fk_config_module_permission_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE config_module_permission ADD CONSTRAINT IF NOT EXISTS fk_config_module_permission_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- =============================================================================
-- PART 3: ADD MISSING INDEXES (Using stored procedure for portability)
-- =============================================================================

DELIMITER //

DROP PROCEDURE IF EXISTS sp_create_index_if_not_exists //
CREATE PROCEDURE sp_create_index_if_not_exists(
    IN p_table_name VARCHAR(128),
    IN p_index_name VARCHAR(128),
    IN p_index_ddl TEXT
)
BEGIN
    DECLARE index_exists INT DEFAULT 0;

    SELECT COUNT(1) INTO index_exists
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = p_table_name
      AND index_name = p_index_name;

    IF index_exists = 0 THEN
        SET @ddl = p_index_ddl;
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END//

DELIMITER ;

-- users
CALL sp_create_index_if_not_exists('users', 'idx_users_created_at', 'CREATE INDEX idx_users_created_at ON users(created_at)');
CALL sp_create_index_if_not_exists('users', 'idx_users_branch', 'CREATE INDEX idx_users_branch ON users(branch(50))');

-- departments
CALL sp_create_index_if_not_exists('departments', 'idx_departments_name', 'CREATE INDEX idx_departments_name ON departments(name(100))');

-- positions
CALL sp_create_index_if_not_exists('positions', 'idx_positions_name', 'CREATE INDEX idx_positions_name ON positions(name(100))');

-- route_requests
CALL sp_create_index_if_not_exists('route_requests', 'idx_route_requests_destination', 'CREATE INDEX idx_route_requests_destination ON route_requests(destination_from(100), destination_to(100))');
CALL sp_create_index_if_not_exists('route_requests', 'idx_route_requests_dates', 'CREATE INDEX idx_route_requests_dates ON route_requests(start_date, end_date)');
CALL sp_create_index_if_not_exists('route_requests', 'idx_route_requests_created_at', 'CREATE INDEX idx_route_requests_created_at ON route_requests(created_at)');
CALL sp_create_index_if_not_exists('route_requests', 'idx_route_requests_requester_status', 'CREATE INDEX idx_route_requests_requester_status ON route_requests(requester_id, status)');
CALL sp_create_index_if_not_exists('route_requests', 'idx_route_requests_created_by', 'CREATE INDEX idx_route_requests_created_by ON route_requests(created_by)');
CALL sp_create_index_if_not_exists('route_requests', 'ft_route_requests_search', 'CREATE FULLTEXT INDEX ft_route_requests_search ON route_requests(requester_name, destination_from, destination_to, remarks)');

-- transport_requests
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_destination', 'CREATE INDEX idx_transport_requests_destination ON transport_requests(destination_from(100), destination_to(100))');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_type_status', 'CREATE INDEX idx_transport_requests_type_status ON transport_requests(request_type, status)');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_created_at', 'CREATE INDEX idx_transport_requests_created_at ON transport_requests(created_at)');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_dates', 'CREATE INDEX idx_transport_requests_dates ON transport_requests(active_start_date, active_end_date)');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_company', 'CREATE INDEX idx_transport_requests_company ON transport_requests(company(50))');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_route_code', 'CREATE INDEX idx_transport_requests_route_code ON transport_requests(route_code)');
CALL sp_create_index_if_not_exists('transport_requests', 'idx_transport_requests_created_by', 'CREATE INDEX idx_transport_requests_created_by ON transport_requests(created_by)');
CALL sp_create_index_if_not_exists('transport_requests', 'ft_transport_requests_search', 'CREATE FULLTEXT INDEX ft_transport_requests_search ON transport_requests(requester_name, destination_from, destination_to, remarks)');

-- employee_penalties
CALL sp_create_index_if_not_exists('employee_penalties', 'idx_employee_penalties_employee_id', 'CREATE INDEX idx_employee_penalties_employee_id ON employee_penalties(employee_id)');
CALL sp_create_index_if_not_exists('employee_penalties', 'idx_employee_penalties_created_at', 'CREATE INDEX idx_employee_penalties_created_at ON employee_penalties(created_at)');
CALL sp_create_index_if_not_exists('employee_penalties', 'idx_employee_penalties_amount', 'CREATE INDEX idx_employee_penalties_amount ON employee_penalties(penalty_amount)');
CALL sp_create_index_if_not_exists('employee_penalties', 'idx_employee_penalties_department', 'CREATE INDEX idx_employee_penalties_department ON employee_penalties(department(50))');
CALL sp_create_index_if_not_exists('employee_penalties', 'ft_employee_penalties_search', 'CREATE FULLTEXT INDEX ft_employee_penalties_search ON employee_penalties(employee_name, violation_type, description)');

-- trip_operation_reports
CALL sp_create_index_if_not_exists('trip_operation_reports', 'idx_trip_operation_reports_origin_dest', 'CREATE INDEX idx_trip_operation_reports_origin_dest ON trip_operation_reports(origin(100), destination(100))');
CALL sp_create_index_if_not_exists('trip_operation_reports', 'idx_trip_operation_reports_created_at', 'CREATE INDEX idx_trip_operation_reports_created_at ON trip_operation_reports(created_at)');
CALL sp_create_index_if_not_exists('trip_operation_reports', 'idx_trip_operation_reports_driver', 'CREATE INDEX idx_trip_operation_reports_driver ON trip_operation_reports(driver_phone)');
CALL sp_create_index_if_not_exists('trip_operation_reports', 'idx_trip_operation_reports_coordinator', 'CREATE INDEX idx_trip_operation_reports_coordinator ON trip_operation_reports(coordinator_name(50))');
CALL sp_create_index_if_not_exists('trip_operation_reports', 'idx_trip_operation_reports_trip_date', 'CREATE INDEX idx_trip_operation_reports_trip_date ON trip_operation_reports(trip_date)');
CALL sp_create_index_if_not_exists('trip_operation_reports', 'ft_trip_operation_search', 'CREATE FULLTEXT INDEX ft_trip_operation_search ON trip_operation_reports(origin, destination, vehicle_number, note)');

-- kpi_evaluations
CALL sp_create_index_if_not_exists('kpi_evaluations', 'idx_kpi_evaluations_staff_name', 'CREATE INDEX idx_kpi_evaluations_staff_name ON kpi_evaluations(staff_name)');
CALL sp_create_index_if_not_exists('kpi_evaluations', 'idx_kpi_evaluations_created_at', 'CREATE INDEX idx_kpi_evaluations_created_at ON kpi_evaluations(created_at)');
CALL sp_create_index_if_not_exists('kpi_evaluations', 'idx_kpi_evaluations_composite', 'CREATE INDEX idx_kpi_evaluations_composite ON kpi_evaluations(staff_id, evaluation_year, evaluation_month)');
CALL sp_create_index_if_not_exists('kpi_evaluations', 'idx_kpi_evaluations_rating', 'CREATE INDEX idx_kpi_evaluations_rating ON kpi_evaluations(performance_rating)');

-- daily_performance_reports
CALL sp_create_index_if_not_exists('daily_performance_reports', 'idx_daily_performance_staff_name', 'CREATE INDEX idx_daily_performance_staff_name ON daily_performance_reports(staff_name)');
CALL sp_create_index_if_not_exists('daily_performance_reports', 'idx_daily_performance_created_at', 'CREATE INDEX idx_daily_performance_created_at ON daily_performance_reports(created_at)');
CALL sp_create_index_if_not_exists('daily_performance_reports', 'idx_daily_performance_composite', 'CREATE INDEX idx_daily_performance_composite ON daily_performance_reports(staff_id, report_date)');
CALL sp_create_index_if_not_exists('daily_performance_reports', 'idx_daily_performance_staff_date', 'CREATE INDEX idx_daily_performance_staff_date ON daily_performance_reports(staff_id, report_date, status)');
CALL sp_create_index_if_not_exists('daily_performance_reports', 'ft_daily_performance_search', 'CREATE FULLTEXT INDEX ft_daily_performance_search ON daily_performance_reports(staff_name, remarks)');

-- monthly_kpi_summaries
CALL sp_create_index_if_not_exists('monthly_kpi_summaries', 'idx_monthly_kpi_staff_name', 'CREATE INDEX idx_monthly_kpi_staff_name ON monthly_kpi_summaries(staff_name)');
CALL sp_create_index_if_not_exists('monthly_kpi_summaries', 'idx_monthly_kpi_created_at', 'CREATE INDEX idx_monthly_kpi_created_at ON monthly_kpi_summaries(created_at)');
CALL sp_create_index_if_not_exists('monthly_kpi_summaries', 'idx_monthly_kpi_performance', 'CREATE INDEX idx_monthly_kpi_performance ON monthly_kpi_summaries(performance_rating)');
CALL sp_create_index_if_not_exists('monthly_kpi_summaries', 'idx_monthly_kpi_staff_period_rating', 'CREATE INDEX idx_monthly_kpi_staff_period_rating ON monthly_kpi_summaries(staff_id, year, month, performance_rating)');

-- config tables
CALL sp_create_index_if_not_exists('config_module', 'idx_config_module_sort_order', 'CREATE INDEX idx_config_module_sort_order ON config_module(sort_order)');
CALL sp_create_index_if_not_exists('config_field', 'idx_config_field_field_type', 'CREATE INDEX idx_config_field_field_type ON config_field(field_type)');
CALL sp_create_index_if_not_exists('config_field', 'idx_config_field_display_order', 'CREATE INDEX idx_config_field_display_order ON config_field(display_order)');
CALL sp_create_index_if_not_exists('config_dropdown_option', 'idx_config_dropdown_option_sort', 'CREATE INDEX idx_config_dropdown_option_sort ON config_dropdown_option(sort_order)');
CALL sp_create_index_if_not_exists('config_dropdown_option', 'idx_config_dropdown_option_active', 'CREATE INDEX idx_config_dropdown_option_active ON config_dropdown_option(is_active)');
CALL sp_create_index_if_not_exists('dynamic_record', 'idx_dynamic_record_created_at', 'CREATE INDEX idx_dynamic_record_created_at ON dynamic_record(created_at)');
CALL sp_create_index_if_not_exists('user_activity_log', 'idx_user_activity_date_range', 'CREATE INDEX idx_user_activity_date_range ON user_activity_log(created_at, action, user_id)');
CALL sp_create_index_if_not_exists('notification_log', 'idx_notification_log_sent', 'CREATE INDEX idx_notification_log_sent ON notification_log(status, created_at)');
CALL sp_create_index_if_not_exists('uploaded_files', 'idx_uploaded_files_entity_date', 'CREATE INDEX idx_uploaded_files_entity_date ON uploaded_files(entity_type, entity_id, created_at)');

-- =============================================================================
-- PART 4: DATA MIGRATION - Populate lookup tables from existing data
-- =============================================================================

-- 4.1 Populate violation_types from existing employee_penalties (if empty)
INSERT IGNORE INTO violation_types (name)
SELECT DISTINCT violation_type FROM employee_penalties
WHERE violation_type IS NOT NULL AND violation_type != ''
AND NOT EXISTS (SELECT 1 FROM violation_types WHERE violation_types.name = employee_penalties.violation_type);

-- 4.2 Populate vehicle_statuses from existing trip_operation_reports (if empty)
INSERT IGNORE INTO vehicle_statuses (name, label)
SELECT DISTINCT vehicle_status, vehicle_status FROM trip_operation_reports
WHERE vehicle_status IS NOT NULL AND vehicle_status != ''
AND NOT EXISTS (SELECT 1 FROM vehicle_statuses WHERE vehicle_statuses.name = trip_operation_reports.vehicle_status);

-- 4.3 Populate branches from existing users.branch (if empty)
INSERT IGNORE INTO branches (name)
SELECT DISTINCT branch FROM users
WHERE branch IS NOT NULL AND branch != ''
AND NOT EXISTS (SELECT 1 FROM branches WHERE branches.name = users.branch);

-- 4.4 Populate companies from existing route_requests (if empty)
INSERT IGNORE INTO companies (name)
SELECT DISTINCT company FROM route_requests
WHERE company IS NOT NULL AND company != ''
AND NOT EXISTS (SELECT 1 FROM companies WHERE companies.name = route_requests.company);

-- 4.5 Populate destinations from existing route_requests (if empty)
INSERT IGNORE INTO destinations (name)
SELECT DISTINCT destination_from FROM route_requests
WHERE destination_from IS NOT NULL AND destination_from != ''
AND NOT EXISTS (SELECT 1 FROM destinations WHERE destinations.name = route_requests.destination_from);

-- =============================================================================
-- PART 5: CLEANUP - Drop temporary procedure
-- =============================================================================

DROP PROCEDURE IF EXISTS sp_create_index_if_not_exists;

-- =============================================================================
-- PART 6: REMOVE LEGACY COLUMNS
-- =============================================================================

-- 6.1 Drop legacy role string column from users table
-- The RBAC system now uses role_id FK exclusively.
ALTER TABLE users DROP COLUMN IF EXISTS role;

-- =============================================================================
-- PART 7: VERIFICATION
-- =============================================================================

SELECT 'MIGRATION COMPLETE' AS status;
SELECT CONCAT('Table: ', TABLE_NAME, ' - Rows: ', TABLE_ROWS) AS table_status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'support_system'
ORDER BY TABLE_NAME;
