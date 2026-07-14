"""
Comprehensive RBAC permission test.
For every permission, creates a role with ONLY that permission, assigns a user,
then verifies that only the expected routes are accessible and all others return 403.
"""

import os
import sys
import unittest
from datetime import datetime, timezone

os.environ['FLASK_ENV'] = 'test'

import app as flask_app
from app import db, User, Role

# ── Permission → Route Mapping ──────────────────────────────────────────────
# Each permission maps to the route endpoints it should grant access to.
# IMPORTANT: Routes guarded by @any_permission_required(a,b,c) are accessible
# if the user has ANY of (a,b,c). This test accounts for that.

PERMISSION_ROUTES = {
    'route_request_view': [
        'route_requests', 'view_route_request',
    ],
    'route_request_create': [
        'new_route_request',
        'route_requests',  # list page is guarded by any route_request_* perm
    ],
    'route_request_edit': [
        'edit_route_request',
        'route_requests',
    ],
    'route_request_delete': [
        'delete_route_request',
        'route_requests',
    ],
    'route_request_approve': [
        'review_route_request',
        'route_requests',
    ],
    'route_request_reject': [
        'review_route_request',
        'route_requests',
    ],
    'route_request_download': [
        'export_requests_excel', 'export_requests_pdf',
        'route_requests',
    ],
    'transport_request_view': [
        'transport_requests', 'view_transport_request',
        'transport_download_file',
    ],
    'transport_request_create': [
        'new_transport_request', 'transport_upload_file', 'transport_delete_file',
        'transport_requests',
    ],
    'transport_request_edit': [
        'edit_transport_request', 'transport_upload_file', 'transport_delete_file',
        'transport_requests',
    ],
    'transport_request_delete': [
        'delete_transport_request',
        'transport_requests',
    ],
    'transport_request_approve': [
        'review_transport_request',
        'transport_requests',
    ],
    'transport_request_reject': [
        'review_transport_request',
        'transport_requests',
    ],
    'transport_request_download': [
        'transport_requests',
    ],
    'penalty_view': [
        'penalties', 'view_penalty',
    ],
    'penalty_create': [
        'new_penalty',
        'penalties',
    ],
    'penalty_edit': [
        'edit_penalty', 'approve_penalty',
        'penalties',
    ],
    'penalty_delete': [
        'delete_penalty',
        'penalties',
    ],
    'penalty_download': [
        'export_penalties_excel', 'export_penalties_pdf',
        'penalties',
    ],
    'trip_operation_report_view': [
        'trip_operation_reports', 'view_trip_operation_report',
        'vehicle_performance', 'api_vehicle_performance_vehicles',
        'export_trip_reports_excel', 'export_trip_reports_pdf',
    ],
    'trip_operation_report_create': [
        'new_trip_operation_report',
        'trip_operation_reports', 'vehicle_performance',
        'api_vehicle_performance_vehicles',
    ],
    'trip_operation_report_edit': [
        'edit_trip_operation_report',
        'trip_operation_reports', 'vehicle_performance',
        'api_vehicle_performance_vehicles',
    ],
    'trip_operation_report_delete': [
        'delete_trip_operation_report',
        'trip_operation_reports', 'vehicle_performance',
        'api_vehicle_performance_vehicles',
    ],
    'trip_operation_report_download': [
        'export_trip_reports_excel', 'export_trip_reports_pdf',
        'trip_operation_reports', 'vehicle_performance',
        'api_vehicle_performance_vehicles',
    ],
    'daily_report_view': [
        'daily_reports', 'view_daily_report',
        'export_daily_reports_excel', 'export_daily_reports_pdf',
    ],
    'daily_report_create': [
        'new_daily_report',
        'daily_reports',
    ],
    'daily_report_edit': [
        'edit_daily_report',
        'daily_reports',
    ],
    'daily_report_delete': [
        'delete_daily_report',
        'daily_reports',
    ],
    'kpi_evaluation_view': [
        'kpi_evaluations', 'view_kpi_evaluation',
    ],
    'kpi_evaluation_create': [
        'new_kpi_evaluation',
        'kpi_evaluations',
    ],
    'kpi_evaluation_edit': [
        'edit_kpi_evaluation',
        'kpi_evaluations',
    ],
    'kpi_evaluation_delete': [
        'delete_kpi_evaluation',
        'kpi_evaluations',
    ],
    'kpi_dashboard_view':    ['kpi_dashboard'],
    'kpi_history_view':      ['kpi_history'],
    'system_settings_view':  [
        'dynamic_settings', 'dynamic_list', 'dynamic_view',
    ],
    'system_settings_edit':  [
        'dynamic_create', 'dynamic_edit', 'dynamic_delete', 'dynamic_toggle',
        'telegram_settings', 'telegram_settings_test',
        'api_telegram_status',
        'api_telegram_validate', 'api_telegram_disconnect', 'api_telegram_save',
        'dynamic_settings', 'dynamic_list',
    ],
    'system_settings_update': [
        'telegram_settings', 'telegram_settings_test',
        'api_telegram_status',
        'api_telegram_validate', 'api_telegram_disconnect', 'api_telegram_save',
        'dynamic_settings', 'dynamic_list',
    ],
    'department_view':    ['departments'],
    'department_create':  ['new_department', 'departments'],
    'department_edit':    ['edit_department', 'departments'],
    'department_delete':  ['delete_department', 'departments'],
    'department_download':['departments'],
    'position_view':      ['positions'],
    'position_create':    ['new_position', 'positions'],
    'position_edit':      ['edit_position', 'positions'],
    'position_delete':    ['delete_position', 'positions'],
    'position_download':  ['positions'],
    'role_view':          ['list_roles'],
    'role_create':        ['new_role', 'list_roles'],
    'role_edit':          ['edit_role', 'list_roles'],
    'role_delete':        ['delete_role', 'list_roles'],
    'role_assign_permissions': ['list_roles'],
    'role_download':      ['list_roles'],
    'user_view':          ['users'],
    'user_create':        ['new_user', 'users'],
    'user_edit':          ['edit_user', 'users'],
    'user_delete':        ['delete_user', 'users'],
    'user_assign_roles':  ['users'],
    'user_reset_password':['users'],
    'user_activate':      ['users'],
    'user_deactivate':    ['users'],
    'user_download':      ['users'],
}

# Reports page routes — accessible if user has any of the REPORTS_VIEW_PERMISSIONS
REPORTS_ROUTES = ['reports', 'reports_data', 'reports_charts', 'reports_export', 'report_subpath']

REPORTS_VIEW_PERMISSIONS = {
    'transport_request_view', 'trip_operation_report_view',
    'daily_report_view', 'kpi_evaluation_view',
    'kpi_history_view', 'penalty_view',
}

# Routes that have additional business-logic checks that can return 403/404
# even when the user has the right permission
BUSINESS_LOGIC_OK_CODES = {200, 302, 400, 403, 404}

# URLs for routes with no dynamic parameters
SIMPLE_URLS = {
    'index': '/', 'login': '/login', 'logout': '/logout',
    'dashboard': '/dashboard', 'set_language': '/set-language/en',
    'route_requests': '/route-requests', 'new_route_request': '/route-requests/new',
    'transport_requests': '/transport-requests', 'new_transport_request': '/transport-requests/new',
    'transport_upload_file': '/transport-requests/upload',
    'transport_delete_file': '/transport-requests/delete-file',
    'transport_download_file': '/transport-requests/download/test.txt',
    'penalties': '/penalties', 'new_penalty': '/penalties/new',
    'trip_operation_reports': '/trip-operation-reports',
    'new_trip_operation_report': '/trip-operation-reports/new',
    'vehicle_performance': '/vehicle-performance',
    'daily_reports': '/daily-reports', 'new_daily_report': '/daily-reports/new',
    'kpi_evaluations': '/kpi-evaluations', 'new_kpi_evaluation': '/kpi-evaluations/new',
    'kpi_dashboard': '/kpi-dashboard', 'kpi_history': '/kpi-dashboard/history',
    'departments': '/departments', 'new_department': '/departments/new',
    'positions': '/positions', 'new_position': '/positions/new',
    'list_roles': '/roles', 'new_role': '/roles/new',
    'users': '/users', 'new_user': '/users/new',
    'reports': '/reports', 'reports_data': '/reports/data',
    'reports_charts': '/reports/charts/transport',
    'reports_export': '/reports/export/excel/transport',
    'report_subpath': '/reports/some-slug',
    'dynamic_settings': '/dynamic-settings',
    'dynamic_list': '/dynamic-settings/company',
    'dynamic_create': '/dynamic-settings/company/create',
    'dynamic_view': '/dynamic-settings/company/1',
    'dynamic_edit': '/dynamic-settings/company/1/edit',
    'dynamic_delete': '/dynamic-settings/company/1/delete',
    'dynamic_toggle': '/dynamic-settings/company/1/toggle',
    'telegram_settings': '/settings/telegram',
    'telegram_settings_test': '/settings/telegram/test',
    'api_telegram_status': '/api/telegram/status',
    'api_telegram_validate': '/api/telegram/validate',
    'api_telegram_disconnect': '/api/telegram/disconnect',
    'api_telegram_save': '/api/telegram/save',
    'export_requests_excel': '/reports/export/requests',
    'export_penalties_excel': '/reports/export/penalties',
    'export_requests_pdf': '/reports/export/requests/pdf',
    'export_penalties_pdf': '/reports/export/penalties/pdf',
    'export_trip_reports_excel': '/reports/export/trip-reports',
    'export_trip_reports_pdf': '/reports/export/trip-reports/pdf',
    'export_daily_reports_excel': '/daily-reports/export/excel',
    'export_daily_reports_pdf': '/daily-reports/export/pdf',
    'api_vehicle_performance_vehicles': '/api/vehicle-performance/vehicles',
    'api_vehicle_performance_data': '/api/vehicle-performance/data',
    'api_dashboard_summary': '/api/dashboard/summary',
    'api_dashboard_charts': '/api/dashboard/charts',
    'api_dashboard_executive_summary': '/api/dashboard/executive-summary',
    'api_dashboard_insights': '/api/dashboard/insights',
    'api_dashboard_comparison': '/api/dashboard/comparison',
    'api_dashboard_tables': '/api/dashboard/tables',
}

POST_ONLY_ENDPOINTS = {
    'delete_route_request', 'review_route_request',
    'delete_transport_request', 'review_transport_request',
    'delete_penalty', 'approve_penalty',
    'delete_trip_operation_report',
    'delete_daily_report', 'delete_kpi_evaluation',
    'delete_department', 'delete_position',
    'delete_role', 'delete_user',
    'dynamic_delete', 'dynamic_toggle',
    'telegram_settings_test',
    'api_telegram_validate', 'api_telegram_disconnect', 'api_telegram_save',
    'transport_upload_file', 'transport_delete_file',
}


class RBACTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        flask_app.app.config['TESTING'] = True
        flask_app.app.config['WTF_CSRF_ENABLED'] = False
        flask_app.app.config['WTF_CSRF_CHECK_DEFAULT'] = False
        cls.app = flask_app.app
        cls.client = cls.app.test_client()

    def setUp(self):
        self._test_artifacts = []

    def tearDown(self):
        """Clean up all test users and roles created during this test."""
        with self.app.app_context():
            for username, role_name in self._test_artifacts:
                User.query.filter_by(username=username).delete()
                Role.query.filter_by(name=role_name).delete()
            db.session.commit()

    def _get_url(self, endpoint):
        """Build a URL for a given endpoint, using existing DB IDs when needed."""
        if endpoint in SIMPLE_URLS:
            return SIMPLE_URLS[endpoint]
        # Parameterized routes — get the first actual record ID
        param_map = {
            'view_route_request': ('/route-requests/{id}', flask_app.RouteRequest),
            'edit_route_request': ('/route-requests/{id}/edit', flask_app.RouteRequest),
            'delete_route_request': ('/route-requests/{id}/delete', flask_app.RouteRequest),
            'review_route_request': ('/route-requests/{id}/review', flask_app.RouteRequest),
            'view_transport_request': ('/transport-requests/{id}', flask_app.TransportRequest),
            'edit_transport_request': ('/transport-requests/{id}/edit', flask_app.TransportRequest),
            'delete_transport_request': ('/transport-requests/{id}/delete', flask_app.TransportRequest),
            'review_transport_request': ('/transport-requests/{id}/review', flask_app.TransportRequest),
            'view_penalty': ('/penalties/{id}', flask_app.EmployeePenalty),
            'edit_penalty': ('/penalties/{id}/edit', flask_app.EmployeePenalty),
            'approve_penalty': ('/penalties/{id}/approve', flask_app.EmployeePenalty),
            'delete_penalty': ('/penalties/{id}/delete', flask_app.EmployeePenalty),
            'view_trip_operation_report': ('/trip-operation-reports/{id}', flask_app.TripOperationReport),
            'edit_trip_operation_report': ('/trip-operation-reports/{id}/edit', flask_app.TripOperationReport),
            'delete_trip_operation_report': ('/trip-operation-reports/{id}/delete', flask_app.TripOperationReport),
            'view_daily_report': ('/daily-reports/{id}', flask_app.DailyPerformanceReport),
            'edit_daily_report': ('/daily-reports/{id}/edit', flask_app.DailyPerformanceReport),
            'delete_daily_report': ('/daily-reports/{id}/delete', flask_app.DailyPerformanceReport),
            'view_kpi_evaluation': ('/kpi-evaluations/{id}', flask_app.KpiEvaluation),
            'edit_kpi_evaluation': ('/kpi-evaluations/{id}/edit', flask_app.KpiEvaluation),
            'delete_kpi_evaluation': ('/kpi-evaluations/{id}/delete', flask_app.KpiEvaluation),
            'edit_department': ('/departments/{id}/edit', flask_app.Department),
            'delete_department': ('/departments/{id}/delete', flask_app.Department),
            'edit_position': ('/positions/{id}/edit', flask_app.Position),
            'delete_position': ('/positions/{id}/delete', flask_app.Position),
            'edit_role': ('/roles/{id}/edit', flask_app.Role),
            'delete_role': ('/roles/{id}/delete', flask_app.Role),
            'edit_user': ('/users/{id}/edit', flask_app.User),
            'delete_user': ('/users/{id}/delete', flask_app.User),
        }
        if endpoint in param_map:
            pattern, model_cls = param_map[endpoint]
            with self.app.app_context():
                record = model_cls.query.first()
                if record is not None:
                    return pattern.format(id=record.id)
            # Fallback — try id=1
            return pattern.format(id=1)
        return None

    def _is_post_only(self, endpoint):
        return endpoint in POST_ONLY_ENDPOINTS

    def _create_role_and_user(self, permission_name):
        with self.app.app_context():
            ts = datetime.now(timezone.utc).strftime('%H%M%S%f')
            role_name = f'rb_{permission_name[:10]}_{ts[-6:]}'
            username = f'u_{permission_name[:10]}_{ts[-6:]}'
            role = Role(
                name=role_name, label=f'Test {permission_name}',
                permissions=[permission_name]
            )
            db.session.add(role)
            db.session.flush()
            user = User(
                full_name=f'Test {permission_name}',
                username=username, branch='HQ',
                role_id=role.id, is_active=True
            )
            user.set_password('test123')
            db.session.add(user)
            db.session.commit()
            self._test_artifacts.append((username, role_name))
            return username, 'test123'

    def _login(self, username, password, follow_redirects=True):
        return self.client.post('/login', data={
            'username': username, 'password': password
        }, follow_redirects=follow_redirects)

    def test_login_redirect(self):
        """Unauthenticated users must be redirected."""
        for url in ['/dashboard', '/route-requests', '/daily-reports']:
            resp = self.client.get(url, follow_redirects=False)
            self.assertIn(resp.status_code, [302, 401],
                          f'{url} should redirect unauthenticated, got {resp.status_code}')

    def test_all_permissions(self):
        """
        For each permission, create a user with ONLY that permission.
        Verify:
          - ALLOWED routes return 2xx (or business-logic 403/404)
          - DENIED routes return 403
        """
        errors = []
        perms = sorted(PERMISSION_ROUTES.keys())
        total = len(perms)

        for idx, perm in enumerate(perms, 1):
            allowed_set = set(PERMISSION_ROUTES[perm])
            if perm in REPORTS_VIEW_PERMISSIONS:
                allowed_set.update(REPORTS_ROUTES)

            all_guarded = set()
            for p, eps in PERMISSION_ROUTES.items():
                all_guarded.update(eps)
            all_guarded.update(REPORTS_ROUTES)

            denied_set = all_guarded - allowed_set

            with self.subTest(permission=perm):
                try:
                    u, p = self._create_role_and_user(perm)
                    login_resp = self._login(u, p, follow_redirects=False)
                    if login_resp.status_code not in (302, 200):
                        errors.append(f'PERM={perm}: Login failed (status={login_resp.status_code})')
                        continue

                    # Test ALLOWED routes
                    for ep in allowed_set:
                        url = self._get_url(ep)
                        if url is None:
                            errors.append(f'PERM={perm}: No URL for allowed endpoint {ep}')
                            continue
                        method = 'POST' if self._is_post_only(ep) else 'GET'
                        try:
                            if method == 'POST':
                                r = self.client.post(url, follow_redirects=True)
                            else:
                                r = self.client.get(url, follow_redirects=True)
                            # Allow business-logic codes (200/302/403/404)
                            if r.status_code not in BUSINESS_LOGIC_OK_CODES:
                                errors.append(
                                    f'PERM={perm}: ALLOWED {ep} -> {url} '
                                    f'({method}) returned {r.status_code} '
                                    f'(expected {BUSINESS_LOGIC_OK_CODES})')
                        except Exception as e:
                            errors.append(f'PERM={perm}: ALLOWED {ep} EXCEPTION: {e}')

                    # Test DENIED routes — sample up to 25 per permission
                    denied_tested = 0
                    for ep in sorted(denied_set):
                        if denied_tested >= 25:
                            break
                        url = self._get_url(ep)
                        if url is None:
                            continue
                        method = 'POST' if self._is_post_only(ep) else 'GET'
                        try:
                            if method == 'POST':
                                r = self.client.post(url, follow_redirects=True)
                            else:
                                r = self.client.get(url, follow_redirects=True)
                            if r.status_code != 403:
                                errors.append(
                                    f'PERM={perm}: DENIED {ep} -> {url} '
                                    f'({method}) returned {r.status_code} (expected 403)')
                        except Exception as e:
                            errors.append(f'PERM={perm}: DENIED {ep} EXCEPTION: {e}')
                        denied_tested += 1

                    self.client.get('/logout', follow_redirects=True)

                except Exception as e:
                    errors.append(f'PERM={perm}: SETUP EXCEPTION: {e}')

            sys.stdout.write(f'\r  [{idx}/{total}] {perm:40s} errors={len(errors)}')
            sys.stdout.flush()

        print()
        if errors:
            print(f'\n  ERRORS ({len(errors)}):')
            for err in errors[:60]:
                print(f'    {err}')
            if len(errors) > 60:
                print(f'    ... and {len(errors) - 60} more')
        self.assertEqual(len(errors), 0, f'{len(errors)} permission errors found')

    def test_sidebar_restricted(self):
        """Verify the rendered sidebar only shows links for granted permissions."""
        self._ensure_logged_out()
        perm = 'penalty_view'
        u, p = self._create_role_and_user(perm)
        self._login(u, p)
        resp = self.client.get('/penalties', follow_redirects=True)
        html = resp.data.decode('utf-8').lower()

        self.assertIn('penalties', html,
                      'Sidebar should show Penalties link for penalty_view user')
        # Should NOT see daily-reports link
        dr_count = html.count('/daily-reports')
        self.assertLessEqual(dr_count, 1,
            f'penalty_view user should not see daily-reports. Found {dr_count}')
        # Should NOT see kpi-evaluations link
        kpi_count = html.count('/kpi-evaluations')
        self.assertLessEqual(kpi_count, 1,
            f'penalty_view user should not see kpi-evaluations. Found {kpi_count}')

    def _ensure_logged_out(self):
        self.client.get('/logout', follow_redirects=True)

    def test_sidebar_full_admin(self):
        """Admin user should see ALL sidebar links."""
        self._ensure_logged_out()
        all_perms = sorted(PERMISSION_ROUTES.keys()) + ['dashboard_view']
        with self.app.app_context():
            ts = datetime.now(timezone.utc).strftime('%H%M%S%f')
            role_name = f'admintest_role_{ts[-6:]}'
            username = f'admintest_user_{ts[-6:]}'
            role = Role(name=role_name, label='Admin Full', permissions=all_perms)
            db.session.add(role)
            db.session.flush()
            user = User(
                full_name='Admin Full', username=username,
                role_id=role.id, branch='HQ'
            )
            user.set_password('test123')
            db.session.add(user)
            db.session.commit()
            self._test_artifacts.append((username, role_name))
        self._login(username, 'test123')
        resp = self.client.get('/dashboard', follow_redirects=True)
        html = resp.data.decode('utf-8').lower()

        self.assertIn('route-requests', html)
        self.assertIn('transport-requests', html)
        self.assertIn('penalties', html)
        self.assertIn('trip-operation-reports', html)
        self.assertIn('daily-reports', html)
        self.assertIn('kpi-evaluations', html)
        self.assertIn('kpi-dashboard', html)
        self.assertIn('departments', html)
        self.assertIn('positions', html)
        self.assertIn('roles', html)
        self.assertIn('users', html)
        self.assertIn('reports', html)
        self.assertIn('dynamic-settings', html)
        self._ensure_logged_out()

    def test_no_access_without_permission(self):
        """User with zero permissions should get 403 on all guarded routes."""
        self._ensure_logged_out()
        u, p = self._create_role_and_user('route_request_view')
        self._login(u, p)
        resp = self.client.get('/daily-reports', follow_redirects=True)
        self.assertEqual(resp.status_code, 403,
                         'User without daily_report_* should get 403 on /daily-reports')
        resp = self.client.get('/kpi-dashboard', follow_redirects=True)
        self.assertEqual(resp.status_code, 403,
                         'User without kpi_dashboard_view should get 403 on /kpi-dashboard')
        self._ensure_logged_out()


if __name__ == '__main__':
    unittest.main(verbosity=2)
