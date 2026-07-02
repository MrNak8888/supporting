-- =============================================================================
-- IT Management System - Foreign Key Relationships
-- =============================================================================

-- -----------------------------------------
-- users -> roles
-- -----------------------------------------
ALTER TABLE users
  ADD CONSTRAINT fk_users_role_id
  FOREIGN KEY (role_id) REFERENCES roles(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- positions -> departments
-- -----------------------------------------
ALTER TABLE positions
  ADD CONSTRAINT fk_positions_department_id
  FOREIGN KEY (department_id) REFERENCES departments(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- route_requests -> users (requester)
-- -----------------------------------------
ALTER TABLE route_requests
  ADD CONSTRAINT fk_route_requests_requester_id
  FOREIGN KEY (requester_id) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- route_requests -> users (reviewer)
-- -----------------------------------------
ALTER TABLE route_requests
  ADD CONSTRAINT fk_route_requests_reviewed_by
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- transport_requests -> users (requester)
-- -----------------------------------------
ALTER TABLE transport_requests
  ADD CONSTRAINT fk_transport_requests_requester_id
  FOREIGN KEY (requester_id) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- transport_requests -> users (reviewer)
-- -----------------------------------------
ALTER TABLE transport_requests
  ADD CONSTRAINT fk_transport_requests_reviewed_by
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- employee_penalties -> users (creator)
-- -----------------------------------------
ALTER TABLE employee_penalties
  ADD CONSTRAINT fk_employee_penalties_created_by
  FOREIGN KEY (created_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- trip_operation_reports -> users (creator)
-- -----------------------------------------
ALTER TABLE trip_operation_reports
  ADD CONSTRAINT fk_trip_operation_reports_created_by
  FOREIGN KEY (created_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- kpi_evaluations -> users (creator)
-- -----------------------------------------
ALTER TABLE kpi_evaluations
  ADD CONSTRAINT fk_kpi_evaluations_created_by
  FOREIGN KEY (created_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- daily_performance_reports -> users (creator)
-- -----------------------------------------
ALTER TABLE daily_performance_reports
  ADD CONSTRAINT fk_daily_performance_created_by
  FOREIGN KEY (created_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- config_field -> config_module (module owner)
-- -----------------------------------------
ALTER TABLE config_field
  ADD CONSTRAINT fk_config_field_module_id
  FOREIGN KEY (module_id) REFERENCES config_module(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- config_field -> config_module (option source)
-- -----------------------------------------
ALTER TABLE config_field
  ADD CONSTRAINT fk_config_field_option_module_id
  FOREIGN KEY (option_module_id) REFERENCES config_module(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- config_field -> config_module (relation)
-- -----------------------------------------
ALTER TABLE config_field
  ADD CONSTRAINT fk_config_field_rel_module_id
  FOREIGN KEY (rel_module_id) REFERENCES config_module(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- config_validation -> config_field
-- -----------------------------------------
ALTER TABLE config_validation
  ADD CONSTRAINT fk_config_validation_field_id
  FOREIGN KEY (field_id) REFERENCES config_field(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- config_dropdown_option -> config_field
-- -----------------------------------------
ALTER TABLE config_dropdown_option
  ADD CONSTRAINT fk_config_dropdown_option_field_id
  FOREIGN KEY (field_id) REFERENCES config_field(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- config_module_permission -> config_module
-- -----------------------------------------
ALTER TABLE config_module_permission
  ADD CONSTRAINT fk_config_module_permission_module_id
  FOREIGN KEY (module_id) REFERENCES config_module(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- dynamic_record -> config_module
-- -----------------------------------------
ALTER TABLE dynamic_record
  ADD CONSTRAINT fk_dynamic_record_module_id
  FOREIGN KEY (module_id) REFERENCES config_module(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- dynamic_record -> users (creator)
-- -----------------------------------------
ALTER TABLE dynamic_record
  ADD CONSTRAINT fk_dynamic_record_created_by
  FOREIGN KEY (created_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- dynamic_record -> users (updater)
-- -----------------------------------------
ALTER TABLE dynamic_record
  ADD CONSTRAINT fk_dynamic_record_updated_by
  FOREIGN KEY (updated_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- role_permissions -> roles
-- -----------------------------------------
ALTER TABLE role_permissions
  ADD CONSTRAINT fk_role_permissions_role_id
  FOREIGN KEY (role_id) REFERENCES roles(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- role_permissions -> permissions
-- -----------------------------------------
ALTER TABLE role_permissions
  ADD CONSTRAINT fk_role_permissions_permission_id
  FOREIGN KEY (permission_id) REFERENCES permissions(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- route_request_audit_log -> route_requests
-- -----------------------------------------
ALTER TABLE route_request_audit_log
  ADD CONSTRAINT fk_rr_audit_route_request_id
  FOREIGN KEY (route_request_id) REFERENCES route_requests(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- route_request_audit_log -> users
-- -----------------------------------------
ALTER TABLE route_request_audit_log
  ADD CONSTRAINT fk_rr_audit_performed_by
  FOREIGN KEY (performed_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- transport_request_audit_log -> transport_requests
-- -----------------------------------------
ALTER TABLE transport_request_audit_log
  ADD CONSTRAINT fk_tr_audit_transport_request_id
  FOREIGN KEY (transport_request_id) REFERENCES transport_requests(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- transport_request_audit_log -> users
-- -----------------------------------------
ALTER TABLE transport_request_audit_log
  ADD CONSTRAINT fk_tr_audit_performed_by
  FOREIGN KEY (performed_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- employee_penalty_audit_log -> employee_penalties
-- -----------------------------------------
ALTER TABLE employee_penalty_audit_log
  ADD CONSTRAINT fk_penalty_audit_penalty_id
  FOREIGN KEY (penalty_id) REFERENCES employee_penalties(id)
  ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------
-- employee_penalty_audit_log -> users
-- -----------------------------------------
ALTER TABLE employee_penalty_audit_log
  ADD CONSTRAINT fk_penalty_audit_performed_by
  FOREIGN KEY (performed_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- user_activity_log -> users
-- -----------------------------------------
ALTER TABLE user_activity_log
  ADD CONSTRAINT fk_user_activity_user_id
  FOREIGN KEY (user_id) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;

-- -----------------------------------------
-- uploaded_files -> users (uploader)
-- -----------------------------------------
ALTER TABLE uploaded_files
  ADD CONSTRAINT fk_uploaded_files_uploaded_by
  FOREIGN KEY (uploaded_by) REFERENCES users(id)
  ON DELETE SET NULL ON UPDATE CASCADE;
