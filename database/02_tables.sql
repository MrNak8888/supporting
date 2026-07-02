-- =============================================================================
-- IT Management System - Table Definitions
-- Compatible: MySQL 8.x | Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- =============================================================================

-- 1. roles - Role-based access control
CREATE TABLE IF NOT EXISTS roles (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    label           VARCHAR(100)    DEFAULT NULL,
    permissions     JSON            NOT NULL DEFAULT ('[]'),
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. users - System users / employees
CREATE TABLE IF NOT EXISTS users (
    id              INT             NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(100)    NOT NULL,
    username        VARCHAR(50)     NOT NULL,
    password_hash   VARCHAR(256)    NOT NULL,
    role            VARCHAR(30)     NOT NULL DEFAULT 'admin',
    role_id         INT             DEFAULT NULL,
    branch          VARCHAR(100)    DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    last_login_at   DATETIME        DEFAULT NULL,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_username (username),
    KEY idx_users_role (role),
    KEY idx_users_role_id (role_id),
    KEY idx_users_is_active (is_active),
    KEY idx_users_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. departments - HR organizational units
CREATE TABLE IF NOT EXISTS departments (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(50)     DEFAULT NULL,
    description     TEXT            DEFAULT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_departments_status (status),
    KEY idx_departments_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. positions - Job positions linked to departments
CREATE TABLE IF NOT EXISTS positions (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(50)     DEFAULT NULL,
    department_id   INT             NOT NULL,
    description     TEXT            DEFAULT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'Active',
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_positions_department_id (department_id),
    KEY idx_positions_status (status),
    KEY idx_positions_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. route_requests - Route/trip requests
CREATE TABLE IF NOT EXISTS route_requests (
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
    status          VARCHAR(20)     NOT NULL DEFAULT 'Pending',
    reviewed_by     INT             DEFAULT NULL,
    review_note     TEXT            DEFAULT NULL,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_route_requests_request_id (request_id),
    KEY idx_route_requests_requester_id (requester_id),
    KEY idx_route_requests_status (status),
    KEY idx_route_requests_request_date (request_date),
    KEY idx_route_requests_reviewed_by (reviewed_by),
    KEY idx_route_requests_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. transport_requests - Transport change requests
CREATE TABLE IF NOT EXISTS transport_requests (
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
    status                      VARCHAR(20)     NOT NULL DEFAULT 'Pending',
    reviewed_by                 INT             DEFAULT NULL,
    review_note                 TEXT            DEFAULT NULL,
    deleted_at                  DATETIME        DEFAULT NULL,
    created_by                  INT             DEFAULT NULL,
    updated_by                  INT             DEFAULT NULL,
    created_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_transport_requests_request_id (request_id),
    KEY idx_transport_requests_requester_id (requester_id),
    KEY idx_transport_requests_status (status),
    KEY idx_transport_requests_request_date (request_date),
    KEY idx_transport_requests_reviewed_by (reviewed_by),
    KEY idx_transport_requests_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. employee_penalties - Employee discipline records
CREATE TABLE IF NOT EXISTS employee_penalties (
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
    reviewed_by_user INT            DEFAULT NULL,
    is_recurring    TINYINT(1)      DEFAULT 0,
    status          VARCHAR(20)     NOT NULL DEFAULT 'Pending',
    deleted_at      DATETIME        DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_employee_penalties_penalty_id (penalty_id),
    KEY idx_employee_penalties_created_by (created_by),
    KEY idx_employee_penalties_status (status),
    KEY idx_employee_penalties_violation_type (violation_type),
    KEY idx_employee_penalties_incident_date (incident_date),
    KEY idx_employee_penalties_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. trip_operation_reports - Daily trip logs
CREATE TABLE IF NOT EXISTS trip_operation_reports (
    id                      INT             NOT NULL AUTO_INCREMENT,
    report_id               VARCHAR(20)     NOT NULL,
    origin                  VARCHAR(200)    DEFAULT '',
    destination             VARCHAR(200)    DEFAULT '',
    trip_date               DATE            DEFAULT NULL,
    travel_direction        VARCHAR(50)     DEFAULT '',
    departure_time          VARCHAR(10)     DEFAULT NULL,
    power_off_time          VARCHAR(10)     DEFAULT NULL,
    power_on_time           VARCHAR(10)     DEFAULT NULL,
    vehicle_number          VARCHAR(50)     NOT NULL,
    driver_phone            VARCHAR(50)     DEFAULT NULL,
    arrival_at_station      VARCHAR(10)     DEFAULT NULL,
    departure_from_station  VARCHAR(10)     DEFAULT NULL,
    travel_delay_duration   DECIMAL(8,2)    DEFAULT 0.00,
    layover_duration        VARCHAR(10)     DEFAULT '',
    reason_for_delay        TEXT            DEFAULT NULL,
    vehicle_status          VARCHAR(50)     NOT NULL,
    passenger_count         INT             DEFAULT 0,
    fuel_consumption        DECIMAL(10,2)   DEFAULT NULL,
    odometer_start          INT             DEFAULT NULL,
    odometer_end            INT             DEFAULT NULL,
    coordinator_name        VARCHAR(100)    DEFAULT NULL,
    note                    TEXT            DEFAULT NULL,
    created_by              INT             DEFAULT NULL,
    deleted_at              DATETIME        DEFAULT NULL,
    updated_by              INT             DEFAULT NULL,
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_trip_operation_reports_report_id (report_id),
    KEY idx_trip_operation_reports_created_by (created_by),
    KEY idx_trip_operation_reports_vehicle_number (vehicle_number),
    KEY idx_trip_operation_reports_vehicle_status (vehicle_status),
    KEY idx_trip_operation_reports_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. kpi_evaluations - Employee KPI evaluations
CREATE TABLE IF NOT EXISTS kpi_evaluations (
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
    evaluated_date          DATE            DEFAULT NULL,
    evaluator_name          VARCHAR(100)    DEFAULT NULL,
    comments                TEXT            DEFAULT NULL,
    improvement_plan        TEXT            DEFAULT NULL,
    status                  VARCHAR(20)     NOT NULL DEFAULT 'Draft',
    created_by              INT             DEFAULT NULL,
    deleted_at              DATETIME        DEFAULT NULL,
    updated_by              INT             DEFAULT NULL,
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_kpi_evaluations_staff_id (staff_id),
    KEY idx_kpi_evaluations_created_by (created_by),
    KEY idx_kpi_evaluations_status (status),
    KEY idx_kpi_evaluations_month_year (evaluation_month, evaluation_year),
    KEY idx_kpi_evaluations_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. daily_performance_reports - Staff daily logs
CREATE TABLE IF NOT EXISTS daily_performance_reports (
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
    time_check_in       TIME            DEFAULT NULL,
    time_check_out      TIME            DEFAULT NULL,
    attendance_status   VARCHAR(20)     DEFAULT NULL,
    status              VARCHAR(20)     NOT NULL DEFAULT 'Draft',
    created_by          INT             DEFAULT NULL,
    deleted_at          DATETIME        DEFAULT NULL,
    updated_by          INT             DEFAULT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_daily_performance_staff_id (staff_id),
    KEY idx_daily_performance_created_by (created_by),
    KEY idx_daily_performance_report_date (report_date),
    KEY idx_daily_performance_status (status),
    KEY idx_daily_performance_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. monthly_kpi_summaries - Auto-computed monthly KPI summaries
CREATE TABLE IF NOT EXISTS monthly_kpi_summaries (
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
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_monthly_kpi_staff_id (staff_id),
    KEY idx_monthly_kpi_year_month (year, month),
    UNIQUE KEY uk_monthly_kpi_staff_period (staff_id, year, month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. telegram_settings - Telegram notification configuration
CREATE TABLE IF NOT EXISTS telegram_settings (
    id              INT             NOT NULL AUTO_INCREMENT,
    bot_token       TEXT,
    chat_id         VARCHAR(100)    DEFAULT '',
    enabled         TINYINT(1)      NOT NULL DEFAULT 0,
    bot_username    VARCHAR(100)    DEFAULT '',
    group_name      VARCHAR(200)    DEFAULT '',
    last_test_at    DATETIME        NULL,
    is_connected    TINYINT(1)      NOT NULL DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. config_module - Dynamic configuration module definitions
CREATE TABLE IF NOT EXISTS config_module (
    id              INT             NOT NULL AUTO_INCREMENT,
    module_key      VARCHAR(100)    NOT NULL,
    module_name     VARCHAR(200)    NOT NULL,
    module_icon     VARCHAR(50)     DEFAULT 'fa-database',
    table_name      VARCHAR(100)    DEFAULT NULL,
    sort_order      INT             DEFAULT 0,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_config_module_module_key (module_key),
    KEY idx_config_module_is_active (is_active),
    KEY idx_config_module_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. config_field - Dynamic field definitions per module
CREATE TABLE IF NOT EXISTS config_field (
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
    deleted_at          DATETIME        DEFAULT NULL,
    created_by          INT             DEFAULT NULL,
    updated_by          INT             DEFAULT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_config_field_module_id (module_id),
    KEY idx_config_field_option_module_id (option_module_id),
    KEY idx_config_field_rel_module_id (rel_module_id),
    KEY idx_config_field_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. config_validation - Field validation rules
CREATE TABLE IF NOT EXISTS config_validation (
    id                  INT             NOT NULL AUTO_INCREMENT,
    field_id            INT             NOT NULL,
    validation_type     VARCHAR(50)     NOT NULL COMMENT 'required, unique, min_length, max_length, regex, custom',
    validation_value    VARCHAR(500)    DEFAULT NULL,
    error_message       VARCHAR(500)    DEFAULT NULL,
    deleted_at          DATETIME        DEFAULT NULL,
    created_by          INT             DEFAULT NULL,
    updated_by          INT             DEFAULT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_config_validation_field_id (field_id),
    KEY idx_config_validation_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. config_dropdown_option - Dropdown options for fields
CREATE TABLE IF NOT EXISTS config_dropdown_option (
    id              INT             NOT NULL AUTO_INCREMENT,
    field_id        INT             NOT NULL,
    option_value    VARCHAR(200)    NOT NULL,
    option_label    VARCHAR(200)    NOT NULL,
    sort_order      INT             DEFAULT 0,
    is_active       TINYINT(1)      DEFAULT 1,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_config_dropdown_option_field_id (field_id),
    KEY idx_config_dropdown_option_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. config_module_permission - Role-based permissions per module
CREATE TABLE IF NOT EXISTS config_module_permission (
    id                  INT             NOT NULL AUTO_INCREMENT,
    module_id           INT             NOT NULL,
    role                VARCHAR(50)     NOT NULL,
    role_id             INT             DEFAULT NULL,
    can_create          TINYINT(1)      DEFAULT 0,
    can_read            TINYINT(1)      DEFAULT 1,
    can_update          TINYINT(1)      DEFAULT 0,
    can_delete          TINYINT(1)      DEFAULT 0,
    field_permissions   JSON            DEFAULT NULL COMMENT '{"field_name": "read_only|hidden"}',
    deleted_at          DATETIME        DEFAULT NULL,
    created_by          INT             DEFAULT NULL,
    updated_by          INT             DEFAULT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_config_module_permission_module_id (module_id),
    KEY idx_config_module_permission_role (role),
    KEY idx_config_module_permission_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. dynamic_record - Dynamic data storage for config modules
CREATE TABLE IF NOT EXISTS dynamic_record (
    id              INT             NOT NULL AUTO_INCREMENT,
    module_id       INT             NOT NULL,
    data            JSON            NOT NULL DEFAULT ('{}'),
    is_active       TINYINT(1)      DEFAULT 1,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    deleted_at      DATETIME        DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_dynamic_record_module_id (module_id),
    KEY idx_dynamic_record_created_by (created_by),
    KEY idx_dynamic_record_updated_by (updated_by),
    KEY idx_dynamic_record_is_active (is_active),
    KEY idx_dynamic_record_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. _schema_migrations - Auto-migration tracking
CREATE TABLE IF NOT EXISTS _schema_migrations (
    id              INT             NOT NULL AUTO_INCREMENT,
    migration_name  VARCHAR(200)    NOT NULL,
    applied_at      DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_schema_migrations_name (migration_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. violation_types - Penalty violation type reference
CREATE TABLE IF NOT EXISTS violation_types (
    id                  INT             NOT NULL AUTO_INCREMENT,
    name                VARCHAR(100)    NOT NULL,
    description         TEXT            DEFAULT NULL,
    default_min_amount  DECIMAL(10,2)   DEFAULT NULL,
    default_max_amount  DECIMAL(10,2)   DEFAULT NULL,
    is_active           TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order          INT             DEFAULT 0,
    deleted_at          DATETIME        DEFAULT NULL,
    created_by          INT             DEFAULT NULL,
    updated_by          INT             DEFAULT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_violation_types_name (name),
    KEY idx_violation_types_active (is_active),
    KEY idx_violation_types_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. vehicle_statuses - Vehicle status lookup
CREATE TABLE IF NOT EXISTS vehicle_statuses (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(50)     NOT NULL,
    label           VARCHAR(100)    DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_vehicle_statuses_name (name),
    KEY idx_vehicle_statuses_active (is_active),
    KEY idx_vehicle_statuses_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 22. power_statuses - Power on/off status lookup
CREATE TABLE IF NOT EXISTS power_statuses (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(50)     NOT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_power_statuses_name (name),
    KEY idx_power_statuses_active (is_active),
    KEY idx_power_statuses_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 23. request_types - Transport request type reference
CREATE TABLE IF NOT EXISTS request_types (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    code            VARCHAR(50)     NOT NULL,
    description     TEXT            DEFAULT NULL,
    icon            VARCHAR(50)     DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_request_types_name (name),
    UNIQUE KEY uk_request_types_code (code),
    KEY idx_request_types_active (is_active),
    KEY idx_request_types_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 24. branches - Branch location reference
CREATE TABLE IF NOT EXISTS branches (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(50)     DEFAULT NULL,
    address         TEXT            DEFAULT NULL,
    phone           VARCHAR(50)     DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_branches_name (name),
    UNIQUE KEY uk_branches_code (code),
    KEY idx_branches_active (is_active),
    KEY idx_branches_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 25. companies - Company reference
CREATE TABLE IF NOT EXISTS companies (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(50)     DEFAULT NULL,
    phone           VARCHAR(50)     DEFAULT NULL,
    email           VARCHAR(100)    DEFAULT NULL,
    address         TEXT            DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_companies_name (name),
    UNIQUE KEY uk_companies_code (code),
    KEY idx_companies_active (is_active),
    KEY idx_companies_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 26. destinations - Route destination reference
CREATE TABLE IF NOT EXISTS destinations (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(50)     DEFAULT NULL,
    description     TEXT            DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_destinations_name (name),
    KEY idx_destinations_active (is_active),
    KEY idx_destinations_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 27. transportation_types - Vehicle/transport type reference
CREATE TABLE IF NOT EXISTS transportation_types (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    capacity        INT             DEFAULT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_transportation_types_name (name),
    KEY idx_transportation_types_active (is_active),
    KEY idx_transportation_types_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 28. report_submission_statuses - Daily report submission status reference
CREATE TABLE IF NOT EXISTS report_submission_statuses (
    id              INT             NOT NULL AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    score_weight    DECIMAL(5,2)    DEFAULT 0.00,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    sort_order      INT             DEFAULT 0,
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_report_submission_statuses_name (name),
    KEY idx_report_submission_statuses_active (is_active),
    KEY idx_report_submission_statuses_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 29. permissions - System permissions catalog
CREATE TABLE IF NOT EXISTS permissions (
    id              INT             NOT NULL AUTO_INCREMENT,
    code            VARCHAR(100)    NOT NULL COMMENT 'Permission code (e.g. route_request_view)',
    name            VARCHAR(200)    NOT NULL COMMENT 'Human-readable name',
    module          VARCHAR(100)    DEFAULT NULL COMMENT 'Module/group this belongs to',
    description     TEXT            DEFAULT NULL,
    is_system       TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'System permissions cannot be deleted',
    deleted_at      DATETIME        DEFAULT NULL,
    created_by      INT             DEFAULT NULL,
    updated_by      INT             DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_permissions_code (code),
    KEY idx_permissions_module (module),
    KEY idx_permissions_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 30. role_permissions - Many-to-many relationship between roles and permissions
CREATE TABLE IF NOT EXISTS role_permissions (
    id              INT             NOT NULL AUTO_INCREMENT,
    role_id         INT             NOT NULL,
    permission_id   INT             NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_permission (role_id, permission_id),
    KEY idx_role_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 31. route_request_audit_log - Approval workflow history
CREATE TABLE IF NOT EXISTS route_request_audit_log (
    id              INT             NOT NULL AUTO_INCREMENT,
    route_request_id INT            NOT NULL,
    action          VARCHAR(50)     NOT NULL COMMENT 'created, updated, approved, rejected, deleted',
    previous_status VARCHAR(20)     DEFAULT NULL,
    new_status      VARCHAR(20)     DEFAULT NULL,
    review_note     TEXT            DEFAULT NULL,
    performed_by    INT             DEFAULT NULL,
    ip_address      VARCHAR(45)     DEFAULT NULL,
    user_agent      VARCHAR(500)    DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_rr_audit_route_request_id (route_request_id),
    KEY idx_rr_audit_performed_by (performed_by),
    KEY idx_rr_audit_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 32. transport_request_audit_log - Transport approval workflow history
CREATE TABLE IF NOT EXISTS transport_request_audit_log (
    id              INT             NOT NULL AUTO_INCREMENT,
    transport_request_id INT        NOT NULL,
    action          VARCHAR(50)     NOT NULL COMMENT 'created, updated, approved, rejected, cancelled, deleted',
    previous_status VARCHAR(20)     DEFAULT NULL,
    new_status      VARCHAR(20)     DEFAULT NULL,
    review_note     TEXT            DEFAULT NULL,
    performed_by    INT             DEFAULT NULL,
    ip_address      VARCHAR(45)     DEFAULT NULL,
    user_agent      VARCHAR(500)    DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_tr_audit_transport_request_id (transport_request_id),
    KEY idx_tr_audit_performed_by (performed_by),
    KEY idx_tr_audit_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 33. employee_penalty_audit_log - Penalty workflow history
CREATE TABLE IF NOT EXISTS employee_penalty_audit_log (
    id              INT             NOT NULL AUTO_INCREMENT,
    penalty_id      INT             NOT NULL,
    action          VARCHAR(50)     NOT NULL COMMENT 'created, updated, approved, rejected, deleted',
    previous_status VARCHAR(20)     DEFAULT NULL,
    new_status      VARCHAR(20)     DEFAULT NULL,
    performed_by    INT             DEFAULT NULL,
    ip_address      VARCHAR(45)     DEFAULT NULL,
    user_agent      VARCHAR(500)    DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_penalty_audit_penalty_id (penalty_id),
    KEY idx_penalty_audit_performed_by (performed_by),
    KEY idx_penalty_audit_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 34. user_activity_log - Security audit trail
CREATE TABLE IF NOT EXISTS user_activity_log (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    user_id         INT             DEFAULT NULL,
    username        VARCHAR(50)     DEFAULT NULL,
    action          VARCHAR(100)    NOT NULL COMMENT 'login, logout, create, update, delete, export, download',
    entity_type     VARCHAR(100)    DEFAULT NULL COMMENT 'table/model name',
    entity_id       INT             DEFAULT NULL,
    description     TEXT            DEFAULT NULL,
    ip_address      VARCHAR(45)     DEFAULT NULL,
    user_agent      VARCHAR(500)    DEFAULT NULL,
    request_method  VARCHAR(10)     DEFAULT NULL,
    request_url     VARCHAR(500)    DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_activity_user_id (user_id),
    KEY idx_user_activity_username (username),
    KEY idx_user_activity_action (action),
    KEY idx_user_activity_entity (entity_type, entity_id),
    KEY idx_user_activity_created_at (created_at),
    KEY idx_user_activity_ip (ip_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 35. notification_log - Telegram notification delivery log
CREATE TABLE IF NOT EXISTS notification_log (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    notification_type VARCHAR(50)   NOT NULL COMMENT 'transport_new, penalty_approved, etc.',
    entity_type     VARCHAR(50)     DEFAULT NULL COMMENT 'transport_request, employee_penalty, etc.',
    entity_id       INT             DEFAULT NULL,
    recipient       VARCHAR(200)    DEFAULT NULL COMMENT 'chat ID or recipient identifier',
    status          VARCHAR(20)     NOT NULL DEFAULT 'pending' COMMENT 'pending, sent, failed',
    error_message   TEXT            DEFAULT NULL,
    sent_at         DATETIME        DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_notification_log_type (notification_type),
    KEY idx_notification_log_entity (entity_type, entity_id),
    KEY idx_notification_log_status (status),
    KEY idx_notification_log_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 36. uploaded_files - Centralized upload tracking
CREATE TABLE IF NOT EXISTS uploaded_files (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    original_name   VARCHAR(500)    NOT NULL,
    stored_name     VARCHAR(255)    NOT NULL,
    file_path       VARCHAR(500)    DEFAULT NULL,
    file_size       BIGINT          DEFAULT 0,
    mime_type       VARCHAR(100)    DEFAULT NULL,
    entity_type     VARCHAR(100)    DEFAULT NULL COMMENT 'route_request, transport_request, employee_penalty, etc.',
    entity_id       INT             DEFAULT NULL,
    uploaded_by     INT             DEFAULT NULL,
    deleted_at      DATETIME        DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_uploaded_files_entity (entity_type, entity_id),
    KEY idx_uploaded_files_uploaded_by (uploaded_by),
    KEY idx_uploaded_files_stored_name (stored_name),
    KEY idx_uploaded_files_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
