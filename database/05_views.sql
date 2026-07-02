-- =============================================================================
-- IT Management System - Reporting and Dashboard Views
-- =============================================================================

-- 1. v_route_request_details - Denormalized view for route request reports
CREATE OR REPLACE VIEW v_route_request_details AS
SELECT
    rr.id,
    rr.request_id,
    rr.request_date,
    rr.requester_name,
    rr.destination_from,
    rr.destination_to,
    rr.branch_location,
    rr.company,
    rr.transportation,
    rr.national_road,
    rr.price,
    rr.departure_time,
    rr.arrival_time,
    rr.start_date,
    rr.end_date,
    rr.allow_access,
    rr.status,
    rr.review_note,
    rr.created_at,
    rr.updated_at,
    creator.full_name AS created_by_name,
    updater.full_name AS updated_by_name,
    requester.full_name AS requester_full_name,
    reviewer.full_name AS reviewer_name
FROM route_requests rr
LEFT JOIN users creator ON rr.created_by = creator.id
LEFT JOIN users updater ON rr.updated_by = updater.id
LEFT JOIN users requester ON rr.requester_id = requester.id
LEFT JOIN users reviewer ON rr.reviewed_by = reviewer.id
WHERE rr.deleted_at IS NULL;

-- 2. v_transport_request_details - Denormalized view for transport request reports
CREATE OR REPLACE VIEW v_transport_request_details AS
SELECT
    tr.id,
    tr.request_id,
    tr.request_date,
    tr.request_type,
    tr.requester_name,
    tr.destination_from,
    tr.destination_to,
    tr.transportation_type,
    tr.company,
    tr.branch_location,
    tr.national_road,
    tr.price,
    tr.vehicle_no,
    tr.route_code,
    tr.departure_time,
    tr.arrival_time,
    tr.duration,
    tr.active_start_date,
    tr.active_end_date,
    tr.number_of_days,
    tr.promotion_price,
    tr.status,
    tr.review_note,
    tr.created_at,
    tr.updated_at,
    creator.full_name AS created_by_name,
    requester.full_name AS requester_full_name,
    reviewer.full_name AS reviewer_name
FROM transport_requests tr
LEFT JOIN users creator ON tr.created_by = creator.id
LEFT JOIN users requester ON tr.requester_id = requester.id
LEFT JOIN users reviewer ON tr.reviewed_by = reviewer.id
WHERE tr.deleted_at IS NULL;

-- 3. v_employee_performance_summary - Aggregated employee KPI
CREATE OR REPLACE VIEW v_employee_performance_summary AS
SELECT
    dpr.staff_id,
    dpr.staff_name,
    dpr.branch,
    dpr.company,
    COUNT(DISTINCT dpr.report_date) AS total_report_days,
    SUM(dpr.tickets_sold) AS total_tickets_sold,
    SUM(dpr.total_sales_amount) AS total_sales_amount,
    SUM(dpr.bookings) AS total_bookings,
    SUM(dpr.booking_errors) AS total_booking_errors,
    SUM(dpr.cancelled_tickets) AS total_cancelled_tickets,
    SUM(dpr.refunded_tickets) AS total_refunded_tickets,
    SUM(dpr.complaints) AS total_complaints,
    SUM(dpr.resolved_complaints) AS total_resolved_complaints,
    COUNT(DISTINCT ep.id) AS total_penalties,
    COALESCE(SUM(ep.penalty_amount), 0) AS total_penalty_amount
FROM daily_performance_reports dpr
LEFT JOIN employee_penalties ep ON dpr.staff_id = ep.employee_id
    AND ep.deleted_at IS NULL
WHERE dpr.deleted_at IS NULL
GROUP BY dpr.staff_id, dpr.staff_name, dpr.branch, dpr.company;

-- 4. v_dashboard_kpi - Dashboard KPIs at a glance
CREATE OR REPLACE VIEW v_dashboard_kpi AS
SELECT
    DATE_FORMAT(rr.created_at, '%Y-%m') AS period,
    'route_requests' AS metric,
    COUNT(*) AS total,
    SUM(CASE WHEN rr.status = 'Pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN rr.status = 'Approved' THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN rr.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected
FROM route_requests rr
WHERE rr.deleted_at IS NULL
GROUP BY DATE_FORMAT(rr.created_at, '%Y-%m')
UNION ALL
SELECT
    DATE_FORMAT(ep.created_at, '%Y-%m') AS period,
    'penalties' AS metric,
    COUNT(*) AS total,
    SUM(CASE WHEN ep.status = 'Pending' THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN ep.status = 'Approved' THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN ep.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected
FROM employee_penalties ep
WHERE ep.deleted_at IS NULL
GROUP BY DATE_FORMAT(ep.created_at, '%Y-%m')
UNION ALL
SELECT
    DATE_FORMAT(tor.created_at, '%Y-%m') AS period,
    'trip_reports' AS metric,
    COUNT(*) AS total,
    SUM(CASE WHEN tor.vehicle_status = 'Departed' THEN 1 ELSE 0 END) AS departed,
    SUM(CASE WHEN tor.vehicle_status = 'Not Departed' THEN 1 ELSE 0 END) AS not_departed,
    0 AS rejected
FROM trip_operation_reports tor
WHERE tor.deleted_at IS NULL
GROUP BY DATE_FORMAT(tor.created_at, '%Y-%m');

-- 5. v_pending_approvals - All pending items for dashboard
CREATE OR REPLACE VIEW v_pending_approvals AS
SELECT
    'route_request' AS request_type,
    rr.request_id AS identifier,
    rr.requester_name,
    rr.destination_from,
    rr.destination_to,
    rr.created_at,
    rr.status
FROM route_requests rr
WHERE rr.status = 'Pending' AND rr.deleted_at IS NULL
UNION ALL
SELECT
    'transport_request' AS request_type,
    tr.request_id AS identifier,
    tr.requester_name,
    tr.destination_from,
    tr.destination_to,
    tr.created_at,
    tr.status
FROM transport_requests tr
WHERE tr.status = 'Pending' AND tr.deleted_at IS NULL
UNION ALL
SELECT
    'penalty' AS request_type,
    ep.penalty_id AS identifier,
    ep.employee_name AS requester_name,
    ep.violation_type AS destination_from,
    ep.department AS destination_to,
    ep.created_at,
    ep.status
FROM employee_penalties ep
WHERE ep.status = 'Pending' AND ep.deleted_at IS NULL;

-- 6. v_monthly_performance_trend - Monthly trend of KPI scores
CREATE OR REPLACE VIEW v_monthly_performance_trend AS
SELECT
    staff_id,
    staff_name,
    branch,
    company,
    year,
    month,
    total_tickets_sold,
    total_sales_amount,
    total_bookings,
    total_booking_errors,
    total_score,
    performance_rating
FROM monthly_kpi_summaries
ORDER BY staff_id, year, month;
