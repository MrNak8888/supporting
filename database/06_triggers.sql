-- =============================================================================
-- IT Management System - Triggers
-- =============================================================================

DELIMITER //

-- 1. route_request_audit on INSERT
CREATE OR REPLACE TRIGGER trg_route_request_after_insert
    AFTER INSERT ON route_requests
    FOR EACH ROW
BEGIN
    INSERT INTO route_request_audit_log
        (route_request_id, action, previous_status, new_status, review_note, performed_by)
    VALUES
        (NEW.id, 'created', NULL, NEW.status, NEW.review_note, NEW.created_by);
END//

-- 2. route_request_audit on UPDATE
CREATE OR REPLACE TRIGGER trg_route_request_after_update
    AFTER UPDATE ON route_requests
    FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status OR OLD.review_note != NEW.review_note THEN
        INSERT INTO route_request_audit_log
            (route_request_id, action, previous_status, new_status, review_note, performed_by)
        VALUES
            (NEW.id,
             CASE
                 WHEN NEW.status = 'Approved' AND OLD.status != 'Approved' THEN 'approved'
                 WHEN NEW.status = 'Rejected' AND OLD.status != 'Rejected' THEN 'rejected'
                 ELSE 'updated'
             END,
             OLD.status, NEW.status, NEW.review_note, NEW.updated_by);
    END IF;
END//

-- 3. transport_request_audit on INSERT
CREATE OR REPLACE TRIGGER trg_transport_request_after_insert
    AFTER INSERT ON transport_requests
    FOR EACH ROW
BEGIN
    INSERT INTO transport_request_audit_log
        (transport_request_id, action, previous_status, new_status, review_note, performed_by)
    VALUES
        (NEW.id, 'created', NULL, NEW.status, NEW.review_note, NEW.created_by);
END//

-- 4. transport_request_audit on UPDATE
CREATE OR REPLACE TRIGGER trg_transport_request_after_update
    AFTER UPDATE ON transport_requests
    FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO transport_request_audit_log
            (transport_request_id, action, previous_status, new_status, review_note, performed_by)
        VALUES
            (NEW.id,
             CASE
                 WHEN NEW.status = 'Approved' THEN 'approved'
                 WHEN NEW.status = 'Rejected' THEN 'rejected'
                 WHEN NEW.status = 'Cancelled' THEN 'cancelled'
                 ELSE 'updated'
             END,
             OLD.status, NEW.status, NEW.review_note, NEW.updated_by);
    END IF;
END//

-- 5. employee_penalty_audit on INSERT
CREATE OR REPLACE TRIGGER trg_employee_penalty_after_insert
    AFTER INSERT ON employee_penalties
    FOR EACH ROW
BEGIN
    INSERT INTO employee_penalty_audit_log
        (penalty_id, action, previous_status, new_status, performed_by)
    VALUES
        (NEW.id, 'created', NULL, NEW.status, NEW.created_by);
END//

-- 6. employee_penalty_audit on UPDATE
CREATE OR REPLACE TRIGGER trg_employee_penalty_after_update
    AFTER UPDATE ON employee_penalties
    FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO employee_penalty_audit_log
            (penalty_id, action, previous_status, new_status, performed_by)
        VALUES
            (NEW.id,
             CASE
                 WHEN NEW.status = 'Approved' THEN 'approved'
                 WHEN NEW.status = 'Rejected' THEN 'rejected'
                 ELSE 'updated'
             END,
             OLD.status, NEW.status, NEW.updated_by);
    END IF;
END//

-- 7. Trip Operation Report audit on INSERT
CREATE OR REPLACE TRIGGER trg_trip_operation_report_after_insert
    AFTER INSERT ON trip_operation_reports
    FOR EACH ROW
BEGIN
    INSERT INTO user_activity_log
        (user_id, username, action, entity_type, entity_id, description)
    VALUES
        (NEW.created_by, NULL, 'create', 'trip_operation_report', NEW.id,
         CONCAT('Created trip report ', NEW.report_id, ': ', NEW.origin, ' -> ', NEW.destination));
END//

-- 8. Auto-calculate layover and delay durations before insert on trip_operation_reports
CREATE OR REPLACE TRIGGER trg_trip_operation_before_insert
    BEFORE INSERT ON trip_operation_reports
    FOR EACH ROW
BEGIN
    -- Calculate layover: departure_from_station - departure_time
    IF NEW.departure_time IS NOT NULL AND NEW.departure_from_station IS NOT NULL THEN
        SET NEW.layover_duration = SEC_TO_TIME(
            TIME_TO_SEC(NEW.departure_from_station) - TIME_TO_SEC(NEW.departure_time)
        );
    END IF;
    -- Calculate delay: departure_from_station - arrival_at_station
    IF NEW.arrival_at_station IS NOT NULL AND NEW.departure_from_station IS NOT NULL THEN
        SET NEW.travel_delay_duration = GREATEST(0,
            (TIME_TO_SEC(NEW.departure_from_station) - TIME_TO_SEC(NEW.arrival_at_station)) / 60
        );
    END IF;
END//

-- 9. Auto-calculate layover and delay durations before update on trip_operation_reports
CREATE OR REPLACE TRIGGER trg_trip_operation_before_update
    BEFORE UPDATE ON trip_operation_reports
    FOR EACH ROW
BEGIN
    IF NEW.departure_time IS NOT NULL AND NEW.departure_from_station IS NOT NULL THEN
        SET NEW.layover_duration = SEC_TO_TIME(
            TIME_TO_SEC(NEW.departure_from_station) - TIME_TO_SEC(NEW.departure_time)
        );
    END IF;
    IF NEW.arrival_at_station IS NOT NULL AND NEW.departure_from_station IS NOT NULL THEN
        SET NEW.travel_delay_duration = GREATEST(0,
            (TIME_TO_SEC(NEW.departure_from_station) - TIME_TO_SEC(NEW.arrival_at_station)) / 60
        );
    END IF;
END//

-- 10. Log user soft deletes in user_activity_log
CREATE OR REPLACE TRIGGER trg_user_after_soft_delete
    BEFORE UPDATE ON users
    FOR EACH ROW
BEGIN
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
        INSERT INTO user_activity_log
            (user_id, username, action, entity_type, entity_id, description)
        VALUES
            (OLD.id, OLD.username, 'soft_delete', 'user', OLD.id,
             CONCAT('User ', OLD.username, ' was deactivated'));
    END IF;
END//

DELIMITER ;
