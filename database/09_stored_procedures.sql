-- =============================================================================
-- IT Management System - Stored Procedures
-- =============================================================================

DELIMITER //

-- 1. sp_compute_monthly_kpi - Aggregate daily reports into monthly KPI summary
CREATE OR REPLACE PROCEDURE sp_compute_monthly_kpi(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_staff_id VARCHAR(20);
    DECLARE v_staff_name VARCHAR(100);
    DECLARE v_branch VARCHAR(100);
    DECLARE v_company VARCHAR(200);
    DECLARE cur CURSOR FOR
        SELECT DISTINCT staff_id, staff_name, branch, company
        FROM daily_performance_reports
        WHERE YEAR(report_date) = p_year AND MONTH(report_date) = p_month
          AND deleted_at IS NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_staff_id, v_staff_name, v_branch, v_company;
        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO monthly_kpi_summaries
            (staff_name, staff_id, branch, company, year, month,
             total_tickets_sold, total_sales_amount, total_bookings,
             total_booking_errors, total_complaints, total_resolved_complaints)
        SELECT
            v_staff_name, v_staff_id, v_branch, v_company, p_year, p_month,
            SUM(tickets_sold), SUM(total_sales_amount), SUM(bookings),
            SUM(booking_errors), SUM(complaints), SUM(resolved_complaints)
        FROM daily_performance_reports
        WHERE staff_id = v_staff_id
          AND YEAR(report_date) = p_year AND MONTH(report_date) = p_month
          AND deleted_at IS NULL
        ON DUPLICATE KEY UPDATE
            total_tickets_sold = VALUES(total_tickets_sold),
            total_sales_amount = VALUES(total_sales_amount),
            total_bookings = VALUES(total_bookings),
            total_booking_errors = VALUES(total_booking_errors),
            total_complaints = VALUES(total_complaints),
            total_resolved_complaints = VALUES(total_resolved_complaints);

    END LOOP;
    CLOSE cur;
END//

-- 2. sp_generate_request_id - Generate next sequential ID for route requests
CREATE OR REPLACE PROCEDURE sp_generate_request_id(
    IN p_prefix VARCHAR(5),
    IN p_year YEAR,
    OUT p_request_id VARCHAR(20)
)
BEGIN
    DECLARE next_num INT;
    DECLARE table_name_str VARCHAR(50);

    IF p_prefix = 'RR' THEN
        SET table_name_str = 'route_requests';
        SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(request_id, '-', -1) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM route_requests
        WHERE request_id LIKE CONCAT(p_prefix, '-', p_year, '-%');
    ELSEIF p_prefix = 'TR' THEN
        SET table_name_str = 'transport_requests';
        SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(request_id, '-', -1) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM transport_requests
        WHERE request_id LIKE CONCAT(p_prefix, '-', p_year, '-%');
    ELSEIF p_prefix = 'EP' THEN
        SET table_name_str = 'employee_penalties';
        SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(penalty_id, '-', -1) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM employee_penalties
        WHERE penalty_id LIKE CONCAT(p_prefix, '-', p_year, '-%');
    ELSEIF p_prefix = 'TOR' THEN
        SET table_name_str = 'trip_operation_reports';
        SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(report_id, '-', -1) AS UNSIGNED)), 0) + 1
        INTO next_num
        FROM trip_operation_reports
        WHERE report_id LIKE CONCAT(p_prefix, '-', p_year, '-%');
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid prefix';
    END IF;

    IF next_num IS NULL OR next_num = 0 THEN
        SET next_num = 1;
    END IF;
    SET p_request_id = CONCAT(p_prefix, '-', p_year, '-', LPAD(next_num, 4, '0'));
END//

-- 3. sp_get_dashboard_stats - Get complete dashboard statistics
CREATE OR REPLACE PROCEDURE sp_get_dashboard_stats(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Route Request Stats
    SELECT
        COUNT(*) AS total_requests,
        SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_requests,
        SUM(CASE WHEN status = 'Approved' THEN 1 ELSE 0 END) AS approved_requests,
        SUM(CASE WHEN status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_requests
    FROM route_requests
    WHERE (p_start_date IS NULL OR created_at >= p_start_date)
      AND (p_end_date IS NULL OR created_at <= p_end_date)
      AND deleted_at IS NULL;

    -- Penalty Stats
    SELECT
        COUNT(*) AS total_penalties,
        COALESCE(SUM(penalty_amount), 0) AS total_penalty_amount,
        SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_penalties
    FROM employee_penalties
    WHERE (p_start_date IS NULL OR created_at >= p_start_date)
      AND (p_end_date IS NULL OR created_at <= p_end_date)
      AND deleted_at IS NULL;

    -- Trip Report Stats
    SELECT
        COUNT(*) AS total_reports,
        SUM(CASE WHEN vehicle_status = 'Departed' THEN 1 ELSE 0 END) AS departed_reports,
        SUM(CASE WHEN vehicle_status = 'Not Departed' THEN 1 ELSE 0 END) AS not_departed_reports,
        COALESCE(SUM(passenger_count), 0) AS total_passengers
    FROM trip_operation_reports
    WHERE (p_start_date IS NULL OR created_at >= p_start_date)
      AND (p_end_date IS NULL OR created_at <= p_end_date)
      AND deleted_at IS NULL;

    -- Transport Request Stats
    SELECT
        COUNT(*) AS total_transport_requests,
        SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_transport_requests
    FROM transport_requests
    WHERE (p_start_date IS NULL OR created_at >= p_start_date)
      AND (p_end_date IS NULL OR created_at <= p_end_date)
      AND deleted_at IS NULL;
END//

-- 4. sp_cleanup_soft_deleted - Permanently delete records soft-deleted for more than N days
CREATE OR REPLACE PROCEDURE sp_cleanup_soft_deleted(
    IN p_days INT
)
BEGIN
    DECLARE cutoff DATETIME;
    SET cutoff = DATE_SUB(NOW(), INTERVAL p_days DAY);

    DELETE FROM route_requests WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM transport_requests WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM employee_penalties WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM trip_operation_reports WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM kpi_evaluations WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM daily_performance_reports WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM config_module WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM config_field WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM config_validation WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM config_dropdown_option WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM config_module_permission WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM dynamic_record WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM departments WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM positions WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM users WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM roles WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
    DELETE FROM uploaded_files WHERE deleted_at IS NOT NULL AND deleted_at < cutoff;
END//

-- 5. sp_audit_user_login - Record user login activity
CREATE OR REPLACE PROCEDURE sp_audit_user_login(
    IN p_user_id INT,
    IN p_username VARCHAR(50),
    IN p_ip_address VARCHAR(45),
    IN p_user_agent VARCHAR(500)
)
BEGIN
    INSERT INTO user_activity_log
        (user_id, username, action, entity_type, entity_id, description, ip_address, user_agent)
    VALUES
        (p_user_id, p_username, 'login', 'user', p_user_id,
         CONCAT('User ', p_username, ' logged in'), p_ip_address, p_user_agent);

    UPDATE users SET last_login_at = NOW() WHERE id = p_user_id;
END//

DELIMITER ;
