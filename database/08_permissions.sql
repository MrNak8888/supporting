-- =============================================================================
-- IT Management System - RBAC Permissions Catalog & Role-Permission Mapping
-- =============================================================================

-- Insert all application permissions into catalog
INSERT IGNORE INTO permissions (code, name, module, is_system) VALUES
-- Dashboard
('dashboard_view', 'View Dashboard', 'dashboard', 1),
('dashboard_edit', 'Edit Dashboard', 'dashboard', 1),
('dashboard_download', 'Download Dashboard Data', 'dashboard', 1),
-- Route Requests
('route_request_view', 'View Route Requests', 'route_requests', 1),
('route_request_create', 'Create Route Requests', 'route_requests', 1),
('route_request_edit', 'Edit Route Requests', 'route_requests', 1),
('route_request_delete', 'Delete Route Requests', 'route_requests', 1),
('route_request_approve', 'Approve Route Requests', 'route_requests', 1),
('route_request_reject', 'Reject Route Requests', 'route_requests', 1),
('route_request_download', 'Download Route Requests', 'route_requests', 1),
-- Transport Requests
('transport_request_view', 'View Transport Requests', 'transport_requests', 1),
('transport_request_create', 'Create Transport Requests', 'transport_requests', 1),
('transport_request_edit', 'Edit Transport Requests', 'transport_requests', 1),
('transport_request_delete', 'Delete Transport Requests', 'transport_requests', 1),
('transport_request_approve', 'Approve Transport Requests', 'transport_requests', 1),
('transport_request_reject', 'Reject Transport Requests', 'transport_requests', 1),
('transport_request_download', 'Download Transport Requests', 'transport_requests', 1),
-- Penalties
('penalty_view', 'View Penalties', 'penalties', 1),
('penalty_create', 'Create Penalties', 'penalties', 1),
('penalty_edit', 'Edit Penalties', 'penalties', 1),
('penalty_delete', 'Delete Penalties', 'penalties', 1),
('penalty_download', 'Download Penalties', 'penalties', 1),
-- Trip Operation Reports
('trip_operation_report_view', 'View Trip Reports', 'trip_reports', 1),
('trip_operation_report_create', 'Create Trip Reports', 'trip_reports', 1),
('trip_operation_report_edit', 'Edit Trip Reports', 'trip_reports', 1),
('trip_operation_report_delete', 'Delete Trip Reports', 'trip_reports', 1),
('trip_operation_report_download', 'Download Trip Reports', 'trip_reports', 1),
-- Reports
('report_view', 'View Reports', 'reports', 1),
('report_create', 'Create Reports', 'reports', 1),
('report_edit', 'Edit Reports', 'reports', 1),
('report_delete', 'Delete Reports', 'reports', 1),
('report_export', 'Export Reports', 'reports', 1),
('report_print', 'Print Reports', 'reports', 1),
('report_download', 'Download Reports', 'reports', 1),
-- System Settings
('system_settings_view', 'View System Settings', 'settings', 1),
('system_settings_edit', 'Edit System Settings', 'settings', 1),
('system_settings_update', 'Update System Settings', 'settings', 1),
-- Departments (HR)
('department_view', 'View Departments', 'hr', 1),
('department_create', 'Create Departments', 'hr', 1),
('department_edit', 'Edit Departments', 'hr', 1),
('department_delete', 'Delete Departments', 'hr', 1),
('department_download', 'Download Departments', 'hr', 1),
-- Positions (HR)
('position_view', 'View Positions', 'hr', 1),
('position_create', 'Create Positions', 'hr', 1),
('position_edit', 'Edit Positions', 'hr', 1),
('position_delete', 'Delete Positions', 'hr', 1),
('position_download', 'Download Positions', 'hr', 1),
-- Roles (RBAC)
('role_view', 'View Roles', 'rbac', 1),
('role_create', 'Create Roles', 'rbac', 1),
('role_edit', 'Edit Roles', 'rbac', 1),
('role_delete', 'Delete Roles', 'rbac', 1),
('role_assign_permissions', 'Assign Role Permissions', 'rbac', 1),
('role_download', 'Download Roles', 'rbac', 1),
-- Users
('user_view', 'View Users', 'users', 1),
('user_create', 'Create Users', 'users', 1),
('user_edit', 'Edit Users', 'users', 1),
('user_delete', 'Delete Users', 'users', 1),
('user_assign_roles', 'Assign User Roles', 'users', 1),
('user_reset_password', 'Reset User Passwords', 'users', 1),
('user_activate', 'Activate Users', 'users', 1),
('user_deactivate', 'Deactivate Users', 'users', 1),
('user_download', 'Download Users', 'users', 1);

-- =============================================================================
-- Role-Permission Mapping
-- =============================================================================

-- Admin: all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions;

-- Regional Manager (role_id=2)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE code IN (
    'dashboard_view',
    'route_request_view', 'route_request_approve', 'route_request_reject', 'route_request_download',
    'transport_request_view', 'transport_request_approve', 'transport_request_reject', 'transport_request_download',
    'penalty_view', 'penalty_edit', 'penalty_download',
    'trip_operation_report_view', 'trip_operation_report_download',
    'report_view', 'report_export', 'report_download',
    'department_view', 'position_view'
);

-- Branch Manager (role_id=3)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE code IN (
    'dashboard_view',
    'route_request_view', 'route_request_create', 'route_request_edit',
    'transport_request_view', 'transport_request_create', 'transport_request_edit',
    'trip_operation_report_view', 'trip_operation_report_create', 'trip_operation_report_edit'
);

-- HR Manager (role_id=4)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE code IN (
    'dashboard_view',
    'penalty_view', 'penalty_create', 'penalty_edit', 'penalty_download',
    'transport_request_view',
    'department_view', 'department_create', 'department_edit',
    'position_view', 'position_create', 'position_edit',
    'report_view', 'report_export', 'report_download'
);

-- IT Staff (role_id=5)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, id FROM permissions WHERE code IN (
    'dashboard_view',
    'route_request_view', 'route_request_download',
    'transport_request_view', 'transport_request_download',
    'trip_operation_report_view', 'trip_operation_report_download',
    'report_view', 'report_export', 'report_download'
);
