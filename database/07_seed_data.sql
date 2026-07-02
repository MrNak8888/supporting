-- =============================================================================
-- IT Management System - Seed / Reference Data
-- =============================================================================

-- Roles (permissions JSON column used by the Python app for backward compatibility)
INSERT INTO roles (id, name, label, permissions) VALUES
(1, 'admin',           'Administrator',    JSON_ARRAY('dashboard_view','dashboard_edit','dashboard_download','route_request_view','route_request_create','route_request_edit','route_request_delete','route_request_approve','route_request_reject','route_request_download','transport_request_view','transport_request_create','transport_request_edit','transport_request_delete','transport_request_approve','transport_request_reject','transport_request_download','penalty_view','penalty_create','penalty_edit','penalty_delete','penalty_download','trip_operation_report_view','trip_operation_report_create','trip_operation_report_edit','trip_operation_report_delete','trip_operation_report_download','report_view','report_create','report_edit','report_delete','report_export','report_print','report_download','system_settings_view','system_settings_edit','system_settings_update','department_view','department_create','department_edit','department_delete','department_download','position_view','position_create','position_edit','position_delete','position_download','role_view','role_create','role_edit','role_delete','role_assign_permissions','role_download','user_view','user_create','user_edit','user_delete','user_assign_roles','user_reset_password','user_activate','user_deactivate','user_download')),
(2, 'regional_manager','Regional Manager', JSON_ARRAY('dashboard_view','route_request_view','route_request_approve','route_request_reject','route_request_download','transport_request_view','transport_request_approve','transport_request_reject','transport_request_download','penalty_view','penalty_edit','penalty_download','trip_operation_report_view','trip_operation_report_download','report_view','report_export','report_download','department_view','position_view')),
(3, 'branch_manager',  'Branch Manager',   JSON_ARRAY('dashboard_view','route_request_view','route_request_create','route_request_edit','transport_request_view','transport_request_create','transport_request_edit','trip_operation_report_view','trip_operation_report_create','trip_operation_report_edit')),
(4, 'hr_manager',      'HR Manager',       JSON_ARRAY('dashboard_view','penalty_view','penalty_create','penalty_edit','penalty_download','transport_request_view','department_view','department_create','department_edit','position_view','position_create','position_edit','report_view','report_export','report_download')),
(5, 'it_staff',        'IT Staff',         JSON_ARRAY('dashboard_view','route_request_view','route_request_download','transport_request_view','transport_request_download','trip_operation_report_view','trip_operation_report_download','report_view','report_export','report_download'));

-- Departments
INSERT INTO departments (id, name, description) VALUES
(1, 'Administration',   'Corporate administration and executive management'),
(2, 'Operations',       'Transport operations and logistics management'),
(3, 'Human Resources',  'Employee relations, recruitment, and compliance'),
(4, 'Finance',          'Financial planning, accounting, and budgeting'),
(5, 'Information Technology', 'IT infrastructure, systems, and support'),
(6, 'Sales & Marketing','Ticket sales, promotions, and customer acquisition'),
(7, 'Customer Service', 'Customer support, complaints, and satisfaction');

-- Positions
INSERT INTO positions (id, name, department_id, description) VALUES
(1,  'General Manager',          1, 'Overall management of the organization'),
(2,  'Operations Manager',       2, 'Oversees daily transport operations'),
(3,  'HR Manager',               3, 'Leads the human resources department'),
(4,  'Finance Manager',          4, 'Manages financial operations'),
(5,  'IT Manager',               5, 'Oversees IT systems and infrastructure'),
(6,  'Sales Manager',            6, 'Leads sales and marketing team'),
(7,  'Customer Service Manager', 7, 'Manages customer support team'),
(8,  'Route Coordinator',        2, 'Coordinates route scheduling and changes'),
(9,  'Bus Driver',               2, 'Operates assigned vehicle routes'),
(10, 'Ticket Sales Agent',       6, 'Sells tickets and assists passengers'),
(11, 'Customer Service Rep',     7, 'Handles customer inquiries and issues'),
(12, 'Accountant',               4, 'Manages accounts and records'),
(13, 'IT Support Specialist',    5, 'Provides technical support'),
(14, 'HR Assistant',             3, 'Assists with HR operations');

-- Users (password for all: Password123!)
INSERT INTO users (id, full_name, username, password_hash, role, role_id, branch, is_active) VALUES
(1,  'Admin User',      'admin',      'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'admin',           1, 'Phnom Penh', 1),
(2,  'Sok Chan Pheak',  'sokchan',    'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'regional_manager', 2, 'Battambang', 1),
(3,  'Heng Vibol',       'hengvibol',  'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'branch_manager',   3, 'Siem Reap',  1),
(4,  'Chea Srey Mom',    'cheasrey',   'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'hr_manager',       4, 'Phnom Penh', 1),
(5,  'Meas Sophea',      'meassophea', 'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'it_staff',         5, 'Phnom Penh', 1),
(6,  'Sorn Bora',        'sornbora',   'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'branch_manager',   3, 'Sihanoukville', 1),
(7,  'Nop Rithy',        'noprithy',   'scrypt:32768:8:1$DmyM1UUWY6Xk98om$2e7c53628a07c08376e7b71f257ae4e7ef5d72596d6b23e8e7d2a40c9f09e2e6e6e8a9b4c6d2f3a5b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f', 'regional_manager', 2, 'Phnom Penh', 1);

-- Route Requests
INSERT INTO route_requests (request_id, request_date, requester_name, requester_id, destination_from, destination_to, branch_location, company, transportation, national_road, price, departure_time, arrival_time, start_date, end_date, status, reviewed_by, review_note) VALUES
('RR-2024-0001', '2024-06-01', 'Heng Vibol',   3, 'Phnom Penh',  'Siem Reap',    'Siem Reap',  'ABC Transport', 'Bus',  'NR6', 25.00, '07:00', '13:00', '2024-06-10', '2024-06-10', 'Approved', 2, 'Route approved as requested'),
('RR-2024-0002', '2024-06-05', 'Sorn Bora',    6, 'Phnom Penh',  'Sihanoukville','Sihanoukville','XYZ Travel', 'Van',  'NR4', 18.00, '08:30', '12:30', '2024-06-15', '2024-06-15', 'Approved', 2, 'Approved per schedule'),
('RR-2024-0003', '2024-06-10', 'Heng Vibol',   3, 'Siem Reap',   'Phnom Penh',   'Siem Reap',  'ABC Transport', 'Bus',  'NR6', 25.00, '06:00', '12:00', '2024-06-20', '2024-06-20', 'Pending',  NULL, NULL),
('RR-2024-0004', '2024-06-12', 'Sorn Bora',    6, 'Sihanoukville','Phnom Penh',  'Sihanoukville','XYZ Travel', 'Bus',  'NR4', 18.00, '09:00', '13:00', '2024-06-22', '2024-06-22', 'Rejected', 2, 'Route overlaps with existing service'),
('RR-2024-0005', '2024-06-15', 'Admin User',   1, 'Phnom Penh',  'Battambang',   'Phnom Penh', 'Mekong Express', 'Bus', 'NR5', 20.00, '07:30', '12:30', '2024-06-25', '2024-06-25', 'Approved', 2, 'Approved'),
('RR-2024-0006', '2024-06-18', 'Sorn Bora',    6, 'Phnom Penh',  'Kampot',       'Sihanoukville','Local Lines', 'Minibus', 'NR3', 15.00, '06:00', '10:00', '2024-06-28', '2024-06-28', 'Pending',  NULL, NULL),
('RR-2024-0007', '2024-06-20', 'Heng Vibol',   3, 'Siem Reap',   'Poipet',       'Siem Reap',  'Border Express', 'Bus', 'NR6', 22.00, '08:00', '14:00', '2024-07-01', '2024-07-01', 'Approved', 2, 'Approved for border route'),
('RR-2024-0008', '2024-06-22', 'Admin User',   1, 'Phnom Penh',  'Kratie',       'Phnom Penh', 'Eastern Travel', 'Bus', 'NR7', 28.00, '06:30', '12:30', '2024-07-05', '2024-07-05', 'Pending',  NULL, NULL);

-- Transport Requests
INSERT INTO transport_requests (request_id, request_date, request_type, requester_name, requester_id, destination_from, destination_to, transportation_type, company, price, vehicle_no, route_code, status, reviewed_by) VALUES
('TR-2024-0001', '2024-06-02', 'change_type',   'Heng Vibol',   3, 'Phnom Penh', 'Siem Reap',     'Bus',       'ABC Transport',  25.00, 'PP-1234', 'PP-SR-01', 'Approved', 2),
('TR-2024-0002', '2024-06-08', 'change_price',  'Sorn Bora',    6, 'Phnom Penh', 'Sihanoukville', 'Van',       'XYZ Travel',     18.00, 'PP-5678', 'PP-SH-02', 'Pending',  NULL),
('TR-2024-0003', '2024-06-14', 'new_route',     'Admin User',   1, 'Battambang', 'Pailin',        'Minibus',   'Western Express', 12.00, 'BT-9012', 'BT-PL-01', 'Approved', 2),
('TR-2024-0004', '2024-06-16', 'change_type',   'Sorn Bora',    6, 'Phnom Penh', 'Kampot',        'Bus',       'Local Lines',     15.00, 'PP-3456', 'PP-KP-03', 'Rejected', 2);

-- Employee Penalties
INSERT INTO employee_penalties (penalty_id, employee_id, employee_name, department, position, violation_type, description, penalty_amount, incident_date, status, created_by) VALUES
('EP-2024-0001', 'EMP-001', 'Sok Dara',     'Operations',      'Bus Driver',        'Late Arrival',       'Arrived 45 minutes late for scheduled departure without prior notice',                                     50.00, '2024-06-05', 'Approved', 4),
('EP-2024-0002', 'EMP-002', 'Lim Socheata',  'Customer Service', 'Customer Service Rep', 'Customer Complaint', 'Received 3 unresolved customer complaints in one week about rude behavior',                               30.00, '2024-06-10', 'Pending', 4),
('EP-2024-0003', 'EMP-003', 'Van Dara',      'Sales & Marketing','Ticket Sales Agent',   'Cash Handling Error',  'Cash discrepancy of $120 found during end-of-day reconciliation',                                         100.00, '2024-06-12', 'Approved', 4),
('EP-2024-0004', 'EMP-004', 'Chea Rithy',    'Operations',      'Bus Driver',        'Accident',           'Minor collision while reversing at the station - no injuries reported',                                    75.00, '2024-06-15', 'Pending', 4),
('EP-2024-0005', 'EMP-005', 'Neang Pisey',   'Sales & Marketing','Ticket Sales Agent',   'Unauthorized Discount', 'Gave unauthorized 50% discount to a passenger without managerial approval',                                60.00, '2024-06-18', 'Approved', 4);

-- Trip Operation Reports
INSERT INTO trip_operation_reports (report_id, trip_date, origin, destination, travel_direction, departure_time, power_off_time, power_on_time, vehicle_number, driver_phone, arrival_at_station, departure_from_station, travel_delay_duration, vehicle_status, passenger_count, coordinator_name, created_by) VALUES
('TOR-2024-0001', '2024-06-01', 'Phnom Penh', 'Siem Reap',     'One Way',       '07:00', '07:05', '12:55', 'PP-1234', '012 345 678', '13:00', '13:15', 0.00, 'Departed',    45, 'Sok Vanna',   1),
('TOR-2024-0002', '2024-06-01', 'Siem Reap',  'Phnom Penh',    'Round Trip',    '06:00', '06:10', '11:50', 'SR-5678', '012 987 654', '12:00', '12:20', 15.00, 'Not Departed',38, 'Chea Sary',   3),
('TOR-2024-0003', '2024-06-02', 'Phnom Penh', 'Sihanoukville', 'One Way',       '08:30', '08:35', '12:25', 'PP-9012', '016 555 777', '12:30', '12:45', 10.00, 'Departed',    52, 'Heng Kim',    6),
('TOR-2024-0004', '2024-06-02', 'Battambang', 'Phnom Penh',    'One Way',       '05:30', '05:40', '10:20', 'BT-3456', '017 222 333', '10:30', '10:45', 20.00, 'Departed',    30, 'Soy Maly',    2),
('TOR-2024-0005', '2024-06-03', 'Phnom Penh', 'Kampot',        'Round Trip',    '06:00', '06:05', '09:55', 'PP-7890', '015 444 888', '10:00', '10:15', 5.00,  'Departed',    25, 'Rath Som',    1);

-- Daily Performance Reports
INSERT INTO daily_performance_reports (staff_name, staff_id, branch, company, report_date, tickets_sold, total_sales_amount, bookings, booking_errors, cancelled_tickets, refunded_tickets, complaints, resolved_complaints, status, created_by) VALUES
('Van Dara',     'EMP-003', 'Phnom Penh',  'ABC Transport',   '2024-06-01', 45,  1125.00, 38, 2, 3, 1, 2, 2, 'Submitted', 1),
('Neang Pisey',  'EMP-005', 'Siem Reap',   'ABC Transport',   '2024-06-01', 32,   800.00, 28, 1, 1, 0, 1, 1, 'Submitted', 3),
('Van Dara',     'EMP-003', 'Phnom Penh',  'ABC Transport',   '2024-06-02', 52,  1300.00, 45, 3, 2, 0, 3, 2, 'Submitted', 1),
('Neang Pisey',  'EMP-005', 'Siem Reap',   'ABC Transport',   '2024-06-02', 28,   700.00, 25, 0, 0, 0, 0, 0, 'Submitted', 3),
('Van Dara',     'EMP-003', 'Phnom Penh',  'ABC Transport',   '2024-06-03', 38,   950.00, 32, 1, 1, 0, 1, 1, 'Draft',    1),
('Neang Pisey',  'EMP-005', 'Siem Reap',   'ABC Transport',   '2024-06-03', 35,   875.00, 30, 2, 2, 1, 2, 1, 'Submitted', 3),
('Sok Dara',     'EMP-001', 'Battambang',  'Western Express', '2024-06-01', 20,   500.00, 18, 0, 0, 0, 0, 0, 'Submitted', 2),
('Lim Socheata', 'EMP-002', 'Phnom Penh',  'ABC Transport',   '2024-06-01', 0,     0.00,  0, 0, 0, 0, 5, 3, 'Submitted', 1);

-- KPI Evaluations
INSERT INTO kpi_evaluations (staff_name, staff_id, branch, company, evaluation_month, evaluation_year, ticket_sales_target, actual_tickets_sold, achievement_pct, ticket_sales_score, booking_accuracy_pct, booking_errors, booking_accuracy_score, customer_satisfaction, complaints_handled, customer_service_score, late_arrivals, unexcused_absences, attendance_score, daily_report_score, sop_compliance, sop_compliance_score, total_score, performance_rating, evaluator_name, status, created_by) VALUES
('Van Dara',     'EMP-003', 'Phnom Penh', 'ABC Transport',   6, 2024, 1000, 1350, 135.00, 40.00, 95.00, 6, 18.00, 4.5, 6, 14.00, 2, 0, 10.00, 9.00, 98.00, 5.00, 96.00, 'Excellent',       'Admin User', 'Submitted', 1),
('Neang Pisey',  'EMP-005', 'Siem Reap',  'ABC Transport',   6, 2024, 900,   950, 105.56, 38.00, 96.67, 3, 19.00, 4.2, 3, 13.00, 1, 0, 10.00, 8.00, 95.00, 4.50, 92.50, 'Excellent',       'Admin User', 'Submitted', 1),
('Sok Dara',     'EMP-001', 'Battambang','Western Express',  6, 2024, 600,   500,  83.33, 30.00, 90.00, 2, 17.00, 4.0, 0, 12.00, 3, 1,  7.00, 7.00, 85.00, 4.00, 77.00, 'Good',           'Admin User', 'Submitted', 1),
('Lim Socheata', 'EMP-002', 'Phnom Penh', 'ABC Transport',   6, 2024, 0,       0,   0.00,  0.00,  0.00, 0,  0.00, 3.5, 5, 10.00, 4, 2,  5.00, 5.00, 70.00, 3.00, 23.00, 'Unsatisfactory',  'Admin User', 'Submitted', 1);

-- Monthly KPI Summaries
INSERT INTO monthly_kpi_summaries (staff_name, staff_id, branch, company, year, month, total_tickets_sold, total_sales_amount, total_bookings, total_booking_errors, total_complaints, total_resolved_complaints, ticket_sales_target, ticket_sales_score, booking_accuracy_score, customer_service_score, attendance_score, daily_reporting_score, sop_compliance_score, total_score, performance_rating) VALUES
('Van Dara',     'EMP-003', 'Phnom Penh', 'ABC Transport',   2024, 6, 135, 3375, 115, 6,  6, 4, 1000, 40.00, 18.00, 14.00, 10.00, 9.00, 5.00, 96.00, 'Excellent'),
('Neang Pisey',  'EMP-005', 'Siem Reap',  'ABC Transport',   2024, 6,  95, 2375,  83, 3,  3, 2,  900, 38.00, 19.00, 13.00, 10.00, 8.00, 4.50, 92.50, 'Excellent'),
('Sok Dara',     'EMP-001', 'Battambang','Western Express',  2024, 6,  20,  500,  18, 0,  0, 0,  600, 30.00, 17.00, 12.00,  7.00, 7.00, 4.00, 77.00, 'Good');

-- Config Module - Dynamic configuration engine
INSERT INTO config_module (id, module_key, module_name, module_icon, table_name, sort_order, is_active) VALUES
(1, 'bus_owners',     'Bus Owners',     'fa-truck',       NULL, 1, 1),
(2, 'bus_companies',  'Bus Companies',  'fa-building',    NULL, 2, 1),
(3, 'routes',         'Routes',         'fa-route',       NULL, 3, 1),
(4, 'stations',       'Stations',       'fa-map-pin',     NULL, 4, 1);

-- Config Field - Sample fields for dynamic modules
INSERT INTO config_field (id, module_id, field_name, field_label, field_type, is_required, is_listable, is_searchable, display_order) VALUES
(1, 1, 'owner_name',     'Owner Name',     'text',     1, 1, 1, 1),
(2, 1, 'phone_number',   'Phone Number',   'tel',      1, 1, 0, 2),
(3, 1, 'email',          'Email Address',  'email',    0, 1, 0, 3),
(4, 1, 'contract_date',  'Contract Date',  'date',     1, 1, 0, 4),
(5, 1, 'is_active',      'Active Status',  'boolean',  1, 1, 0, 5),
(6, 2, 'company_name',   'Company Name',   'text',     1, 1, 1, 1),
(7, 2, 'tax_id',         'Tax ID',         'text',     1, 1, 0, 2),
(8, 2, 'contact_person', 'Contact Person', 'text',     0, 1, 0, 3),
(9, 2, 'status',         'Status',         'dropdown', 1, 1, 0, 4),
(10, 3, 'route_code',    'Route Code',     'text',     1, 1, 1, 1),
(11, 3, 'start_point',   'Start Point',    'text',     1, 1, 1, 2),
(12, 3, 'end_point',     'End Point',      'text',     1, 1, 1, 3),
(13, 3, 'distance_km',   'Distance (km)',  'number',   1, 1, 0, 4),
(14, 4, 'station_name',  'Station Name',   'text',     1, 1, 1, 1),
(15, 4, 'location',      'Location',       'text',     1, 1, 0, 2),
(16, 4, 'contact',       'Contact Number', 'tel',      0, 1, 0, 3);

-- Config Dropdown Option - Status options for Bus Companies
INSERT INTO config_dropdown_option (field_id, option_value, option_label, sort_order) VALUES
(9, 'Active',    'Active',    1),
(9, 'Inactive',  'Inactive',  2),
(9, 'Suspended', 'Suspended', 3),
(9, 'Pending',   'Pending',   4);

-- Config Module Permission - Admin has full access to all dynamic modules
INSERT INTO config_module_permission (module_id, role, can_create, can_read, can_update, can_delete) VALUES
(1, 'admin', 1, 1, 1, 1),
(2, 'admin', 1, 1, 1, 1),
(3, 'admin', 1, 1, 1, 1),
(4, 'admin', 1, 1, 1, 1),
(1, 'branch_manager', 0, 1, 0, 0),
(2, 'branch_manager', 0, 1, 0, 0),
(3, 'branch_manager', 1, 1, 1, 0),
(4, 'branch_manager', 0, 1, 0, 0);

-- Dynamic Record - Sample dynamic data
INSERT INTO dynamic_record (module_id, data, is_active, created_by) VALUES
(4, JSON_OBJECT('station_name', 'Phnom Penh Central Station', 'location', 'Phnom Penh, Cambodia', 'contact', '023 888 999'), 1, 1),
(4, JSON_OBJECT('station_name', 'Siem Reap Bus Terminal',    'location', 'Siem Reap, Cambodia',   'contact', '063 777 888'), 1, 1),
(4, JSON_OBJECT('station_name', 'Sihanoukville Station',      'location', 'Sihanoukville, Cambodia','contact', '034 666 777'), 1, 1),
(4, JSON_OBJECT('station_name', 'Battambang Station',         'location', 'Battambang, Cambodia',  'contact', '053 555 666'), 1, 3);

-- =============================================================================
-- Reference / Lookup Table Seed Data
-- =============================================================================

-- Violation Types
INSERT INTO violation_types (name, description, default_min_amount, default_max_amount, sort_order) VALUES
('Late Arrival', 'Employee arrived late for scheduled shift', 25.00, 50.00, 1),
('Absenteeism', 'Employee absent without prior notice', 50.00, 100.00, 2),
('Misconduct', 'Inappropriate behavior or conduct violation', 100.00, 500.00, 3),
('Policy Violation', 'Violation of company policies', 50.00, 150.00, 4),
('Performance Issue', 'Consistent underperformance', NULL, NULL, 5),
('Insubordination', 'Refusal to follow legitimate instructions', NULL, NULL, 6),
('Theft', 'Theft of company property', NULL, NULL, 7),
('Cash Handling Error', 'Cash discrepancy or accounting error', 25.00, 200.00, 8),
('Customer Complaint', 'Validated customer complaint', 25.00, 100.00, 9),
('Unauthorized Discount', 'Giving discounts without approval', 50.00, 150.00, 10),
('Accident', 'Vehicle or workplace accident', 75.00, 500.00, 11),
('Other', 'Other violations not categorized', NULL, NULL, 12);

-- Vehicle Statuses
INSERT INTO vehicle_statuses (name, label, sort_order) VALUES
('Departed', 'Departed', 1),
('Not Departed', 'Not Departed', 2),
('In Transit', 'In Transit', 3),
('Arrived', 'Arrived', 4),
('Delayed', 'Delayed', 5),
('Cancelled', 'Cancelled', 6);

-- Power Statuses
INSERT INTO power_statuses (name, sort_order) VALUES
('Off', 1),
('On', 2);

-- Request Types
INSERT INTO request_types (name, code, description, icon, sort_order) VALUES
('Create Journey', 'create_journey', 'Create a new transportation journey route', 'fa-plus-circle', 1),
('Open Route', 'open_route', 'Open a new route for transportation', 'fa-road', 2),
('Change Route', 'change_route', 'Modify an existing transportation route', 'fa-exchange-alt', 3),
('Change Price', 'change_price', 'Change the price of an existing route', 'fa-tag', 4),
('Change Type', 'change_type', 'Change the transportation type for a route', 'fa-truck', 5);

-- Report Submission Statuses
INSERT INTO report_submission_statuses (name, score_weight, sort_order) VALUES
('On Time', 100.00, 1),
('Late', 50.00, 2),
('Incomplete', 25.00, 3),
('Not Submitted', 0.00, 4);

-- Branches
INSERT INTO branches (name, code) VALUES
('Phnom Penh', 'PP'),
('Siem Reap', 'SR'),
('Battambang', 'BTB'),
('Sihanoukville', 'SHV'),
('Kampot', 'KT'),
('Kampong Cham', 'KPC'),
('Takeo', 'TK'),
('Kandal', 'KL'),
('Poipet', 'PPT'),
('Headquarters', 'HQ');

-- Companies
INSERT INTO companies (name, code) VALUES
('ABC Transport', 'ABC'),
('XYZ Travel', 'XYZ'),
('Mekong Express', 'MEK'),
('Local Lines', 'LOC'),
('Western Express', 'WEST'),
('Eastern Travel', 'EAST'),
('Border Express', 'BORD'),
('Royal Bus', 'ROYAL'),
('City Link', 'CITY'),
('Sokha Express', 'SOKH');

-- Destinations
INSERT INTO destinations (name, code, sort_order) VALUES
('Phnom Penh', 'PP', 1),
('Siem Reap', 'SR', 2),
('Battambang', 'BTB', 3),
('Kampot', 'KT', 4),
('Kampong Cham', 'KPC', 5),
('Sihanoukville', 'SHV', 6),
('Takeo', 'TK', 7),
('Kandal', 'KL', 8),
('Poipet', 'PPT', 9),
('Pailin', 'PLN', 10),
('Kratie', 'KRT', 11),
('Stung Treng', 'STG', 12);

-- Transportation Types
INSERT INTO transportation_types (name, capacity, sort_order) VALUES
('Bus', 45, 1),
('Van', 16, 2),
('Car', 4, 3),
('Minibus', 25, 4),
('Motorcycle', 1, 5),
('Truck', 10, 6),
('VIP Bus', 30, 7),
('Mini Van', 12, 8);
