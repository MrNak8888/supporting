-- =============================================================================
-- IT Management System - Performance Indexes
-- =============================================================================

-- users
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_branch ON users(branch(50));

-- departments
CREATE INDEX idx_departments_name ON departments(name(100));

-- positions
CREATE INDEX idx_positions_name ON positions(name(100));

-- route_requests
CREATE INDEX idx_route_requests_destination ON route_requests(destination_from(100), destination_to(100));
CREATE INDEX idx_route_requests_dates ON route_requests(start_date, end_date);
CREATE INDEX idx_route_requests_created_at ON route_requests(created_at);
CREATE INDEX idx_route_requests_requester_status ON route_requests(requester_id, status);
CREATE INDEX idx_route_requests_created_by ON route_requests(created_by);

-- transport_requests
CREATE INDEX idx_transport_requests_destination ON transport_requests(destination_from(100), destination_to(100));
CREATE INDEX idx_transport_requests_type_status ON transport_requests(request_type, status);
CREATE INDEX idx_transport_requests_created_at ON transport_requests(created_at);
CREATE INDEX idx_transport_requests_dates ON transport_requests(active_start_date, active_end_date);
CREATE INDEX idx_transport_requests_company ON transport_requests(company(50));
CREATE INDEX idx_transport_requests_route_code ON transport_requests(route_code);
CREATE INDEX idx_transport_requests_created_by ON transport_requests(created_by);

-- employee_penalties
CREATE INDEX idx_employee_penalties_employee_id ON employee_penalties(employee_id);
CREATE INDEX idx_employee_penalties_created_at ON employee_penalties(created_at);
CREATE INDEX idx_employee_penalties_amount ON employee_penalties(penalty_amount);
CREATE INDEX idx_employee_penalties_department ON employee_penalties(department(50));

-- trip_operation_reports
CREATE INDEX idx_trip_operation_reports_origin_dest ON trip_operation_reports(origin(100), destination(100));
CREATE INDEX idx_trip_operation_reports_created_at ON trip_operation_reports(created_at);
CREATE INDEX idx_trip_operation_reports_driver ON trip_operation_reports(driver_phone);
CREATE INDEX idx_trip_operation_reports_coordinator ON trip_operation_reports(coordinator_name(50));
CREATE INDEX idx_trip_operation_reports_trip_date ON trip_operation_reports(trip_date);

-- kpi_evaluations
CREATE INDEX idx_kpi_evaluations_staff_name ON kpi_evaluations(staff_name);
CREATE INDEX idx_kpi_evaluations_created_at ON kpi_evaluations(created_at);
CREATE INDEX idx_kpi_evaluations_composite ON kpi_evaluations(staff_id, evaluation_year, evaluation_month);
CREATE INDEX idx_kpi_evaluations_rating ON kpi_evaluations(performance_rating);

-- daily_performance_reports
CREATE INDEX idx_daily_performance_staff_name ON daily_performance_reports(staff_name);
CREATE INDEX idx_daily_performance_created_at ON daily_performance_reports(created_at);
CREATE INDEX idx_daily_performance_composite ON daily_performance_reports(staff_id, report_date);
CREATE INDEX idx_daily_performance_staff_date ON daily_performance_reports(staff_id, report_date, status);

-- monthly_kpi_summaries
CREATE INDEX idx_monthly_kpi_staff_name ON monthly_kpi_summaries(staff_name);
CREATE INDEX idx_monthly_kpi_created_at ON monthly_kpi_summaries(created_at);
CREATE INDEX idx_monthly_kpi_performance ON monthly_kpi_summaries(performance_rating);
CREATE INDEX idx_monthly_kpi_staff_period_rating ON monthly_kpi_summaries(staff_id, year, month, performance_rating);

-- config_module
CREATE INDEX idx_config_module_sort_order ON config_module(sort_order);

-- config_field
CREATE INDEX idx_config_field_field_type ON config_field(field_type);
CREATE INDEX idx_config_field_display_order ON config_field(display_order);

-- config_dropdown_option
CREATE INDEX idx_config_dropdown_option_sort ON config_dropdown_option(sort_order);
CREATE INDEX idx_config_dropdown_option_active ON config_dropdown_option(is_active);

-- dynamic_record
CREATE INDEX idx_dynamic_record_created_at ON dynamic_record(created_at);

-- user_activity_log
CREATE INDEX idx_user_activity_date_range ON user_activity_log(created_at, action, user_id);

-- notification_log
CREATE INDEX idx_notification_log_sent ON notification_log(status, created_at);

-- uploaded_files
CREATE INDEX idx_uploaded_files_entity_date ON uploaded_files(entity_type, entity_id, created_at);

-- Full-text search indexes (MySQL 8+)
CREATE FULLTEXT INDEX ft_route_requests_search ON route_requests(requester_name, destination_from, destination_to, remarks);
CREATE FULLTEXT INDEX ft_transport_requests_search ON transport_requests(requester_name, destination_from, destination_to, remarks);
CREATE FULLTEXT INDEX ft_employee_penalties_search ON employee_penalties(employee_name, violation_type, description);
CREATE FULLTEXT INDEX ft_trip_operation_search ON trip_operation_reports(origin, destination, vehicle_number, note);
CREATE FULLTEXT INDEX ft_kpi_evaluations_search ON kpi_evaluations(staff_name, comments, improvement_plan);
CREATE FULLTEXT INDEX ft_daily_performance_search ON daily_performance_reports(staff_name, remarks);
