-- =============================================================================
-- Complete Database Schema for Support System
-- Generated from Flask SQLAlchemy models (app.py)
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- =============================================================================

CREATE DATABASE IF NOT EXISTS support_system
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE support_system;

-- =============================================================================
-- DROP TABLES (in dependency order)
-- =============================================================================

DROP TABLE IF EXISTS dynamic_record;
DROP TABLE IF EXISTS config_module_permission;
DROP TABLE IF EXISTS config_dropdown_option;
DROP TABLE IF EXISTS config_validation;
DROP TABLE IF EXISTS config_field;
DROP TABLE IF EXISTS config_module;
DROP TABLE IF EXISTS monthly_kpi_summaries;
DROP TABLE IF EXISTS daily_performance_reports;
DROP TABLE IF EXISTS kpi_evaluations;
DROP TABLE IF EXISTS trip_operation_reports;
DROP TABLE IF EXISTS telegram_settings;
DROP TABLE IF EXISTS employee_penalties;
DROP TABLE IF EXISTS transport_requests;
DROP TABLE IF EXISTS route_requests;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS _schema_migrations;

-- =============================================================================
-- 1. _schema_migrations - Auto-migration tracking
-- =============================================================================

CREATE TABLE _schema_migrations (
    id              INT             NOT NULL AUTO_INCREMENT,
    migration_name  VARCHAR(200)    NOT NULL,
    applied_at      DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_schema_migrations_name (migration_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 2. roles - Role-based access control
-- =============================================================================

CREATE TABLE roles (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    label           VARCHAR(100)    DEFAULT NULL,
    permissions     JSON            NOT NULL DEFAULT ('[]'),
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 3. users - System users
-- =============================================================================

CREATE TABLE users (
    id              INT             NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(100)    NOT NULL,
    username        VARCHAR(50)     NOT NULL,
    password_hash   VARCHAR(256)    NOT NULL,
    role            VARCHAR(30)     NOT NULL DEFAULT 'admin',
    role_id         INT             DEFAULT NULL,
    branch          VARCHAR(100)    DEFAULT NULL,
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_username (username),
    KEY idx_users_role (role),
    KEY idx_users_role_id (role_id),
    KEY idx_users_is_active (is_active),
    CONSTRAINT fk_users_role_id FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 4. departments - HR organizational units
-- =============================================================================

CREATE TABLE departments (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    description     TEXT            DEFAULT NULL,
    status          VARCHAR(20)     DEFAULT 'Active',
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date    DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_departments_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 5. positions - Job positions linked to departments
-- =============================================================================

CREATE TABLE positions (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    department_id   INT             NOT NULL,
    description     TEXT            DEFAULT NULL,
    status          VARCHAR(20)     DEFAULT 'Active',
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date    DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_positions_department_id (department_id),
    KEY idx_positions_status (status),
    CONSTRAINT fk_positions_department_id FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 6. config_module - Dynamic configuration module definitions
-- =============================================================================

CREATE TABLE config_module (
    id              INT             NOT NULL AUTO_INCREMENT,
    module_key      VARCHAR(100)    NOT NULL,
    module_name     VARCHAR(200)    NOT NULL,
    module_icon     VARCHAR(50)     DEFAULT 'fa-database',
    table_name      VARCHAR(100)    DEFAULT NULL,
    sort_order      INT             DEFAULT 0,
    is_active       TINYINT(1)      DEFAULT 1,
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_config_module_module_key (module_key),
    KEY idx_config_module_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 7. config_field - Dynamic field definitions per module
-- =============================================================================

CREATE TABLE config_field (
    id                  INT             NOT NULL AUTO_INCREMENT,
    module_id           INT             NOT NULL,
    field_name          VARCHAR(100)    NOT NULL,
    field_label         VARCHAR(200)    NOT NULL,
    field_type          VARCHAR(50)     NOT NULL COMMENT 'text, number, date, dropdown, textarea, checkbox, boolean, email, tel, password',
    is_required         TINYINT(1)      DEFAULT 0,
    is_unique           TINYINT(1)      DEFAULT 0,
    is_listable         TINYINT(1)      DEFAULT 1,
    is_searchable       TINYINT(1)      DEFAULT 0,
    is_sortable         TINYINT(1)      DEFAULT 1,
    is_editable         TINYINT(1)      DEFAULT 1,
    is_creatable        TINYINT(1)      DEFAULT 1,
    display_order       INT             DEFAULT 0,
    default_value       VARCHAR(500)    DEFAULT NULL,
    placeholder         VARCHAR(500)    DEFAULT NULL,
    help_text           VARCHAR(500)    DEFAULT NULL,
    min_length          INT             DEFAULT NULL,
    max_length          INT             DEFAULT NULL,
    regex_pattern       VARCHAR(500)    DEFAULT NULL,
    regex_message       VARCHAR(500)    DEFAULT NULL,
    option_source       VARCHAR(20)     DEFAULT NULL COMMENT 'static, module, api',
    option_module_id    INT             DEFAULT NULL,
    option_parent_field VARCHAR(100)    DEFAULT NULL,
    rel_module_id       INT             DEFAULT NULL,
    rel_type            VARCHAR(20)     DEFAULT NULL COMMENT 'one_to_many, many_to_one',
    grid_width          INT             DEFAULT NULL,
    PRIMARY KEY (id),
    KEY idx_config_field_module_id (module_id),
    KEY idx_config_field_option_module_id (option_module_id),
    KEY idx_config_field_rel_module_id (rel_module_id),
    CONSTRAINT fk_config_field_module_id FOREIGN KEY (module_id) REFERENCES config_module(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_config_field_option_module_id FOREIGN KEY (option_module_id) REFERENCES config_module(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_config_field_rel_module_id FOREIGN KEY (rel_module_id) REFERENCES config_module(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 8. config_validation - Field validation rules
-- =============================================================================

CREATE TABLE config_validation (
    id                  INT             NOT NULL AUTO_INCREMENT,
    field_id            INT             NOT NULL,
    validation_type     VARCHAR(50)     NOT NULL COMMENT 'required, unique, min_length, max_length, regex, custom',
    validation_value    VARCHAR(500)    DEFAULT NULL,
    error_message       VARCHAR(500)    DEFAULT NULL,
    PRIMARY KEY (id),
    KEY idx_config_validation_field_id (field_id),
    CONSTRAINT fk_config_validation_field_id FOREIGN KEY (field_id) REFERENCES config_field(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 9. config_dropdown_option - Dropdown options for fields
-- =============================================================================

CREATE TABLE config_dropdown_option (
    id              INT             NOT NULL AUTO_INCREMENT,
    field_id        INT             NOT NULL,
    option_value    VARCHAR(200)    NOT NULL,
    option_label    VARCHAR(200)    NOT NULL,
    sort_order      INT             DEFAULT 0,
    is_active       TINYINT(1)      DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_config_dropdown_option_field_id (field_id),
    CONSTRAINT fk_config_dropdown_option_field_id FOREIGN KEY (field_id) REFERENCES config_field(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 10. config_module_permission - Role-based permissions per module
-- =============================================================================

CREATE TABLE config_module_permission (
    id                  INT             NOT NULL AUTO_INCREMENT,
    module_id           INT             NOT NULL,
    role                VARCHAR(50)     NOT NULL,
    can_create          TINYINT(1)      DEFAULT 0,
    can_read            TINYINT(1)      DEFAULT 1,
    can_update          TINYINT(1)      DEFAULT 0,
    can_delete          TINYINT(1)      DEFAULT 0,
    field_permissions   JSON            DEFAULT NULL COMMENT '{"field_name": "read_only|hidden"}',
    PRIMARY KEY (id),
    KEY idx_config_module_permission_module_id (module_id),
    KEY idx_config_module_permission_role (role),
    CONSTRAINT fk_config_module_permission_module_id FOREIGN KEY (module_id) REFERENCES config_module(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 11. dynamic_record - Dynamic data storage for config modules
-- =============================================================================

CREATE TABLE dynamic_record (
    id              INT             NOT NULL AUTO_INCREMENT,
    module_id       INT             NOT NULL,
    data            JSON            NOT NULL DEFAULT ('{}'),
    is_active       TINYINT(1)      DEFAULT 1,
    created_by      INT             DEFAULT NULL,
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_by      INT             DEFAULT NULL,
    updated_date    DATETIME        DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_date    DATETIME        DEFAULT NULL,
    PRIMARY KEY (id),
    KEY idx_dynamic_record_module_id (module_id),
    KEY idx_dynamic_record_created_by (created_by),
    KEY idx_dynamic_record_updated_by (updated_by),
    KEY idx_dynamic_record_is_active (is_active),
    CONSTRAINT fk_dynamic_record_module_id FOREIGN KEY (module_id) REFERENCES config_module(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_dynamic_record_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_dynamic_record_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 12. route_requests - Route/trip requests
-- =============================================================================

CREATE TABLE route_requests (
    id              INT             NOT NULL AUTO_INCREMENT,
    request_id      VARCHAR(20)     NOT NULL,
    request_date    DATE            DEFAULT (CURRENT_DATE),
    requester_name  VARCHAR(100)    NOT NULL,
    requester_id    INT             DEFAULT NULL,
    destination_from VARCHAR(200)   NOT NULL,
    destination_to  VARCHAR(200)    NOT NULL,
    branch_location VARCHAR(200)    DEFAULT NULL,
    company         VARCHAR(200)    DEFAULT NULL,
    transportation  VARCHAR(100)    DEFAULT NULL,
    national_road   VARCHAR(50)     DEFAULT NULL,
    price           DECIMAL(12,2)   DEFAULT 0.00,
    departure_time  VARCHAR(10)     DEFAULT NULL,
    arrival_time    VARCHAR(10)     DEFAULT NULL,
    start_date      DATE            DEFAULT NULL,
    end_date        DATE            DEFAULT NULL,
    allow_access    TINYINT(1)      DEFAULT 1,
    attachment      VARCHAR(255)    DEFAULT NULL,
    remarks         TEXT            DEFAULT NULL,
    status          VARCHAR(20)     DEFAULT 'Pending',
    reviewed_by     INT             DEFAULT NULL,
    review_note     TEXT            DEFAULT NULL,
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date    DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_route_requests_request_id (request_id),
    KEY idx_route_requests_requester_id (requester_id),
    KEY idx_route_requests_status (status),
    KEY idx_route_requests_request_date (request_date),
    KEY idx_route_requests_reviewed_by (reviewed_by),
    CONSTRAINT fk_route_requests_requester_id FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_route_requests_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 13. transport_requests - Transport change requests
-- =============================================================================

CREATE TABLE transport_requests (
    id                          INT             NOT NULL AUTO_INCREMENT,
    request_id                  VARCHAR(20)     NOT NULL,
    request_date                DATE            DEFAULT (CURRENT_DATE),
    request_type                VARCHAR(30)     NOT NULL,
    requester_name              VARCHAR(100)    NOT NULL,
    requester_id                INT             DEFAULT NULL,
    destination_from            VARCHAR(200)    NOT NULL,
    destination_to              VARCHAR(200)    NOT NULL,
    transportation_type         VARCHAR(100)    DEFAULT NULL,
    change_transportation_type_to VARCHAR(100)  DEFAULT NULL,
    company                     VARCHAR(200)    DEFAULT NULL,
    change_company_to           VARCHAR(200)    DEFAULT NULL,
    branch_location             VARCHAR(200)    DEFAULT NULL,
    national_road               VARCHAR(50)     DEFAULT NULL,
    price                       DECIMAL(12,2)   DEFAULT 0.00,
    vehicle_no                  VARCHAR(50)     DEFAULT NULL,
    route_code                  VARCHAR(50)     DEFAULT NULL,
    gender_required             VARCHAR(10)     DEFAULT NULL,
    old_route_code              VARCHAR(50)     DEFAULT NULL,
    old_price                   DECIMAL(12,2)   DEFAULT 0.00,
    new_price                   DECIMAL(12,2)   DEFAULT 0.00,
    departure_time              VARCHAR(10)     DEFAULT NULL,
    arrival_time                VARCHAR(10)     DEFAULT NULL,
    duration                    VARCHAR(50)     DEFAULT NULL,
    active_start_date           DATE            DEFAULT NULL,
    active_end_date             DATE            DEFAULT NULL,
    number_of_days              INT             DEFAULT NULL,
    promotion_price             DECIMAL(12,2)   DEFAULT 0.00,
    attachments                 JSON            DEFAULT ('[]'),
    remarks                     TEXT            DEFAULT NULL,
    status                      VARCHAR(20)     DEFAULT 'Pending',
    reviewed_by                 INT             DEFAULT NULL,
    review_note                 TEXT            DEFAULT NULL,
    created_date                DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date                DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_transport_requests_request_id (request_id),
    KEY idx_transport_requests_requester_id (requester_id),
    KEY idx_transport_requests_status (status),
    KEY idx_transport_requests_request_date (request_date),
    KEY idx_transport_requests_reviewed_by (reviewed_by),
    CONSTRAINT fk_transport_requests_requester_id FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_transport_requests_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 14. employee_penalties - Employee discipline records
-- =============================================================================

CREATE TABLE employee_penalties (
    id              INT             NOT NULL AUTO_INCREMENT,
    penalty_id      VARCHAR(20)     NOT NULL,
    employee_id     VARCHAR(20)     NOT NULL,
    employee_name   VARCHAR(100)    NOT NULL,
    department      VARCHAR(100)    DEFAULT NULL,
    position        VARCHAR(100)    DEFAULT NULL,
    violation_type  VARCHAR(100)    NOT NULL,
    description     TEXT            DEFAULT NULL,
    penalty_amount  DECIMAL(12,2)   DEFAULT 0.00,
    old_code        VARCHAR(100)    DEFAULT NULL,
    evidence_file   VARCHAR(255)    DEFAULT NULL,
    incident_date   DATE            DEFAULT (CURRENT_DATE),
    approved_by     VARCHAR(100)    DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    status          VARCHAR(20)     DEFAULT 'Pending',
    created_date    DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date    DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_employee_penalties_penalty_id (penalty_id),
    KEY idx_employee_penalties_created_by (created_by),
    KEY idx_employee_penalties_status (status),
    KEY idx_employee_penalties_violation_type (violation_type),
    KEY idx_employee_penalties_incident_date (incident_date),
    CONSTRAINT fk_employee_penalties_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 15. telegram_settings - Telegram notification configuration
-- =============================================================================

CREATE TABLE telegram_settings (
    id              INT             NOT NULL AUTO_INCREMENT,
    bot_token       TEXT            DEFAULT NULL,
    chat_id         VARCHAR(100)    DEFAULT '',
    enabled         TINYINT(1)      DEFAULT 0,
    bot_username    VARCHAR(100)    DEFAULT '',
    group_name      VARCHAR(200)    DEFAULT '',
    last_test_at    DATETIME        DEFAULT NULL,
    is_connected    TINYINT(1)      DEFAULT 0,
    created_at      DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 16. trip_operation_reports - Daily trip logs
-- =============================================================================

CREATE TABLE trip_operation_reports (
    id                      INT             NOT NULL AUTO_INCREMENT,
    report_id               VARCHAR(20)     NOT NULL,
    origin                  VARCHAR(200)    DEFAULT '',
    destination             VARCHAR(200)    DEFAULT '',
    travel_direction        VARCHAR(50)     DEFAULT '',
    departure_time          VARCHAR(10)     DEFAULT NULL,
    power_off_time          VARCHAR(10)     DEFAULT NULL,
    power_on_time           VARCHAR(10)     DEFAULT NULL,
    vehicle_number          VARCHAR(50)     NOT NULL,
    driver_phone            VARCHAR(50)     DEFAULT NULL,
    arrival_at_station      VARCHAR(10)     DEFAULT NULL,
    departure_from_station  VARCHAR(10)     DEFAULT NULL,
    travel_delay_duration   DECIMAL(10,2)   DEFAULT 0.00,
    layover_duration        VARCHAR(10)     DEFAULT '',
    trip_date               DATE            DEFAULT NULL,
    reason_for_delay        TEXT            DEFAULT NULL,
    vehicle_status          VARCHAR(50)     NOT NULL,
    passenger_count         INT             DEFAULT 0,
    coordinator_name        VARCHAR(100)    DEFAULT NULL,
    note                    TEXT            DEFAULT NULL,
    created_by              INT             DEFAULT NULL,
    created_date            DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date            DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_trip_operation_reports_report_id (report_id),
    KEY idx_trip_operation_reports_created_by (created_by),
    KEY idx_trip_operation_reports_vehicle_number (vehicle_number),
    KEY idx_trip_operation_reports_vehicle_status (vehicle_status),
    CONSTRAINT fk_trip_operation_reports_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 17. kpi_evaluations - Employee KPI evaluations
-- =============================================================================

CREATE TABLE kpi_evaluations (
    id                      INT             NOT NULL AUTO_INCREMENT,
    staff_name              VARCHAR(100)    NOT NULL,
    staff_id                VARCHAR(20)     NOT NULL,
    branch                  VARCHAR(100)    DEFAULT NULL,
    company                 VARCHAR(200)    DEFAULT NULL,
    evaluation_month        INT             NOT NULL,
    evaluation_year         INT             NOT NULL,
    ticket_sales_target     DECIMAL(12,2)   DEFAULT 0.00,
    actual_tickets_sold     DECIMAL(12,2)   DEFAULT 0.00,
    achievement_pct         DECIMAL(5,2)    DEFAULT 0.00,
    ticket_sales_score      DECIMAL(5,2)    DEFAULT 0.00,
    booking_accuracy_pct    DECIMAL(5,2)    DEFAULT 0.00,
    booking_errors          INT             DEFAULT 0,
    booking_accuracy_score  DECIMAL(5,2)    DEFAULT 0.00,
    customer_satisfaction   DECIMAL(5,2)    DEFAULT 0.00,
    complaints_handled      INT             DEFAULT 0,
    customer_service_score  DECIMAL(5,2)    DEFAULT 0.00,
    late_arrivals           INT             DEFAULT 0,
    unexcused_absences      INT             DEFAULT 0,
    attendance_score        DECIMAL(5,2)    DEFAULT 0.00,
    report_submission       TEXT            DEFAULT NULL,
    daily_report_score      DECIMAL(5,2)    DEFAULT 0.00,
    sop_compliance          DECIMAL(5,2)    DEFAULT 0.00,
    sop_compliance_score    DECIMAL(5,2)    DEFAULT 0.00,
    total_score             DECIMAL(5,2)    DEFAULT 0.00,
    performance_rating      VARCHAR(30)     DEFAULT '',
    evaluator_name          VARCHAR(100)    DEFAULT NULL,
    comments                TEXT            DEFAULT NULL,
    improvement_plan        TEXT            DEFAULT NULL,
    status                  VARCHAR(20)     DEFAULT 'Draft',
    created_by              INT             DEFAULT NULL,
    created_date            DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date            DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_kpi_evaluations_staff_id (staff_id),
    KEY idx_kpi_evaluations_created_by (created_by),
    KEY idx_kpi_evaluations_status (status),
    KEY idx_kpi_evaluations_month_year (evaluation_month, evaluation_year),
    CONSTRAINT fk_kpi_evaluations_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 18. daily_performance_reports - Staff daily logs
-- =============================================================================

CREATE TABLE daily_performance_reports (
    id                  INT             NOT NULL AUTO_INCREMENT,
    staff_name          VARCHAR(100)    NOT NULL,
    staff_id            VARCHAR(20)     NOT NULL,
    branch              VARCHAR(100)    DEFAULT NULL,
    company             VARCHAR(200)    DEFAULT NULL,
    report_date         DATE            NOT NULL,
    tickets_sold        INT             DEFAULT 0,
    total_sales_amount  DECIMAL(12,2)   DEFAULT 0.00,
    bookings            INT             DEFAULT 0,
    booking_errors      INT             DEFAULT 0,
    cancelled_tickets   INT             DEFAULT 0,
    refunded_tickets    INT             DEFAULT 0,
    complaints          INT             DEFAULT 0,
    resolved_complaints INT             DEFAULT 0,
    remarks             TEXT            DEFAULT NULL,
    time_check_in       VARCHAR(10)     DEFAULT NULL,
    time_check_out      VARCHAR(10)     DEFAULT NULL,
    attendance_status   VARCHAR(20)     DEFAULT NULL,
    status              VARCHAR(20)     DEFAULT 'Draft',
    created_by          INT             DEFAULT NULL,
    created_date        DATETIME        DEFAULT CURRENT_TIMESTAMP,
    updated_date        DATETIME        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_daily_performance_staff_id (staff_id),
    KEY idx_daily_performance_created_by (created_by),
    KEY idx_daily_performance_report_date (report_date),
    KEY idx_daily_performance_status (status),
    CONSTRAINT fk_daily_performance_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 19. monthly_kpi_summaries - Auto-computed monthly KPI summaries
-- =============================================================================

CREATE TABLE monthly_kpi_summaries (
    id                      INT             NOT NULL AUTO_INCREMENT,
    staff_name              VARCHAR(100)    NOT NULL,
    staff_id                VARCHAR(20)     NOT NULL,
    branch                  VARCHAR(100)    DEFAULT NULL,
    company                 VARCHAR(200)    DEFAULT NULL,
    year                    INT             NOT NULL,
    month                   INT             NOT NULL,
    total_tickets_sold      INT             DEFAULT 0,
    total_sales_amount      DECIMAL(14,2)   DEFAULT 0.00,
    total_bookings          INT             DEFAULT 0,
    total_booking_errors    INT             DEFAULT 0,
    total_complaints        INT             DEFAULT 0,
    total_resolved_complaints INT           DEFAULT 0,
    ticket_sales_target     DECIMAL(12,2)   DEFAULT 0.00,
    ticket_sales_score      DECIMAL(5,2)    DEFAULT 0.00,
    booking_accuracy_score  DECIMAL(5,2)    DEFAULT 0.00,
    customer_service_score  DECIMAL(5,2)    DEFAULT 0.00,
    attendance_score        DECIMAL(5,2)    DEFAULT 0.00,
    daily_reporting_score   DECIMAL(5,2)    DEFAULT 0.00,
    sop_compliance_score    DECIMAL(5,2)    DEFAULT 0.00,
    total_score             DECIMAL(5,2)    DEFAULT 0.00,
    performance_rating      VARCHAR(30)     DEFAULT '',
    created_date            DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_monthly_kpi_staff_id (staff_id),
    KEY idx_monthly_kpi_year_month (year, month),
    UNIQUE KEY uk_monthly_kpi_staff_period (staff_id, year, month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
