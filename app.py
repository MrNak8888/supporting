from flask import Flask, render_template, request, redirect, url_for, flash, send_file, jsonify, session
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, date, timezone
from functools import wraps
from collections import defaultdict
from sqlalchemy import text
from flask_babel import Babel, _
import os
import io
import json
import uuid
import re
import calendar
from fpdf import FPDF


def send_excel(buf, filename):
    try:
        return send_file(buf, as_attachment=True, download_name=filename,
                         mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    except TypeError:
        return send_file(buf, as_attachment=True, attachment_filename=filename,
                         mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')


def send_pdf(buf, filename):
    buf.seek(0)
    try:
        return send_file(buf, as_attachment=True, download_name=filename,
                         mimetype='application/pdf')
    except TypeError:
        return send_file(buf, as_attachment=True, attachment_filename=filename,
                         mimetype='application/pdf')


app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'it-management-secret-key-2024')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///it_management.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def get_locale():
    if 'lang' in session:
        return session['lang']
    return request.accept_languages.best_match(['en', 'km']) or 'en'

babel = Babel(app, locale_selector=get_locale)

ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_upload(file):
    if file and file.filename and allowed_file(file.filename):
        ext = file.filename.rsplit('.', 1)[1].lower()
        unique_name = f"{uuid.uuid4().hex}.{ext}"
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], unique_name))
        return unique_name
    return None

def delete_upload(filename):
    if filename:
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if os.path.exists(filepath):
            os.remove(filepath)


def _int_or_none(val):
    try:
        return int(val) if val else None
    except (ValueError, TypeError):
        return None


def _add_column_if_not_exists(table, column, col_type):
    try:
        db.session.execute(text(f'ALTER TABLE {table} ADD COLUMN {column} {col_type}'))
        db.session.commit()
    except Exception:
        db.session.rollback()


db = SQLAlchemy(app)

from datetime import datetime as _dt
@app.context_processor
def inject_now():
    return {
        'now': _dt.now(),
        'current_locale': session.get('lang', 'en'),
    }

@app.context_processor
def inject_permission_helpers():
    return dict(has_permission=lambda p: current_user.is_authenticated and current_user.has_permission(p),
                has_any_permission=lambda *ps: current_user.is_authenticated and current_user.has_any_permission(*ps))

login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message = _('Please log in to access this page.')

# ─────────────────────────────────────────
#  MODELS
# ─────────────────────────────────────────

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(30), nullable=False, default='admin')
    role_id = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=True)
    branch = db.Column(db.String(100))
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    is_active = db.Column(db.Boolean, default=True)

    assigned_role = db.relationship('Role', foreign_keys=[role_id])

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    LEGACY_PERMISSIONS = {
        'admin': ['dashboard_view', 'dashboard_edit', 'dashboard_download',
                  'route_request_view', 'route_request_create', 'route_request_edit',
                  'route_request_delete', 'route_request_approve', 'route_request_reject',
                  'route_request_download',
                  'penalty_view', 'penalty_create', 'penalty_edit', 'penalty_delete',
                  'penalty_download',
                  'trip_operation_report_view', 'trip_operation_report_create',
                  'trip_operation_report_edit', 'trip_operation_report_delete',
                  'trip_operation_report_download',
                  'report_view', 'report_create', 'report_edit', 'report_delete',
                  'report_export', 'report_print', 'report_download',
                  'system_settings_view', 'system_settings_edit', 'system_settings_update',
                  'department_view', 'department_create', 'department_edit',
                  'department_delete', 'department_download',
                  'position_view', 'position_create', 'position_edit',
                  'position_delete', 'position_download',
                  'role_view', 'role_create', 'role_edit', 'role_delete',
                  'role_assign_permissions', 'role_download',
                  'user_view', 'user_create', 'user_edit', 'user_delete',
                  'user_assign_roles', 'user_reset_password', 'user_activate',
                  'user_deactivate', 'user_download'],
        'it_staff': ['dashboard_view',
                     'route_request_view', 'route_request_download',
                     'trip_operation_report_view', 'trip_operation_report_download',
                     'report_view', 'report_export', 'report_download'],
        'branch_manager': ['dashboard_view',
                           'route_request_view', 'route_request_create',
                           'route_request_edit',
                           'trip_operation_report_view',
                           'trip_operation_report_create', 'trip_operation_report_edit'],
        'regional_manager': ['dashboard_view',
                             'route_request_view', 'route_request_approve',
                             'route_request_reject', 'route_request_download',
                             'penalty_view', 'penalty_edit', 'penalty_download',
                             'trip_operation_report_view', 'trip_operation_report_download',
                             'report_view', 'report_export', 'report_download',
                             'department_view', 'position_view'],
        'hr_manager': ['dashboard_view',
                       'penalty_view', 'penalty_create', 'penalty_edit',
                       'penalty_download',
                       'department_view', 'department_create', 'department_edit',
                       'position_view', 'position_create', 'position_edit',
                       'report_view', 'report_export', 'report_download'],
    }

    def has_permission(self, permission):
        if self.assigned_role:
            return permission in (self.assigned_role.permissions or [])
        if self.role in self.LEGACY_PERMISSIONS:
            return permission in self.LEGACY_PERMISSIONS[self.role]
        return False

    def has_any_permission(self, *permissions):
        if self.assigned_role:
            role_perms = self.assigned_role.permissions or []
            return any(p in role_perms for p in permissions)
        if self.role in self.LEGACY_PERMISSIONS:
            role_perms = self.LEGACY_PERMISSIONS[self.role]
            return any(p in role_perms for p in permissions)
        return False

    @property
    def role_label(self):
        if self.assigned_role:
            return self.assigned_role.label or self.assigned_role.name
        labels = {
            'admin': _('Administrator'),
            'it_staff': _('IT Staff'),
            'branch_manager': _('Branch Manager'),
            'regional_manager': _('Regional Manager'),
            'hr_manager': _('HR Manager')
        }
        return labels.get(self.role, self.role)


class Role(db.Model):
    __tablename__ = 'roles'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    label = db.Column(db.String(100))
    permissions = db.Column(db.JSON, nullable=False, default=list)
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))

    @property
    def permission_count(self):
        return len(self.permissions or [])

    def get_permissions(self):
        return self.permissions or []


class RouteRequest(db.Model):
    __tablename__ = 'route_requests'
    id = db.Column(db.Integer, primary_key=True)
    request_id = db.Column(db.String(20), unique=True, nullable=False)
    request_date = db.Column(db.Date, default=date.today)
    requester_name = db.Column(db.String(100), nullable=False)
    requester_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    destination_from = db.Column(db.String(200), nullable=False)
    destination_to = db.Column(db.String(200), nullable=False)
    branch_location = db.Column(db.String(200))
    company = db.Column(db.String(200))
    transportation = db.Column(db.String(100))
    national_road = db.Column(db.String(50))
    price = db.Column(db.Float, default=0)
    departure_time = db.Column(db.String(10))
    arrival_time = db.Column(db.String(10))
    start_date = db.Column(db.Date)
    end_date = db.Column(db.Date)
    allow_access = db.Column(db.Boolean, default=True)
    attachment = db.Column(db.String(255))
    remarks = db.Column(db.Text)
    status = db.Column(db.String(20), default='Pending')  # Pending, Approved, Rejected
    reviewed_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    review_note = db.Column(db.Text)
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))

    requester = db.relationship('User', foreign_keys=[requester_id])
    reviewer = db.relationship('User', foreign_keys=[reviewed_by])

    def generate_id(self):
        count = RouteRequest.query.count() + 1
        self.request_id = f"RR-{datetime.now().year}-{count:04d}"


class EmployeePenalty(db.Model):
    __tablename__ = 'employee_penalties'
    id = db.Column(db.Integer, primary_key=True)
    penalty_id = db.Column(db.String(20), unique=True, nullable=False)
    employee_id = db.Column(db.String(20), nullable=False)
    employee_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100))
    position = db.Column(db.String(100))
    violation_type = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    penalty_amount = db.Column(db.Float, default=0)
    evidence_file = db.Column(db.String(255))
    incident_date = db.Column(db.Date, default=date.today)
    approved_by = db.Column(db.String(100))
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    status = db.Column(db.String(20), default='Pending')
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))

    creator = db.relationship('User', foreign_keys=[created_by])

    def generate_id(self):
        last = EmployeePenalty.query.order_by(EmployeePenalty.id.desc()).first()

        if last and last.penalty_id:
            try:
                num = int(last.penalty_id.split('-')[-1]) + 1
            except:
                num = 1
        else:
            num = 1

        self.penalty_id = f"EP-{datetime.now().year}-{num:04d}"


class TripOperationReport(db.Model):
    __tablename__ = 'trip_operation_reports'
    id = db.Column(db.Integer, primary_key=True)
    report_id = db.Column(db.String(20), unique=True, nullable=False)
    origin = db.Column(db.String(200), default='')
    destination = db.Column(db.String(200), default='')
    travel_direction = db.Column(db.String(50), default='')
    departure_time = db.Column(db.String(10))
    power_off_time = db.Column(db.String(10))
    power_on_time = db.Column(db.String(10))
    vehicle_number = db.Column(db.String(50), nullable=False)
    driver_phone = db.Column(db.String(50))
    arrival_at_station = db.Column(db.String(10))
    departure_from_station = db.Column(db.String(10))
    travel_delay_duration = db.Column(db.Float, default=0)
    reason_for_delay = db.Column(db.Text)
    vehicle_status = db.Column(db.String(50), nullable=False)
    passenger_count = db.Column(db.Integer, default=0)
    coordinator_name = db.Column(db.String(100))
    note = db.Column(db.Text)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))

    creator = db.relationship('User', foreign_keys=[created_by])

    def generate_id(self):
        count = TripOperationReport.query.count() + 1
        self.report_id = f"TOR-{datetime.now().year}-{count:04d}"


# ─────────────────────────────────────────
#  HR MODULE MODELS
# ─────────────────────────────────────────

class Department(db.Model):
    __tablename__ = 'departments'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), default='Active')
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    positions = db.relationship('Position', back_populates='department', lazy='dynamic')


class Position(db.Model):
    __tablename__ = 'positions'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey('departments.id'), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), default='Active')
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    department = db.relationship('Department', back_populates='positions')


# ─────────────────────────────────────────
#  DYNAMIC CONFIGURATION ENGINE (Metadata Models)
# ─────────────────────────────────────────

class ConfigModule(db.Model):
    __tablename__ = 'config_module'
    id = db.Column(db.Integer, primary_key=True)
    module_key = db.Column(db.String(100), unique=True, nullable=False)
    module_name = db.Column(db.String(200), nullable=False)
    module_icon = db.Column(db.String(50), default='fa-database')
    table_name = db.Column(db.String(100))
    sort_order = db.Column(db.Integer, default=0)
    is_active = db.Column(db.Boolean, default=True)
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))


class ConfigField(db.Model):
    __tablename__ = 'config_field'
    id = db.Column(db.Integer, primary_key=True)
    module_id = db.Column(db.Integer, db.ForeignKey('config_module.id'), nullable=False)
    field_name = db.Column(db.String(100), nullable=False)
    field_label = db.Column(db.String(200), nullable=False)
    field_type = db.Column(db.String(50), nullable=False)  # text, number, date, dropdown, textarea, checkbox, boolean, email, tel, password
    is_required = db.Column(db.Boolean, default=False)
    is_unique = db.Column(db.Boolean, default=False)
    is_listable = db.Column(db.Boolean, default=True)
    is_searchable = db.Column(db.Boolean, default=False)
    is_sortable = db.Column(db.Boolean, default=True)
    is_editable = db.Column(db.Boolean, default=True)
    is_creatable = db.Column(db.Boolean, default=True)
    display_order = db.Column(db.Integer, default=0)
    default_value = db.Column(db.String(500))
    placeholder = db.Column(db.String(500))
    help_text = db.Column(db.String(500))
    min_length = db.Column(db.Integer)
    max_length = db.Column(db.Integer)
    regex_pattern = db.Column(db.String(500))
    regex_message = db.Column(db.String(500))
    option_source = db.Column(db.String(20))  # static, module, api
    option_module_id = db.Column(db.Integer, db.ForeignKey('config_module.id'))
    option_parent_field = db.Column(db.String(100))
    rel_module_id = db.Column(db.Integer, db.ForeignKey('config_module.id'))
    rel_type = db.Column(db.String(20))  # one_to_many, many_to_one
    grid_width = db.Column(db.Integer)
    module = db.relationship('ConfigModule', foreign_keys=[module_id], backref='fields')
    option_module = db.relationship('ConfigModule', foreign_keys=[option_module_id])
    rel_module = db.relationship('ConfigModule', foreign_keys=[rel_module_id])


class ConfigValidation(db.Model):
    __tablename__ = 'config_validation'
    id = db.Column(db.Integer, primary_key=True)
    field_id = db.Column(db.Integer, db.ForeignKey('config_field.id'), nullable=False)
    validation_type = db.Column(db.String(50), nullable=False)  # required, unique, min_length, max_length, regex, custom
    validation_value = db.Column(db.String(500))
    error_message = db.Column(db.String(500))
    field = db.relationship('ConfigField', backref='validations')


class ConfigDropdownOption(db.Model):
    __tablename__ = 'config_dropdown_option'
    id = db.Column(db.Integer, primary_key=True)
    field_id = db.Column(db.Integer, db.ForeignKey('config_field.id'), nullable=False)
    option_value = db.Column(db.String(200), nullable=False)
    option_label = db.Column(db.String(200), nullable=False)
    sort_order = db.Column(db.Integer, default=0)
    is_active = db.Column(db.Boolean, default=True)
    field = db.relationship('ConfigField', backref='dropdown_options')


class ConfigModulePermission(db.Model):
    __tablename__ = 'config_module_permission'
    id = db.Column(db.Integer, primary_key=True)
    module_id = db.Column(db.Integer, db.ForeignKey('config_module.id'), nullable=False)
    role = db.Column(db.String(50), nullable=False)
    can_create = db.Column(db.Boolean, default=False)
    can_read = db.Column(db.Boolean, default=True)
    can_update = db.Column(db.Boolean, default=False)
    can_delete = db.Column(db.Boolean, default=False)
    field_permissions = db.Column(db.JSON)  # {"field_name": "read_only|hidden"}
    module = db.relationship('ConfigModule', backref='permissions')


class DynamicRecord(db.Model):
    __tablename__ = 'dynamic_record'
    id = db.Column(db.Integer, primary_key=True)
    module_id = db.Column(db.Integer, db.ForeignKey('config_module.id'), nullable=False)
    data = db.Column(db.JSON, nullable=False, default=dict)
    is_active = db.Column(db.Boolean, default=True)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_date = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    updated_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    updated_date = db.Column(db.DateTime, onupdate=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
    deleted_date = db.Column(db.DateTime)
    module = db.relationship('ConfigModule', backref='records')
    creator = db.relationship('User', foreign_keys=[created_by])
    updater = db.relationship('User', foreign_keys=[updated_by])


# ─────────────────────────────────────────
#  AUTH
# ─────────────────────────────────────────

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))


def role_required(*roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if not current_user.is_authenticated:
                return redirect(url_for('login'))
            if current_user.role not in roles:
                flash(_('You do not have permission to access this page.'), 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated
    return decorator


def permission_required(permission):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if not current_user.is_authenticated:
                return redirect(url_for('login'))
            if not current_user.has_permission(permission):
                flash(_('You do not have permission to access this page.'), 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated
    return decorator


def any_permission_required(*permissions):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if not current_user.is_authenticated:
                return redirect(url_for('login'))
            if not current_user.has_any_permission(*permissions):
                flash(_('You do not have permission to access this page.'), 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated
    return decorator


# ─────────────────────────────────────────
#  ROUTES: AUTH
# ─────────────────────────────────────────

@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        user = User.query.filter_by(username=username).first()
        if user and user.check_password(password) and user.is_active:
            login_user(user)
            return redirect(url_for('dashboard'))
        flash(_('Invalid username or password.'), 'danger')
    logo_path = os.path.join(app.config['UPLOAD_FOLDER'], 'Image logo.png')
    login_logo_url = url_for('static', filename='uploads/Image logo.png') if os.path.exists(logo_path) else None
    return render_template('login.html', login_logo_url=login_logo_url)


@app.route('/upload-logo', methods=['POST'])
@login_required
@any_permission_required('system_settings_edit', 'system_settings_update')
def upload_logo():
    file = request.files.get('logo')
    if file and file.filename:
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
        if ext not in ('png', 'jpg', 'jpeg', 'gif', 'svg'):
            flash(_('Logo must be an image file (PNG, JPG, GIF, SVG).'), 'danger')
        else:
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], 'logo.png'))
            flash(_('Logo uploaded successfully!'), 'success')
    else:
        flash(_('No file selected.'), 'danger')
    return redirect(request.referrer or url_for('dashboard'))


@app.route('/delete-logo', methods=['POST'])
@login_required
@any_permission_required('system_settings_edit', 'system_settings_update')
def delete_logo():
    logo_path = os.path.join(app.config['UPLOAD_FOLDER'], 'logo.png')
    if os.path.exists(logo_path):
        os.remove(logo_path)
        flash(_('Logo removed.'), 'info')
    return redirect(request.referrer or url_for('dashboard'))


@app.route('/set-language/<lang>')
def set_language(lang):
    if lang in ['en', 'km']:
        session['lang'] = lang
    return redirect(request.referrer or url_for('dashboard'))


@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))


# ─────────────────────────────────────────
#  ROUTES: DASHBOARD
# ─────────────────────────────────────────

@app.route('/dashboard')
@login_required
def dashboard():
    from datetime import timedelta

    range_filter = request.args.get('range', 'all')
    now = datetime.now()
    today = date.today()

    # Determine date range
    custom_start = ''
    custom_end = ''
    if range_filter == 'today':
        start_date = today
        end_date = today
    elif range_filter == 'week':
        start_date = today - timedelta(days=today.weekday())
        end_date = today
    elif range_filter == 'month':
        start_date = today.replace(day=1)
        end_date = today
    elif range_filter == 'year':
        start_date = today.replace(month=1, day=1)
        end_date = today
    elif range_filter == 'custom':
        raw_start = request.args.get('start_date', '')
        raw_end = request.args.get('end_date', '')
        try:
            start_date = datetime.strptime(raw_start, '%Y-%m-%d').date() if raw_start else None
            end_date = datetime.strptime(raw_end, '%Y-%m-%d').date() if raw_end else None
            custom_start = raw_start
            custom_end = raw_end
        except (ValueError, TypeError):
            start_date = None
            end_date = None
            range_filter = 'all'
    else:
        start_date = None
        end_date = None

    def date_filtered_count(model, **filters):
        q = model.query
        if start_date:
            q = q.filter(model.created_date >= datetime.combine(start_date, datetime.min.time()))
        if end_date:
            q = q.filter(model.created_date <= datetime.combine(end_date, datetime.max.time()))
        for k, v in filters.items():
            if hasattr(model, k):
                q = q.filter(getattr(model, k) == v)
        return q.count()

    def date_filtered_base(model):
        q = model.query
        if start_date:
            q = q.filter(model.created_date >= datetime.combine(start_date, datetime.min.time()))
        if end_date:
            q = q.filter(model.created_date <= datetime.combine(end_date, datetime.max.time()))
        return q

    total_requests = date_filtered_count(RouteRequest)
    pending_requests = date_filtered_count(RouteRequest, status='Pending')
    approved_requests = date_filtered_count(RouteRequest, status='Approved')
    rejected_requests = date_filtered_count(RouteRequest, status='Rejected')

    total_penalties = date_filtered_count(EmployeePenalty)
    total_penalty_amount = db.session.query(db.func.sum(EmployeePenalty.penalty_amount)).scalar() or 0
    pending_penalties = date_filtered_count(EmployeePenalty, status='Pending')

    total_reports = date_filtered_count(TripOperationReport)
    departed_reports = date_filtered_count(TripOperationReport, vehicle_status='Departed')
    not_departed_reports = date_filtered_count(TripOperationReport, vehicle_status='Not Departed')
    total_passengers = db.session.query(db.func.sum(TripOperationReport.passenger_count)).scalar() or 0

    processed_requests = approved_requests + rejected_requests

    recent_requests = RouteRequest.query.order_by(RouteRequest.created_date.desc()).limit(10).all()
    recent_penalties = EmployeePenalty.query.order_by(EmployeePenalty.created_date.desc()).limit(5).all()
    recent_reports = TripOperationReport.query.order_by(TripOperationReport.created_date.desc()).limit(5).all()

    # Monthly data for charts (last 6 months)
    monthly_data = defaultdict(lambda: {'requests': 0, 'penalties': 0, 'reports': 0, 'trip_departed': 0, 'trip_not_departed': 0})
    for r in RouteRequest.query.all():
        key = r.created_date.strftime('%b %Y') if r.created_date else 'Unknown'
        monthly_data[key]['requests'] += 1
    for p in EmployeePenalty.query.all():
        key = p.created_date.strftime('%b %Y') if p.created_date else 'Unknown'
        monthly_data[key]['penalties'] += 1
    for r in TripOperationReport.query.all():
        key = r.created_date.strftime('%b %Y') if r.created_date else 'Unknown'
        monthly_data[key]['reports'] += 1
        if r.vehicle_status == 'Departed':
            monthly_data[key]['trip_departed'] += 1
        else:
            monthly_data[key]['trip_not_departed'] += 1
    monthly_labels = sorted(monthly_data.keys(), key=lambda k: datetime.strptime(k, '%b %Y') if k != 'Unknown' else datetime.min)
    monthly_requests = [monthly_data[k]['requests'] for k in monthly_labels]
    monthly_penalties = [monthly_data[k]['penalties'] for k in monthly_labels]
    monthly_reports = [monthly_data[k]['reports'] for k in monthly_labels]
    monthly_trip_departed = [monthly_data[k]['trip_departed'] for k in monthly_labels]
    monthly_trip_not_departed = [monthly_data[k]['trip_not_departed'] for k in monthly_labels]

    # KPI Trends (compare first vs second half of monthly data)
    def compute_trend(current_val, label):
        mid = len(monthly_labels) // 2
        if len(monthly_data) < 2 or 'Unknown' in monthly_data:
            return {'label': 'No trend', 'cls': 'neutral', 'icon': 'minus'}
        first_half = sum(monthly_data[k][label] for k in monthly_labels[:mid]) or 1
        second_half = sum(monthly_data[k][label] for k in monthly_labels[mid:]) or 1
        pct = int((second_half - first_half) / first_half * 100)
        if pct > 0:
            return {'label': f'+{pct}%', 'cls': 'up', 'icon': 'arrow-up'}
        elif pct < 0:
            return {'label': f'{pct}%', 'cls': 'down', 'icon': 'arrow-down'}
        return {'label': '0%', 'cls': 'neutral', 'icon': 'minus'}

    kpi_trends = {
        'total_requests': compute_trend(total_requests, 'requests'),
        'pending_requests': compute_trend(pending_requests, 'requests'),
        'approved_requests': compute_trend(approved_requests, 'requests'),
        'rejected_requests': compute_trend(rejected_requests, 'requests'),
        'total_penalties': compute_trend(total_penalties, 'penalties'),
        'total_penalty_amount': {'label': '', 'cls': 'neutral', 'icon': 'minus'},
        'pending_penalties': compute_trend(pending_penalties, 'penalties'),
        'processed_requests': compute_trend(processed_requests, 'requests'),
        'total_reports': compute_trend(total_reports, 'reports'),
        'departed_reports': compute_trend(departed_reports, 'trip_departed'),
        'not_departed_reports': compute_trend(not_departed_reports, 'trip_not_departed'),
        'total_passengers': {'label': '', 'cls': 'neutral', 'icon': 'minus'},
    }

    # Recent Activities (combine all record types, sorted by time)
    activities = []
    for rr in RouteRequest.query.order_by(RouteRequest.created_date.desc()).limit(5).all():
        activities.append({
            'icon': 'fas fa-route',
            'bg_color': '#dbeafe',
            'color': '#1d4ed8',
            'title': 'Route Request',
            'description': f'{rr.requester_name} - {rr.destination_from} to {rr.destination_to} ({rr.status})',
            'time_ago': rr.created_date.strftime('%d %b %Y, %H:%M') if rr.created_date else '',
        })
    for ep in EmployeePenalty.query.order_by(EmployeePenalty.created_date.desc()).limit(5).all():
        activities.append({
            'icon': 'fas fa-gavel',
            'bg_color': '#ede9fe',
            'color': '#7c3aed',
            'title': 'Penalty Record',
            'description': f'{ep.employee_name} - {ep.violation_type} (${ep.penalty_amount:.0f})',
            'time_ago': ep.created_date.strftime('%d %b %Y, %H:%M') if ep.created_date else '',
        })
    for tor in TripOperationReport.query.order_by(TripOperationReport.created_date.desc()).limit(5).all():
        activities.append({
            'icon': 'fas fa-bus',
            'bg_color': '#e0f2fe',
            'color': '#0284c7',
            'title': 'Trip Report',
            'description': f'{tor.origin} to {tor.destination} - {tor.vehicle_number} ({tor.vehicle_status})',
            'time_ago': tor.created_date.strftime('%d %b %Y, %H:%M') if tor.created_date else '',
        })
    activities.sort(key=lambda a: a['time_ago'], reverse=True)
    recent_activities = activities[:10]

    # Notifications
    notifications = []
    pending_route_requests = RouteRequest.query.filter_by(status='Pending').count()
    if pending_route_requests > 0:
        notifications.append({
            'message': f'{pending_route_requests} route request(s) pending approval',
            'time_ago': 'Requires attention',
            'dot_color': '#f59e0b',
        })
    pending_penalties_count = EmployeePenalty.query.filter_by(status='Pending').count()
    if pending_penalties_count > 0:
        notifications.append({
            'message': f'{pending_penalties_count} penalty record(s) pending review',
            'time_ago': 'Requires attention',
            'dot_color': '#7c3aed',
        })
    if current_user.role == 'admin':
        total_users = User.query.count()
        notifications.append({
            'message': f'{total_users} registered user(s) in the system',
            'time_ago': 'System info',
            'dot_color': '#059669',
        })
    if not notifications:
        notifications.append({
            'message': 'All caught up! No pending items.',
            'time_ago': 'No action needed',
            'dot_color': '#94a3b8',
        })

    logo_path = os.path.join(app.config['UPLOAD_FOLDER'], 'Image logo.png')
    login_logo_url = url_for('static', filename='uploads/Image logo.png') if os.path.exists(logo_path) else None

    return render_template('dashboard.html',
        total_requests=total_requests,
        pending_requests=pending_requests,
        approved_requests=approved_requests,
        rejected_requests=rejected_requests,
        processed_requests=processed_requests,
        total_penalties=total_penalties,
        total_penalty_amount=total_penalty_amount,
        pending_penalties=pending_penalties,
        recent_requests=recent_requests,
        recent_penalties=recent_penalties,
        monthly_labels=monthly_labels,
        monthly_requests=monthly_requests,
        monthly_penalties=monthly_penalties,
        monthly_reports=monthly_reports,
        monthly_trip_departed=monthly_trip_departed,
        monthly_trip_not_departed=monthly_trip_not_departed,
        total_reports=total_reports,
        departed_reports=departed_reports,
        not_departed_reports=not_departed_reports,
        total_passengers=total_passengers,
        recent_reports=recent_reports,
        login_logo_url=login_logo_url,
        range_filter=range_filter,
        kpi_trends=kpi_trends,
        recent_activities=recent_activities,
        notifications=notifications,
        pending_route_requests=pending_route_requests,
        pending_penalties_count=pending_penalties_count,
        custom_start=custom_start,
        custom_end=custom_end,
    )


# ─────────────────────────────────────────
#  ROUTES: ROUTE REQUESTS
# ─────────────────────────────────────────

@app.route('/route-requests')
@login_required
@any_permission_required('route_request_view', 'route_request_create', 'route_request_edit', 'route_request_delete', 'route_request_approve', 'route_request_reject', 'route_request_download')
def route_requests():
    base = RouteRequest.query
    if current_user.role == 'branch_manager':
        base = base.filter_by(requester_id=current_user.id)
    status_filter = request.args.get('status', '')
    search = request.args.get('search', '')
    query = base
    if status_filter:
        query = query.filter_by(status=status_filter)
    if search:
        query = query.filter(
            (RouteRequest.request_id.contains(search)) |
            (RouteRequest.requester_name.contains(search)) |
            (RouteRequest.destination_from.contains(search)) |
            (RouteRequest.destination_to.contains(search))
        )
    requests_list = query.order_by(RouteRequest.created_date.desc()).all()
    total_count = base.count()
    pending_count = base.filter_by(status='Pending').count()
    approved_count = base.filter_by(status='Approved').count()
    rejected_count = base.filter_by(status='Rejected').count()
    return render_template('route_requests.html', requests=requests_list,
                           status_filter=status_filter, search=search,
                           total_count=total_count,
                           pending_count=pending_count,
                           approved_count=approved_count,
                           rejected_count=rejected_count)


@app.route('/route-requests/new', methods=['GET', 'POST'])
@login_required
@permission_required('route_request_create')
def new_route_request():
    # Fetch dynamic data for dropdowns
    dest_module = ConfigModule.query.filter_by(module_key='destination', is_active=True).first()
    transport_module = ConfigModule.query.filter_by(module_key='transportation_type', is_active=True).first()
    route_module = ConfigModule.query.filter_by(module_key='route', is_active=True).first()

    destinations = DynamicRecord.query.filter_by(module_id=dest_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if dest_module else []
    transport_types = DynamicRecord.query.filter_by(module_id=transport_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if transport_module else []
    routes_list = DynamicRecord.query.filter_by(module_id=route_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if route_module else []

    # Fetch companies and branches from System Settings
    company_module = ConfigModule.query.filter_by(module_key='company', is_active=True).first()
    branch_module = ConfigModule.query.filter_by(module_key='branch', is_active=True).first()
    companies = DynamicRecord.query.filter_by(module_id=company_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if company_module else []
    branches = DynamicRecord.query.filter_by(module_id=branch_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if branch_module else []

    if request.method == 'POST':
        destination_from = (request.form.get('destination_from') or '').strip()
        destination_to = (request.form.get('destination_to') or '').strip()
        if not destination_from or not destination_to:
            flash(_('Origin and destination are required.'), 'danger')
            return render_template('route_request_form.html', request_obj=None, destinations=destinations, transport_types=transport_types, routes_list=routes_list, companies=companies, branches=branches)

        rr = RouteRequest()
        rr.generate_id()
        rr.requester_name = current_user.full_name
        rr.requester_id = current_user.id
        rr.destination_from = destination_from
        rr.destination_to = destination_to
        rr.branch_location = request.form.get('branch_location', '')
        rr.company = request.form.get('company', '')
        rr.transportation = request.form.get('transportation')
        rr.national_road = request.form.get('national_road')
        rr.price = abs(float(request.form.get('price') or 0))
        rr.departure_time = request.form.get('departure_time')
        rr.arrival_time = request.form.get('arrival_time')
        start = request.form.get('start_date')
        end = request.form.get('end_date')
        rr.start_date = datetime.strptime(start, '%Y-%m-%d').date() if start else None
        rr.end_date = datetime.strptime(end, '%Y-%m-%d').date() if end else None
        rr.allow_access = 'allow_access' in request.form
        rr.remarks = request.form.get('remarks')
        rr.request_date = date.today()

        file = request.files.get('attachment')
        rr.attachment = save_upload(file)

        db.session.add(rr)
        db.session.commit()
        flash(_('Route Request %(id)s submitted successfully!', id=rr.request_id), 'success')
        return redirect(url_for('route_requests'))
    return render_template('route_request_form.html', request_obj=None, destinations=destinations, transport_types=transport_types, routes_list=routes_list, companies=companies, branches=branches)


@app.route('/route-requests/<int:id>')
@login_required
def view_route_request(id):
    rr = RouteRequest.query.get_or_404(id)
    return render_template('route_request_detail.html', rr=rr)


@app.route('/route-requests/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('route_request_edit')
def edit_route_request(id):
    rr = RouteRequest.query.get_or_404(id)
    # Fetch dynamic data for dropdowns
    dest_module = ConfigModule.query.filter_by(module_key='destination', is_active=True).first()
    transport_module = ConfigModule.query.filter_by(module_key='transportation_type', is_active=True).first()
    route_module = ConfigModule.query.filter_by(module_key='route', is_active=True).first()
    destinations = DynamicRecord.query.filter_by(module_id=dest_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if dest_module else []
    transport_types = DynamicRecord.query.filter_by(module_id=transport_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if transport_module else []
    routes_list = DynamicRecord.query.filter_by(module_id=route_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if route_module else []

    # Fetch companies and branches from System Settings
    company_module = ConfigModule.query.filter_by(module_key='company', is_active=True).first()
    branch_module = ConfigModule.query.filter_by(module_key='branch', is_active=True).first()
    companies = DynamicRecord.query.filter_by(module_id=company_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if company_module else []
    branches = DynamicRecord.query.filter_by(module_id=branch_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if branch_module else []

    if current_user.role == 'branch_manager' and rr.requester_id != current_user.id:
        flash(_('Access denied.'), 'danger')
        return redirect(url_for('route_requests'))
    if rr.status != 'Pending' and current_user.role not in ['admin']:
        flash(_('Only pending requests can be edited.'), 'warning')
        return redirect(url_for('view_route_request', id=id))
    if request.method == 'POST':
        destination_from = (request.form.get('destination_from') or '').strip()
        destination_to = (request.form.get('destination_to') or '').strip()
        if not destination_from or not destination_to:
            flash(_('Origin and destination are required.'), 'danger')
            return render_template('route_request_form.html', request_obj=rr, destinations=destinations, transport_types=transport_types, routes_list=routes_list, companies=companies, branches=branches)
        rr.requester_name = rr.requester_name
        rr.destination_from = destination_from
        rr.destination_to = destination_to
        rr.branch_location = request.form.get('branch_location', '')
        rr.company = request.form.get('company', '')
        rr.transportation = request.form.get('transportation')
        rr.national_road = request.form.get('national_road')
        rr.price = float(request.form.get('price') or 0)
        rr.departure_time = request.form.get('departure_time')
        rr.arrival_time = request.form.get('arrival_time')
        start = request.form.get('start_date')
        end = request.form.get('end_date')
        rr.start_date = datetime.strptime(start, '%Y-%m-%d').date() if start else None
        rr.end_date = datetime.strptime(end, '%Y-%m-%d').date() if end else None
        rr.allow_access = 'allow_access' in request.form
        rr.remarks = request.form.get('remarks')
        rr.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        flash(_('Request updated successfully!'), 'success')
        return redirect(url_for('view_route_request', id=id))
    return render_template('route_request_form.html', request_obj=rr, destinations=destinations, transport_types=transport_types, routes_list=routes_list, companies=companies, branches=branches)


@app.route('/route-requests/<int:id>/review', methods=['POST'])
@login_required
@any_permission_required('route_request_approve', 'route_request_reject')
def review_route_request(id):
    rr = RouteRequest.query.get_or_404(id)
    action = request.form.get('action')
    note = request.form.get('review_note', '')
    if action in ['Approved', 'Rejected']:
        rr.status = action
        rr.reviewed_by = current_user.id
        rr.review_note = note
        rr.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        flash(_('Request %(action)s successfully!', action=action), 'success')
    return redirect(url_for('view_route_request', id=id))


@app.route('/route-requests/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('route_request_delete')
def delete_route_request(id):
    rr = RouteRequest.query.get_or_404(id)
    delete_upload(rr.attachment)
    db.session.delete(rr)
    db.session.commit()
    flash(_('Request deleted.'), 'info')
    return redirect(url_for('route_requests'))

# _________________________________________
# ROUTES: CREATES ROLE
#___________________________________________

# ─────────────────────────────────────────
#  ROUTES: EMPLOYEE PENALTIES
# ─────────────────────────────────────────

@app.route('/penalties')
@login_required
@any_permission_required('penalty_view', 'penalty_create', 'penalty_edit', 'penalty_delete', 'penalty_download')
def penalties():
    base = EmployeePenalty.query
    status_filter = request.args.get('status', '')
    search = request.args.get('search', '')
    query = base
    if status_filter:
        query = query.filter_by(status=status_filter)
    if search:
        query = query.filter(
            (EmployeePenalty.employee_id.contains(search)) |
            (EmployeePenalty.employee_name.contains(search)) |
            (EmployeePenalty.department.contains(search)) |
            (EmployeePenalty.violation_type.contains(search))
        )
    penalties_list = query.order_by(EmployeePenalty.created_date.desc()).all()
    total_count = base.count()
    pending_count = base.filter_by(status='Pending').count()
    approved_count = base.filter_by(status='Approved').count()
    rejected_count = base.filter_by(status='Rejected').count()
    return render_template('penalties.html', penalties=penalties_list,
                           status_filter=status_filter, search=search,
                           total_count=total_count,
                           pending_count=pending_count,
                           approved_count=approved_count,
                           rejected_count=rejected_count)


@app.route('/penalties/new', methods=['GET', 'POST'])
@login_required
@permission_required('penalty_create')
def new_penalty():
    if request.method == 'POST':
        employee_id = (request.form.get('employee_id') or '').strip()
        employee_name = (request.form.get('employee_name') or '').strip()
        violation_type = request.form.get('violation_type')
        if not employee_id or not employee_name:
            flash(_('Employee ID and name are required.'), 'danger')
            return render_template('penalty_form.html', penalty=None)

        ep = EmployeePenalty()
        ep.generate_id()
        ep.employee_id = employee_id
        ep.employee_name = employee_name
        ep.department = request.form.get('department')
        ep.position = request.form.get('position')
        ep.violation_type = violation_type
        ep.description = request.form.get('description')
        ep.penalty_amount = abs(float(request.form.get('penalty_amount') or 0))
        ep.approved_by = request.form.get('approved_by')
        ep.created_by = current_user.id
        inc_date = request.form.get('incident_date')
        ep.incident_date = datetime.strptime(inc_date, '%Y-%m-%d').date() if inc_date else date.today()

        file = request.files.get('evidence_file')
        ep.evidence_file = save_upload(file)

        db.session.add(ep)
        db.session.commit()
        flash(_('Penalty Record %(id)s created successfully!', id=ep.penalty_id), 'success')
        return redirect(url_for('penalties'))
    return render_template('penalty_form.html', penalty=None)


@app.route('/penalties/<int:id>')
@login_required
@permission_required('penalty_view')
def view_penalty(id):
    ep = EmployeePenalty.query.get_or_404(id)
    return render_template('penalty_detail.html', ep=ep)


@app.route('/penalties/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('penalty_edit')
def edit_penalty(id):
    ep = EmployeePenalty.query.get_or_404(id)
    if ep.status != 'Pending' and current_user.role != 'admin':
        flash(_('Only pending penalties can be edited.'), 'warning')
        return redirect(url_for('view_penalty', id=id))
    if request.method == 'POST':
        employee_id = (request.form.get('employee_id') or '').strip()
        employee_name = (request.form.get('employee_name') or '').strip()
        if not employee_id or not employee_name:
            flash(_('Employee ID and name are required.'), 'danger')
            return render_template('penalty_form.html', penalty=ep)
        ep.employee_id = employee_id
        ep.employee_name = employee_name
        ep.department = request.form.get('department')
        ep.position = request.form.get('position')
        ep.violation_type = request.form.get('violation_type')
        ep.description = request.form.get('description')
        ep.penalty_amount = abs(float(request.form.get('penalty_amount') or 0))
        ep.approved_by = request.form.get('approved_by')
        inc_date = request.form.get('incident_date')
        ep.incident_date = datetime.strptime(inc_date, '%Y-%m-%d').date() if inc_date else ep.incident_date
        ep.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        flash(_('Penalty record updated!'), 'success')
        return redirect(url_for('view_penalty', id=id))
    return render_template('penalty_form.html', penalty=ep)


@app.route('/penalties/<int:id>/approve', methods=['POST'])
@login_required
@permission_required('penalty_edit')
def approve_penalty(id):
    ep = EmployeePenalty.query.get_or_404(id)
    action = request.form.get('action')
    if action in ['Approved', 'Rejected']:
        ep.status = action
        ep.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        flash(_('Penalty %(action)s!', action=action), 'success')
    return redirect(url_for('view_penalty', id=id))


@app.route('/penalties/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('penalty_delete')
def delete_penalty(id):
    ep = EmployeePenalty.query.get_or_404(id)
    delete_upload(ep.evidence_file)
    db.session.delete(ep)
    db.session.commit()
    flash(_('Penalty record deleted.'), 'info')
    return redirect(url_for('penalties'))


# ─────────────────────────────────────────
#  ROUTES: TRIP OPERATION REPORTS
# ─────────────────────────────────────────

@app.route('/trip-operation-reports')
@login_required
@any_permission_required('trip_operation_report_view', 'trip_operation_report_create', 'trip_operation_report_edit', 'trip_operation_report_delete', 'trip_operation_report_download')
def trip_operation_reports():
    base = TripOperationReport.query
    search = request.args.get('search', '')
    direction_filter = request.args.get('direction', '')
    status_filter = request.args.get('vehicle_status', '')
    query = base
    if search:
        query = query.filter(
            (TripOperationReport.report_id.contains(search)) |
            (TripOperationReport.vehicle_number.contains(search)) |
            (TripOperationReport.driver_phone.contains(search)) |
            (TripOperationReport.coordinator_name.contains(search))
        )
    if direction_filter:
        query = query.filter(
            (TripOperationReport.origin.contains(direction_filter)) |
            (TripOperationReport.destination.contains(direction_filter))
        )
    if status_filter:
        query = query.filter_by(vehicle_status=status_filter)
    reports = query.order_by(TripOperationReport.created_date.desc()).all()
    total_count = base.count()
    departed_count = base.filter_by(vehicle_status='Departed').count()
    not_departed_count = base.filter_by(vehicle_status='Not Departed').count()
    return render_template('trip_operation_reports.html', reports=reports,
                           search=search, direction_filter=direction_filter,
                           status_filter=status_filter,
                           total_count=total_count,
                           departed_count=departed_count,
                           not_departed_count=not_departed_count)


@app.route('/trip-operation-reports/new', methods=['GET', 'POST'])
@login_required
@permission_required('trip_operation_report_create')
def new_trip_operation_report():
    dest_module = ConfigModule.query.filter_by(module_key='destination', is_active=True).first()
    destinations = DynamicRecord.query.filter_by(module_id=dest_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if dest_module else []

    if request.method == 'POST':
        origin = (request.form.get('origin') or '').strip()
        destination = (request.form.get('destination') or '').strip()
        departure_time_str = request.form.get('departure_time')
        vehicle_number = (request.form.get('vehicle_number') or '').strip()
        vehicle_status = (request.form.get('vehicle_status') or '').strip()

        errors = []
        if not origin:
            errors.append(_('Origin is required.'))
        if not destination:
            errors.append(_('Destination is required.'))
        if not departure_time_str:
            errors.append(_('Departure Time is required.'))
        if not vehicle_number:
            errors.append(_('Vehicle Number is required.'))
        if not vehicle_status:
            errors.append(_('Vehicle Status is required.'))

        if errors:
            for e in errors:
                flash(e, 'danger')
            return render_template('trip_operation_report_form.html', report=None, destinations=destinations)

        tor = TripOperationReport()
        tor.generate_id()
        tor.origin = origin
        tor.destination = destination
        tor.departure_time = departure_time_str
        tor.power_off_time = request.form.get('power_off_time')
        tor.power_on_time = request.form.get('power_on_time')
        tor.vehicle_number = vehicle_number
        tor.driver_phone = request.form.get('driver_phone')
        tor.arrival_at_station = request.form.get('arrival_at_station')
        tor.departure_from_station = request.form.get('departure_from_station')
        tor.travel_delay_duration = abs(float(request.form.get('travel_delay_duration') or 0))
        tor.reason_for_delay = request.form.get('reason_for_delay')
        tor.vehicle_status = vehicle_status
        tor.passenger_count = abs(int(request.form.get('passenger_count') or 0))
        tor.coordinator_name = request.form.get('coordinator_name')
        tor.note = request.form.get('note')
        tor.created_by = current_user.id

        db.session.add(tor)
        db.session.commit()
        flash(_('Trip Operation Report %(id)s created successfully!', id=tor.report_id), 'success')
        return redirect(url_for('trip_operation_reports'))
    return render_template('trip_operation_report_form.html', report=None, destinations=destinations)


@app.route('/trip-operation-reports/<int:id>')
@login_required
def view_trip_operation_report(id):
    tor = TripOperationReport.query.get_or_404(id)
    return render_template('trip_operation_report_detail.html', tor=tor)


@app.route('/trip-operation-reports/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('trip_operation_report_edit')
def edit_trip_operation_report(id):
    tor = TripOperationReport.query.get_or_404(id)
    dest_module = ConfigModule.query.filter_by(module_key='destination', is_active=True).first()
    destinations = DynamicRecord.query.filter_by(module_id=dest_module.id, is_active=True).order_by(DynamicRecord.created_date.desc()).all() if dest_module else []

    if request.method == 'POST':
        origin = (request.form.get('origin') or '').strip()
        destination = (request.form.get('destination') or '').strip()
        departure_time_str = request.form.get('departure_time')
        vehicle_number = (request.form.get('vehicle_number') or '').strip()
        vehicle_status = (request.form.get('vehicle_status') or '').strip()

        errors = []
        if not origin:
            errors.append(_('Origin is required.'))
        if not destination:
            errors.append(_('Destination is required.'))
        if not departure_time_str:
            errors.append(_('Departure Time is required.'))
        if not vehicle_number:
            errors.append(_('Vehicle Number is required.'))
        if not vehicle_status:
            errors.append(_('Vehicle Status is required.'))

        if errors:
            for e in errors:
                flash(e, 'danger')
            return render_template('trip_operation_report_form.html', report=tor, destinations=destinations)

        tor.origin = origin
        tor.destination = destination
        tor.departure_time = departure_time_str
        tor.power_off_time = request.form.get('power_off_time')
        tor.power_on_time = request.form.get('power_on_time')
        tor.vehicle_number = vehicle_number
        tor.driver_phone = request.form.get('driver_phone')
        tor.arrival_at_station = request.form.get('arrival_at_station')
        tor.departure_from_station = request.form.get('departure_from_station')
        tor.travel_delay_duration = abs(float(request.form.get('travel_delay_duration') or 0))
        tor.reason_for_delay = request.form.get('reason_for_delay')
        tor.vehicle_status = vehicle_status
        tor.passenger_count = abs(int(request.form.get('passenger_count') or 0))
        tor.coordinator_name = request.form.get('coordinator_name')
        tor.note = request.form.get('note')
        tor.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        flash(_('Trip Operation Report updated successfully!'), 'success')
        return redirect(url_for('view_trip_operation_report', id=id))
    return render_template('trip_operation_report_form.html', report=tor, destinations=destinations)


@app.route('/trip-operation-reports/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('trip_operation_report_delete')
def delete_trip_operation_report(id):
    tor = TripOperationReport.query.get_or_404(id)
    db.session.delete(tor)
    db.session.commit()
    flash(_('Trip Operation Report deleted.'), 'info')
    return redirect(url_for('trip_operation_reports'))


# ─────────────────────────────────────────
#  ROUTES: DEPARTMENTS
# ─────────────────────────────────────────

@app.route('/departments')
@login_required
@any_permission_required('department_view', 'department_create', 'department_edit', 'department_delete', 'department_download')
def departments():
    query = Department.query
    search = request.args.get('search', '')
    if search:
        query = query.filter(Department.name.contains(search) | (Department.description.contains(search)))
    dept_list = query.order_by(Department.name).all()
    return render_template('departments.html', departments=dept_list, search=search)


@app.route('/departments/new', methods=['GET', 'POST'])
@login_required
@permission_required('department_create')
def new_department():
    if request.method == 'POST':
        name = (request.form.get('name') or '').strip()
        if not name:
            flash(_('Department name is required.'), 'danger')
            return render_template('department_form.html', dept=None)
        dept = Department(
            name=name,
            description=request.form.get('description'),
            status=request.form.get('status', 'Active'),
        )
        db.session.add(dept)
        db.session.commit()
        flash(_('Department "%(name)s" created successfully!', name=dept.name), 'success')
        return redirect(url_for('departments'))
    return render_template('department_form.html', dept=None)


@app.route('/departments/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('department_edit')
def edit_department(id):
    dept = Department.query.get_or_404(id)
    if request.method == 'POST':
        name = (request.form.get('name') or '').strip()
        if not name:
            flash(_('Department name is required.'), 'danger')
            return render_template('department_form.html', dept=dept)
        dept.name = name
        dept.description = request.form.get('description')
        dept.status = request.form.get('status', 'Active')
        db.session.commit()
        flash(_('Department updated successfully!'), 'success')
        return redirect(url_for('departments'))
    return render_template('department_form.html', dept=dept)


@app.route('/departments/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('department_delete')
def delete_department(id):
    dept = Department.query.get_or_404(id)
    if dept.positions.count() > 0:
        flash(_('Cannot delete department with existing positions.'), 'danger')
        return redirect(url_for('departments'))
    db.session.delete(dept)
    db.session.commit()
    flash(_('Department deleted.'), 'info')
    return redirect(url_for('departments'))


# ─────────────────────────────────────────
#  ROUTES: POSITIONS
# ─────────────────────────────────────────

@app.route('/positions')
@login_required
@any_permission_required('position_view', 'position_create', 'position_edit', 'position_delete', 'position_download')
def positions():
    query = Position.query
    search = request.args.get('search', '')
    if search:
        query = query.filter(Position.name.contains(search) | (Position.description.contains(search)))
    pos_list = query.order_by(Position.name).all()
    return render_template('positions.html', positions=pos_list, search=search)


@app.route('/positions/new', methods=['GET', 'POST'])
@login_required
@permission_required('position_create')
def new_position():
    if request.method == 'POST':
        name = (request.form.get('name') or '').strip()
        dept_id = request.form.get('department_id')
        if not name or not dept_id:
            flash(_('Position name and department are required.'), 'danger')
            return render_template('position_form.html', pos=None)
        pos = Position(
            name=name,
            department_id=int(dept_id),
            description=request.form.get('description'),
            status=request.form.get('status', 'Active'),
        )
        db.session.add(pos)
        db.session.commit()
        flash(_('Position "%(name)s" created successfully!', name=pos.name), 'success')
        return redirect(url_for('positions'))
    departments_list = Department.query.filter_by(status='Active').order_by(Department.name).all()
    return render_template('position_form.html', pos=None, departments=departments_list)


@app.route('/positions/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('position_edit')
def edit_position(id):
    pos = Position.query.get_or_404(id)
    if request.method == 'POST':
        name = (request.form.get('name') or '').strip()
        dept_id = request.form.get('department_id')
        if not name or not dept_id:
            flash(_('Position name and department are required.'), 'danger')
            return render_template('position_form.html', pos=pos)
        pos.name = name
        pos.department_id = int(dept_id)
        pos.description = request.form.get('description')
        pos.status = request.form.get('status', 'Active')
        db.session.commit()
        flash(_('Position updated successfully!'), 'success')
        return redirect(url_for('positions'))
    departments_list = Department.query.filter_by(status='Active').order_by(Department.name).all()
    return render_template('position_form.html', pos=pos, departments=departments_list)


@app.route('/positions/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('position_delete')
def delete_position(id):
    pos = Position.query.get_or_404(id)
    db.session.delete(pos)
    db.session.commit()
    flash(_('Position deleted.'), 'info')
    return redirect(url_for('positions'))



# ─────────────────────────────────────────
#  ROUTES: REPORTS
# ─────────────────────────────────────────

@app.route('/reports')
@login_required
@any_permission_required('report_view', 'report_create', 'report_edit', 'report_delete', 'report_export', 'report_print', 'report_download')
def reports():
    # Aggregate stats
    rr_by_status = {
        'Pending': RouteRequest.query.filter_by(status='Pending').count(),
        'Approved': RouteRequest.query.filter_by(status='Approved').count(),
        'Rejected': RouteRequest.query.filter_by(status='Rejected').count(),
    }
    ep_by_status = {
        'Pending': EmployeePenalty.query.filter_by(status='Pending').count(),
        'Approved': EmployeePenalty.query.filter_by(status='Approved').count(),
        'Rejected': EmployeePenalty.query.filter_by(status='Rejected').count(),
    }
    total_penalty_amount = db.session.query(db.func.sum(EmployeePenalty.penalty_amount)).scalar() or 0
    dept_penalties = db.session.query(
        EmployeePenalty.department,
        db.func.count(EmployeePenalty.id),
        db.func.sum(EmployeePenalty.penalty_amount)
    ).group_by(EmployeePenalty.department).all()

    tor_by_status = {
        'Departed': TripOperationReport.query.filter_by(vehicle_status='Departed').count(),
        'Not Departed': TripOperationReport.query.filter_by(vehicle_status='Not Departed').count(),
    }
    tor_total = TripOperationReport.query.count()
    tor_passengers = db.session.query(db.func.sum(TripOperationReport.passenger_count)).scalar() or 0

    return render_template('reports.html',
        rr_by_status=rr_by_status,
        ep_by_status=ep_by_status,
        total_penalty_amount=total_penalty_amount,
        dept_penalties=dept_penalties,
        tor_by_status=tor_by_status,
        tor_total=tor_total,
        tor_passengers=tor_passengers,
    )


@app.route('/reports/export/requests')
@login_required
@any_permission_required('route_request_view', 'route_request_download')
def export_requests_excel():
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Route Requests"
    headers = ['Request ID', 'Date', 'Requester', 'From', 'To', 'Branch', 'Company',
               'Transport', 'Price', 'Departure', 'Arrival', 'Status']
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="1a3c5e")
    for col, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col, value=h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center')
        ws.column_dimensions[cell.column_letter].width = 18

    for rr in RouteRequest.query.order_by(RouteRequest.created_date.desc()).all():
        ws.append([rr.request_id, str(rr.request_date), rr.requester_name,
                   rr.destination_from, rr.destination_to, rr.branch_location,
                   rr.company, rr.transportation, rr.price,
                   rr.departure_time, rr.arrival_time, rr.status])

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return send_excel(buf, f"route_requests_{date.today()}.xlsx")


@app.route('/reports/export/penalties')
@login_required
@any_permission_required('penalty_view', 'penalty_download')
def export_penalties_excel():
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Employee Penalties"
    headers = ['Penalty ID', 'Employee ID', 'Employee Name', 'Department',
               'Position', 'Violation Type', 'Amount ($)', 'Date', 'Status']
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="1a3c5e")
    for col, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col, value=h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center')
        ws.column_dimensions[cell.column_letter].width = 20

    for ep in EmployeePenalty.query.order_by(EmployeePenalty.created_date.desc()).all():
        ws.append([ep.penalty_id, ep.employee_id, ep.employee_name,
                   ep.department, ep.position, ep.violation_type,
                   ep.penalty_amount, str(ep.incident_date), ep.status])

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return send_excel(buf, f"penalties_{date.today()}.xlsx")


def _export_pdf_report(title, headers, rows, filename):
    pdf = FPDF()
    pdf.add_font('Khmer', '', r'C:\Windows\Fonts\KhmerOS_sys.ttf', uni=True)
    pdf.add_font('Khmer', 'B', r'C:\Windows\Fonts\KhmerOS_sys.ttf', uni=True)
    pdf.add_page()
    pdf.set_font('Khmer', 'B', 14)
    pdf.cell(0, 12, title, new_x='LMARGIN', new_y='NEXT', align='C')
    pdf.ln(2)
    pdf.set_font('Khmer', '', 7)
    pdf.cell(0, 6, f"Generated: {datetime.now().strftime('%d %b %Y %H:%M')}", new_x='LMARGIN', new_y='NEXT', align='R')
    pdf.ln(4)

    col_w = max(10, min(45, 270 // len(headers)))
    page_w = 270
    used_w = col_w * len(headers)
    if used_w > page_w:
        col_w = max(10, page_w // len(headers))

    pdf.set_font('Khmer', 'B', 6)
    pdf.set_fill_color(26, 60, 94)
    pdf.set_text_color(255, 255, 255)
    for h in headers:
        pdf.cell(col_w, 8, h, border=1, fill=True, align='C')
    pdf.ln()

    pdf.set_font('Khmer', '', 6)
    pdf.set_text_color(50, 50, 50)
    for row in rows:
        for i, cell in enumerate(row):
            align = 'L' if i == 0 else 'C'
            txt = str(cell or '')[:int(col_w * 1.5)]
            pdf.cell(col_w, 6, txt, border=1, align=align)
        pdf.ln()

    buf = io.BytesIO()
    pdf.output(buf)
    buf.seek(0)
    return buf


@app.route('/reports/export/requests/pdf')
@login_required
@any_permission_required('route_request_view', 'route_request_download')
def export_requests_pdf():
    headers = ['Req ID', 'Date', 'Requester', 'From', 'To', 'Branch', 'Company',
               'Transport', 'Road', 'Price', 'Depart', 'Arrive', 'Start', 'End', 'Status']
    rows = []
    for rr in RouteRequest.query.order_by(RouteRequest.created_date.desc()).all():
        rows.append([
            rr.request_id, str(rr.request_date), rr.requester_name,
            rr.destination_from, rr.destination_to, rr.branch_location or '',
            rr.company or '', rr.transportation or '', rr.national_road or '',
            f"${rr.price:.2f}", rr.departure_time or '', rr.arrival_time or '',
            str(rr.start_date or ''), str(rr.end_date or ''), rr.status
        ])
    buf = _export_pdf_report('Route Requests Report', headers, rows, f'route_requests_{date.today()}.pdf')
    return send_pdf(buf, f"route_requests_{date.today()}.pdf")


@app.route('/reports/export/penalties/pdf')
@login_required
@any_permission_required('penalty_view', 'penalty_download')
def export_penalties_pdf():
    headers = ['Penalty ID', 'Emp ID', 'Employee Name', 'Department', 'Position',
               'Violation Type', 'Amount ($)', 'Date', 'Status']
    rows = []
    for ep in EmployeePenalty.query.order_by(EmployeePenalty.created_date.desc()).all():
        rows.append([
            ep.penalty_id, ep.employee_id, ep.employee_name,
            ep.department or '', ep.position or '', ep.violation_type,
            f"${ep.penalty_amount:.2f}", str(ep.incident_date), ep.status
        ])
    buf = _export_pdf_report('Employee Penalties Report', headers, rows, f'penalties_{date.today()}.pdf')
    return send_pdf(buf, f"penalties_{date.today()}.pdf")


@app.route('/reports/export/trip-reports')
@login_required
@any_permission_required('trip_operation_report_view', 'trip_operation_report_download')
def export_trip_reports_excel():
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Trip Operation Reports"
    headers = ['Report ID', 'Origin', 'Destination', 'Direction', 'Departure',
               'Vehicle', 'Driver Phone', 'Arrival Station', 'Depart Station',
               'Delay (min)', 'Passengers', 'Coordinator', 'Status']
    header_font = Font(bold=True, color="FFFFFF")
    header_fill = PatternFill("solid", fgColor="1a3c5e")
    for col, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col, value=h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal='center')
        ws.column_dimensions[cell.column_letter].width = 18

    for r in TripOperationReport.query.order_by(TripOperationReport.created_date.desc()).all():
        ws.append([r.report_id, r.origin, r.destination, r.travel_direction,
                   r.departure_time, r.vehicle_number, r.driver_phone or '',
                   r.arrival_at_station or '', r.departure_from_station or '',
                   int(r.travel_delay_duration or 0), int(r.passenger_count),
                   r.coordinator_name or '', r.vehicle_status])

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return send_excel(buf, f"trip_reports_{date.today()}.xlsx")


@app.route('/reports/export/trip-reports/pdf')
@login_required
@any_permission_required('trip_operation_report_view', 'trip_operation_report_download')
def export_trip_reports_pdf():
    headers = ['Report ID', 'Origin', 'Destination', 'Direction', 'Departure',
               'Vehicle', 'Driver Phone', 'Arrival Stn', 'Passengers', 'Coordinator', 'Status']
    rows = []
    for r in TripOperationReport.query.order_by(TripOperationReport.created_date.desc()).all():
        rows.append([
            r.report_id, r.origin, r.destination, r.travel_direction or '',
            r.departure_time or '', r.vehicle_number, r.driver_phone or '',
            r.arrival_at_station or '', int(r.passenger_count),
            r.coordinator_name or '', r.vehicle_status
        ])
    buf = _export_pdf_report('Trip Operation Reports', headers, rows, f'trip_reports_{date.today()}.pdf')
    return send_pdf(buf, f"trip_reports_{date.today()}.pdf")


# ─────────────────────────────────────────
#  DYNAMIC CONFIGURATION ENGINE
# ─────────────────────────────────────────

class DynamicEngine:
    """Generic dynamic CRUD engine driven by ConfigModule/ConfigField metadata."""

    @staticmethod
    def get_module(module_key):
        m = ConfigModule.query.filter_by(module_key=module_key, is_active=True).first()
        if not m:
            flash(_('Module "%(key)s" not found.', key=module_key), 'danger')
        return m

    @staticmethod
    def get_fields(module_id, creatable_only=False, editable_only=False):
        q = ConfigField.query.filter_by(module_id=module_id)
        if creatable_only:
            q = q.filter_by(is_creatable=True)
        if editable_only:
            q = q.filter_by(is_editable=True)
        return q.order_by(ConfigField.display_order).all()

    @staticmethod
    def validate(data, fields, record_id=None, module_id=None):
        errors = {}
        for fld in fields:
            val = data.get(fld.field_name, '')

            # Required
            if fld.is_required and (val is None or str(val).strip() == ''):
                errors[fld.field_name] = _('%(label)s is required.', label=fld.field_label)
                continue

            if val is None or str(val).strip() == '':
                continue

            val_str = str(val).strip()

            # Min length
            if fld.min_length and len(val_str) < fld.min_length:
                errors[fld.field_name] = _('%(label)s must be at least %(len)d characters.', label=fld.field_label, len=fld.min_length)

            # Max length
            if fld.max_length and len(val_str) > fld.max_length:
                errors[fld.field_name] = _('%(label)s must not exceed %(len)d characters.', label=fld.field_label, len=fld.max_length)

            # Regex
            if fld.regex_pattern and not re.match(fld.regex_pattern, val_str):
                errors[fld.field_name] = fld.regex_message or _('%(label)s format is invalid.', label=fld.field_label)

            # Unique
            if fld.is_unique and module_id:
                existing = DynamicRecord.query.filter(
                    DynamicRecord.module_id == module_id,
                    DynamicRecord.data[fld.field_name].as_string() == val_str,
                    DynamicRecord.is_active == True
                )
                if record_id:
                    existing = existing.filter(DynamicRecord.id != record_id)
                if existing.first():
                    errors[fld.field_name] = _('%(label)s must be unique.', label=fld.field_label)

            # Extra validation rules from config_validation table
            for rule in fld.validations:
                if rule.validation_type == 'custom' and rule.validation_value:
                    try:
                        if not eval(rule.validation_value, {'val': val_str, 'data': data}):
                            errors[fld.field_name] = rule.error_message or _('%(label)s validation failed.', label=fld.field_label)
                    except:
                        pass

            # Number type check
            if fld.field_type == 'number' and val_str:
                try:
                    float(val_str)
                except ValueError:
                    errors[fld.field_name] = _('%(label)s must be a valid number.', label=fld.field_label)

        return errors

    @staticmethod
    def get_dropdown_options(field, parent_value=None):
        """Returns list of (value, label) tuples for a dropdown field."""
        if field.option_source == 'static':
            return [(o.option_value, o.option_label)
                    for o in ConfigDropdownOption.query.filter_by(field_id=field.id, is_active=True)
                    .order_by(ConfigDropdownOption.sort_order).all()]

        elif field.option_source == 'module' and field.option_module_id:
            target_module = ConfigModule.query.get(field.option_module_id)
            if not target_module:
                return []
            q = DynamicRecord.query.filter_by(module_id=field.option_module_id, is_active=True)
            if field.option_parent_field and parent_value:
                q = q.filter(DynamicRecord.data[field.option_parent_field].as_string() == str(parent_value))
            records = q.order_by(DynamicRecord.created_date.desc()).all()
            result = []
            for r in records:
                label = r.data.get('name', r.data.get('code', f'Record #{r.id}'))
                result.append((str(r.id), label))
            return result

        return []

    @staticmethod
    def resolve_field_value(field, value):
        """Resolve a foreign key ID to a display label."""
        if field.option_source == 'module' and field.option_module_id and value:
            rec = DynamicRecord.query.get(int(value))
            if rec:
                return rec.data.get('name', rec.data.get('code', f'#{value}'))
        return value

    @staticmethod
    def create(module_key, data):
        module = DynamicEngine.get_module(module_key)
        if not module:
            return None, _('Module not found.')
        fields = DynamicEngine.get_fields(module.id, creatable_only=True)
        errors = DynamicEngine.validate(data, fields, module_id=module.id)
        if errors:
            return None, errors
        record = DynamicRecord(
            module_id=module.id,
            data=data,
            is_active=True,
            created_by=current_user.id
        )
        db.session.add(record)
        db.session.commit()
        return record, None

    @staticmethod
    def update(record_id, data):
        record = DynamicRecord.query.get_or_404(record_id)
        fields = DynamicEngine.get_fields(record.module_id, editable_only=True)
        errors = DynamicEngine.validate(data, fields, record_id=record_id, module_id=record.module_id)
        if errors:
            return None, errors
        record.data = data
        record.updated_by = current_user.id
        record.updated_date = datetime.now(timezone.utc).replace(tzinfo=None)
        db.session.commit()
        return record, None

    @staticmethod
    def delete(record_id, soft=True):
        record = DynamicRecord.query.get_or_404(record_id)
        if soft:
            record.is_active = False
            record.deleted_date = datetime.now(timezone.utc).replace(tzinfo=None)
        else:
            db.session.delete(record)
        db.session.commit()

    @staticmethod
    def list_records(module_key, search=None, sort_by=None, sort_dir='desc', page=1, per_page=20):
        module = DynamicEngine.get_module(module_key)
        if not module:
            return None, 0
        q = DynamicRecord.query.filter_by(module_id=module.id, is_active=True)
        fields = DynamicEngine.get_fields(module.id)

        # Search
        if search:
            searchable = [f for f in fields if f.is_searchable]
            if searchable:
                filters = []
                for f in searchable:
                    filters.append(DynamicRecord.data[f.field_name].as_string().contains(search))
                from sqlalchemy import or_
                q = q.filter(or_(*filters))

        # Sort
        if sort_by:
            try:
                col = DynamicRecord.data[sort_by].as_string()
                q = q.order_by(col.desc() if sort_dir == 'desc' else col)
            except:
                q = q.order_by(DynamicRecord.created_date.desc())
        else:
            q = q.order_by(DynamicRecord.created_date.desc())

        total = q.count()
        records = q.offset((page - 1) * per_page).limit(per_page).all()
        return records, total


@app.context_processor
def inject_dynamic_engine():
    return {'DynamicEngine': DynamicEngine}


# ─────────────────────────────────────────
#  ROUTES: DYNAMIC SETTINGS (Configuration Driven)
# ─────────────────────────────────────────

@app.route('/dynamic-settings')
@login_required
@any_permission_required('system_settings_view', 'system_settings_edit', 'system_settings_update')
def dynamic_settings():
    modules = ConfigModule.query.filter_by(is_active=True).order_by(ConfigModule.sort_order).all()
    return render_template('dynamic_settings.html', modules=modules)


@app.route('/dynamic-settings/<module_key>')
@login_required
@any_permission_required('system_settings_view', 'system_settings_edit', 'system_settings_update')
def dynamic_list(module_key):
    module = DynamicEngine.get_module(module_key)
    if not module:
        return redirect(url_for('dynamic_settings'))

    fields = DynamicEngine.get_fields(module.id)
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '')
    sort_by = request.args.get('sort_by', '')
    sort_dir = request.args.get('sort_dir', 'desc')

    records, total = DynamicEngine.list_records(
        module_key, search=search, sort_by=sort_by, sort_dir=sort_dir, page=page, per_page=15
    )

    # Resolve FK fields for display
    for rec in records:
        for fld in fields:
            val = rec.data.get(fld.field_name)
            rec.data[f'_{fld.field_name}_display'] = DynamicEngine.resolve_field_value(fld, val)

    modules = ConfigModule.query.filter_by(is_active=True).order_by(ConfigModule.sort_order).all()
    return render_template('dynamic_list.html',
        module=module, fields=fields, records=records,
        total=total, page=page, per_page=15,
        search=search, sort_by=sort_by, sort_dir=sort_dir,
        modules=modules
    )


@app.route('/dynamic-settings/<module_key>/create', methods=['GET', 'POST'])
@login_required
@permission_required('system_settings_edit')
def dynamic_create(module_key):
    module = DynamicEngine.get_module(module_key)
    if not module:
        return redirect(url_for('dynamic_settings'))

    fields = DynamicEngine.get_fields(module.id, creatable_only=True)
    modules = ConfigModule.query.filter_by(is_active=True).order_by(ConfigModule.sort_order).all()

    if request.method == 'POST':
        data = {}
        for fld in fields:
            val = request.form.get(fld.field_name, '').strip()
            if fld.field_type == 'number':
                val = float(val) if val else 0
            elif fld.field_type == 'boolean' or fld.field_type == 'checkbox':
                val = fld.field_name in request.form
            data[fld.field_name] = val

        record, error = DynamicEngine.create(module_key, data)
        if error:
            if isinstance(error, dict):
                return render_template('dynamic_form.html', module=module, fields=fields,
                    modules=modules, data=data, errors=error, form_mode='create')
            flash(str(error), 'danger')
        else:
            flash(_('%(name)s created successfully.', name=module.module_name), 'success')
            return redirect(url_for('dynamic_list', module_key=module_key))

        return render_template('dynamic_form.html', module=module, fields=fields,
            modules=modules, data=data, form_mode='create')

    return render_template('dynamic_form.html', module=module, fields=fields,
        modules=modules, data={}, form_mode='create')


@app.route('/dynamic-settings/<module_key>/<int:id>')
@login_required
@permission_required('system_settings_view')
def dynamic_view(module_key, id):
    module = DynamicEngine.get_module(module_key)
    if not module:
        return redirect(url_for('dynamic_settings'))
    record = DynamicRecord.query.get_or_404(id)
    fields = DynamicEngine.get_fields(module.id)
    modules = ConfigModule.query.filter_by(is_active=True).order_by(ConfigModule.sort_order).all()
    for fld in fields:
        val = record.data.get(fld.field_name)
        record.data[f'_{fld.field_name}_display'] = DynamicEngine.resolve_field_value(fld, val)
    return render_template('dynamic_view.html', module=module, fields=fields,
        modules=modules, record=record)


@app.route('/dynamic-settings/<module_key>/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('system_settings_edit')
def dynamic_edit(module_key, id):
    module = DynamicEngine.get_module(module_key)
    if not module:
        return redirect(url_for('dynamic_settings'))

    record = DynamicRecord.query.get_or_404(id)
    fields = DynamicEngine.get_fields(module.id, editable_only=True)
    modules = ConfigModule.query.filter_by(is_active=True).order_by(ConfigModule.sort_order).all()

    if request.method == 'POST':
        data = {}
        for fld in fields:
            val = request.form.get(fld.field_name, '').strip()
            if fld.field_type == 'number':
                val = float(val) if val else 0
            elif fld.field_type == 'boolean' or fld.field_type == 'checkbox':
                val = fld.field_name in request.form
            data[fld.field_name] = val

        updated, error = DynamicEngine.update(id, data)
        if error:
            if isinstance(error, dict):
                return render_template('dynamic_form.html', module=module, fields=fields,
                    modules=modules, data=data, errors=error, form_mode='edit', record=record)
            flash(str(error), 'danger')
        else:
            flash(_('%(name)s updated successfully.', name=module.module_name), 'success')
            return redirect(url_for('dynamic_list', module_key=module_key))

    return render_template('dynamic_form.html', module=module, fields=fields,
        modules=modules, data=record.data, form_mode='edit', record=record)


@app.route('/dynamic-settings/<module_key>/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('system_settings_edit')
def dynamic_delete(module_key, id):
    DynamicEngine.delete(id, soft=True)
    flash(_('Record deleted.'), 'info')
    return redirect(url_for('dynamic_list', module_key=module_key))


@app.route('/dynamic-settings/<module_key>/<int:id>/toggle', methods=['POST'])
@login_required
@permission_required('system_settings_edit')
def dynamic_toggle(module_key, id):
    record = DynamicRecord.query.get_or_404(id)
    record.is_active = not record.is_active
    db.session.commit()
    flash(_('Record activated.') if record.is_active else _('Record deactivated.'), 'info')
    return redirect(url_for('dynamic_list', module_key=module_key))


# API Endpoints for dynamic modules
@app.route('/api/dynamic/<module_key>', methods=['GET'])
@login_required
def dynamic_api_list(module_key):
    search = request.args.get('search', '')
    records, total = DynamicEngine.list_records(module_key, search=search)
    data = [{'id': r.id, **r.data} for r in (records or [])]
    return jsonify({'total': total, 'data': data})


@app.route('/api/dynamic/<module_key>/<int:id>', methods=['GET'])
@login_required
def dynamic_api_get(module_key, id):
    record = DynamicRecord.query.get_or_404(id)
    return jsonify({'id': record.id, **record.data})


@app.route('/api/dynamic/dropdown/<int:field_id>')
@login_required
def dynamic_api_dropdown(field_id):
    field = ConfigField.query.get_or_404(field_id)
    parent_value = request.args.get('parent')
    options = DynamicEngine.get_dropdown_options(field, parent_value)
    return jsonify([{'value': v, 'label': l} for v, l in options])


# ─────────────────────────────────────────
#  ROUTES: USER MANAGEMENT
# ─────────────────────────────────────────

@app.route('/users')
@login_required
@any_permission_required('user_view', 'user_create', 'user_edit', 'user_delete', 'user_assign_roles', 'user_reset_password', 'user_activate', 'user_deactivate', 'user_download')
def users():
    users_list = User.query.order_by(User.created_date.desc()).all()
    return render_template('users.html', users=users_list)


@app.route('/roles')
@login_required
@any_permission_required('role_view', 'role_create', 'role_edit', 'role_delete', 'role_assign_permissions', 'role_download')
def list_roles():
    roles_list = Role.query.order_by(Role.created_date.desc()).all()
    return render_template('roles.html', roles=roles_list)


@app.route('/roles/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('role_edit')
def edit_role(id):
    role = Role.query.get_or_404(id)
    if request.method == 'POST':
        role_name = request.form.get('role_name', '').strip()
        role_label = request.form.get('role_label', '').strip()
        permissions = request.form.getlist('permissions')
        if not permissions:
            permissions_raw = request.form.get('permissions')
            if permissions_raw:
                try:
                    permissions = json.loads(permissions_raw)
                except (json.JSONDecodeError, TypeError):
                    permissions = []

        if not role_name:
            flash(_('Role name is required.'), 'danger')
            return render_template('create_role.html', role=role)

        existing = Role.query.filter_by(name=role_name).first()
        if existing and existing.id != role.id:
            flash(_('A role with that name already exists.'), 'danger')
            return render_template('create_role.html', role=role)

        role.name = role_name
        role.label = role_label or role_name
        role.permissions = permissions
        db.session.commit()

        flash(_('Role "%(name)s" updated.', name=role_name), 'success')
        return redirect(url_for('list_roles'))

    return render_template('create_role.html', role=role)


@app.route('/roles/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('role_delete')
def delete_role(id):
    role = Role.query.get_or_404(id)
    db.session.delete(role)
    db.session.commit()
    flash(_('Role "%(name)s" deleted.', name=role.name), 'info')
    return redirect(url_for('list_roles'))


@app.route('/roles/new', methods=['GET', 'POST'])
@login_required
@permission_required('role_create')
def new_role():
    if request.method == 'POST':
        role_name = request.form.get('role_name', '').strip()
        role_label = request.form.get('role_label', '').strip()
        permissions = request.form.getlist('permissions')
        if not permissions:
            permissions_raw = request.form.get('permissions')
            if permissions_raw:
                try:
                    permissions = json.loads(permissions_raw)
                except (json.JSONDecodeError, TypeError):
                    permissions = []

        if not role_name:
            flash(_('Role name is required.'), 'danger')
            return render_template('create_role.html')

        if Role.query.filter_by(name=role_name).first():
            flash(_('A role with that name already exists.'), 'danger')
            return render_template('create_role.html')

        new_role = Role(name=role_name, label=role_label or role_name, permissions=permissions)
        db.session.add(new_role)
        db.session.commit()

        flash(_('Role "%(name)s" created with %(count)d permissions.', name=role_name, count=len(permissions)), 'success')
        return redirect(url_for('list_roles'))

    return render_template('create_role.html')


@app.route('/users/new', methods=['GET', 'POST'])
@login_required
@permission_required('user_create')
def new_user():
    if request.method == 'POST':
        u = User()
        u.full_name = request.form.get('full_name')
        u.username = request.form.get('username')
        role_id = _int_or_none(request.form.get('role_id'))
        if role_id:
            role_obj = Role.query.get(role_id)
            if role_obj:
                u.role_id = role_obj.id
                u.role = role_obj.name
            else:
                flash(_('Selected role not found.'), 'danger')
                roles = Role.query.order_by(Role.name).all()
                return render_template('user_form.html', user=None, roles=roles)
        else:
            u.role = request.form.get('role', 'admin')
        u.branch = request.form.get('branch')
        u.set_password(request.form.get('password'))
        if User.query.filter_by(username=u.username).first():
            flash(_('Username already exists.'), 'danger')
            roles = Role.query.order_by(Role.name).all()
            return render_template('user_form.html', user=None, roles=roles)
        db.session.add(u)
        db.session.commit()
        flash(_('User %(name)s created!', name=u.username), 'success')
        return redirect(url_for('users'))
    roles = Role.query.order_by(Role.name).all()
    return render_template('user_form.html', user=None, roles=roles)


@app.route('/users/<int:id>/edit', methods=['GET', 'POST'])
@login_required
@permission_required('user_edit')
def edit_user(id):
    u = User.query.get_or_404(id)
    if request.method == 'POST':
        u.full_name = request.form.get('full_name')
        role_id = _int_or_none(request.form.get('role_id'))
        if role_id:
            role_obj = Role.query.get(role_id)
            if role_obj:
                u.role_id = role_obj.id
                u.role = role_obj.name
        else:
            u.role = request.form.get('role', u.role)
            u.role_id = None
        u.branch = request.form.get('branch')
        u.is_active = 'is_active' in request.form
        new_pass = request.form.get('password')
        if new_pass:
            u.set_password(new_pass)
        db.session.commit()
        flash(_('User updated!'), 'success')
        return redirect(url_for('users'))
    roles = Role.query.order_by(Role.name).all()
    return render_template('user_form.html', user=u, roles=roles)


@app.route('/users/<int:id>/delete', methods=['POST'])
@login_required
@permission_required('user_delete')
def delete_user(id):
    u = User.query.get_or_404(id)
    if u.id == current_user.id:
        flash(_('Cannot delete yourself.'), 'danger')
        return redirect(url_for('users'))
    db.session.delete(u)
    db.session.commit()
    flash(_('User deleted.'), 'info')
    return redirect(url_for('users'))


# ─────────────────────────────────────────
#  API: Roles
# ─────────────────────────────────────────

@app.route('/api/roles')
@login_required
def api_roles():
    roles = Role.query.order_by(Role.name).all()
    return jsonify([{
        'id': r.id,
        'name': r.name,
        'label': r.label or r.name,
        'permissions': r.get_permissions()
    } for r in roles])


# ─────────────────────────────────────────
#  API: Chart data
# ─────────────────────────────────────────

@app.route('/api/chart-data')
@login_required
def chart_data():
    months = {}
    for key, count in db.session.query(
        db.func.strftime('%m', RouteRequest.created_date),
        db.func.count(RouteRequest.id)
    ).group_by(db.func.strftime('%m', RouteRequest.created_date)).all():
        month_num = int(key)
        months[month_num] = {'requests': count, 'penalties': 0}
    for key, count in db.session.query(
        db.func.strftime('%m', EmployeePenalty.created_date),
        db.func.count(EmployeePenalty.id)
    ).group_by(db.func.strftime('%m', EmployeePenalty.created_date)).all():
        month_num = int(key)
        if month_num not in months:
            months[month_num] = {'requests': 0, 'penalties': 0}
        months[month_num]['penalties'] = count
    result = {}
    for k, v in months.items():
        result[calendar.month_abbr[k]] = v
    return jsonify(result)


# ─────────────────────────────────────────
#  INIT DB
# ─────────────────────────────────────────

def init_db():
    with app.app_context():
        db.create_all()

        # ── Migrate users table for role_id FK ──
        _add_column_if_not_exists('users', 'role_id', 'INTEGER')

        # ── Migrate TripOperationReport for new columns ──
        _add_column_if_not_exists('trip_operation_reports', 'origin', 'VARCHAR(200)')
        _add_column_if_not_exists('trip_operation_reports', 'destination', 'VARCHAR(200)')

        # ── Seed Dynamic Configuration Modules ──
        if not ConfigModule.query.first():
            modules_data = [
                ('company', 'Company', 'fa-building', 1),
                ('branch', 'Branch', 'fa-location-dot', 2),
                ('agency', 'Agency', 'fa-handshake', 3),
                ('agent_group', 'Agent Group', 'fa-users-gear', 4),
                ('destination', 'Destination', 'fa-map-pin', 5),
                ('destination_group', 'Destination Group', 'fa-layer-group', 6),
                ('transportation_type', 'Transportation Type', 'fa-truck', 7),
                ('route', 'Route', 'fa-route', 8),
                ('boarding_point', 'Boarding Point', 'fa-sign-in-alt', 9),
                ('drop_off_point', 'Drop Off Point', 'fa-sign-out-alt', 10),
                ('bus', 'Bus', 'fa-bus', 11),
                ('bus_type', 'Bus Type', 'fa-bus-simple', 12),
                ('amenity', 'Amenity', 'fa-wifi', 13),
            ]
            for key, name, icon, order in modules_data:
                m = ConfigModule(module_key=key, module_name=name, module_icon=icon, sort_order=order)
                db.session.add(m)
            db.session.flush()

            # ── Seed Fields for each module ──
            field_sets = {
                'company': [
                    ('name', 'Company Name', 'text', True, True, True),
                    ('code', 'Company Code', 'text', False, False, True),
                    ('phone', 'Phone', 'tel', False, False, True),
                    ('email', 'Email', 'email', False, False, False),
                    ('address', 'Address', 'textarea', False, False, False),
                ],
                'branch': [
                    ('name', 'Branch Name', 'text', True, True, True),
                    ('code', 'Branch Code', 'text', False, False, True),
                    ('phone', 'Phone', 'tel', False, False, True),
                    ('address', 'Address', 'textarea', False, False, False),
                ],
                'agency': [
                    ('name', 'Agency Name', 'text', True, True, True),
                    ('code', 'Agency Code', 'text', True, True, True),
                    ('contact_person', 'Contact Person', 'text', False, False, True),
                    ('phone', 'Phone', 'tel', False, False, True),
                    ('email', 'Email', 'email', False, False, False),
                    ('commission_rate', 'Commission Rate (%)', 'number', False, False, False),
                ],
                'agent_group': [
                    ('name', 'Group Name', 'text', True, True, True),
                    ('description', 'Description', 'textarea', False, False, False),
                    ('discount_rate', 'Discount Rate (%)', 'number', False, False, False),
                ],
                'destination': [
                    ('name', 'Destination Name', 'text', True, True, True),
                    ('code', 'Code', 'text', False, True, True),
                    ('description', 'Description', 'textarea', False, False, False),
                ],
                'destination_group': [
                    ('name', 'Group Name', 'text', True, True, True),
                    ('description', 'Description', 'textarea', False, False, False),
                ],
                'transportation_type': [
                    ('name', 'Transport Type', 'text', True, True, True),
                    ('capacity', 'Default Capacity', 'number', False, False, False),
                ],
                'route': [
                    ('name', 'Route Name', 'text', False, False, True),
                    ('from_destination_id', 'From Destination', 'dropdown', True, False, True),
                    ('to_destination_id', 'To Destination', 'dropdown', True, False, True),
                    ('distance_km', 'Distance (km)', 'number', False, False, False),
                    ('estimated_hours', 'Est. Hours', 'number', False, False, False),
                ],
                'boarding_point': [
                    ('name', 'Point Name', 'text', True, False, True),
                    ('destination_id', 'Destination', 'dropdown', True, False, True),
                    ('address', 'Address', 'textarea', False, False, False),
                ],
                'drop_off_point': [
                    ('name', 'Point Name', 'text', True, False, True),
                    ('destination_id', 'Destination', 'dropdown', True, False, True),
                    ('address', 'Address', 'textarea', False, False, False),
                ],
                'bus': [
                    ('bus_number', 'Bus Number', 'text', True, True, True),
                    ('bus_type_id', 'Bus Type', 'dropdown', True, False, True),
                    ('capacity', 'Capacity', 'number', True, False, True),
                    ('plate_number', 'Plate Number', 'text', True, False, True),
                    ('amenities', 'Amenities', 'textarea', False, False, False),
                ],
                'bus_type': [
                    ('name', 'Bus Type Name', 'text', True, True, True),
                    ('capacity', 'Default Capacity', 'number', True, False, True),
                    ('description', 'Description', 'textarea', False, False, False),
                ],
                'amenity': [
                    ('name', 'Amenity Name', 'text', True, True, True),
                    ('icon', 'Icon Class', 'text', False, False, True),
                    ('description', 'Description', 'textarea', False, False, False),
                ],
            }
            for key, name, icon, order in modules_data:
                module = ConfigModule.query.filter_by(module_key=key).first()
                if module and key in field_sets:
                    for i, (fname, flabel, ftype, req, unique, listable) in enumerate(field_sets[key]):
                        # Set dropdown source for FK fields
                        opt_source = None
                        opt_module_id = None
                        if fname in ('from_destination_id', 'to_destination_id', 'destination_id'):
                            opt_source = 'module'
                            dest_mod = ConfigModule.query.filter_by(module_key='destination').first()
                            opt_module_id = dest_mod.id if dest_mod else None
                        elif fname == 'bus_type_id':
                            opt_source = 'module'
                            bt_mod = ConfigModule.query.filter_by(module_key='bus_type').first()
                            opt_module_id = bt_mod.id if bt_mod else None

                        f = ConfigField(
                            module_id=module.id,
                            field_name=fname,
                            field_label=flabel,
                            field_type=ftype,
                            is_required=req,
                            is_unique=unique,
                            is_listable=listable,
                            is_searchable=req or unique,
                            display_order=i,
                            option_source=opt_source,
                            option_module_id=opt_module_id,
                        )
                        db.session.add(f)

            # Seed sample data for core modules
            dest_module = ConfigModule.query.filter_by(module_key='destination').first()
            dest_data = ['Phnom Penh', 'Siem Reap', 'Battambang', 'Kampot', 'Kampong Cham', 'Sihanoukville', 'Takeo', 'Kandal']
            for name in dest_data:
                rec = DynamicRecord(module_id=dest_module.id, data={'name': name}, is_active=True)
                db.session.add(rec)

            transport_module = ConfigModule.query.filter_by(module_key='transportation_type').first()
            for name in ['Bus', 'Van', 'Car', 'Minibus', 'Motorcycle', 'Truck']:
                rec = DynamicRecord(module_id=transport_module.id, data={'name': name}, is_active=True)
                db.session.add(rec)

            bus_type_module = ConfigModule.query.filter_by(module_key='bus_type').first()
            for name, cap in [('Standard', 40), ('VIP', 30), ('Mini', 16), ('Luxury', 20)]:
                rec = DynamicRecord(module_id=bus_type_module.id, data={'name': name, 'capacity': cap}, is_active=True)
                db.session.add(rec)

            amenity_module = ConfigModule.query.filter_by(module_key='amenity').first()
            for item, icon in [('WiFi', 'fa-wifi'), ('AC', 'fa-snowflake'), ('TV', 'fa-tv'), ('Toilet', 'fa-toilet'), ('Water', 'fa-bottle-water'), ('Charger', 'fa-plug')]:
                rec = DynamicRecord(module_id=amenity_module.id, data={'name': item, 'icon': icon}, is_active=True)
                db.session.add(rec)

            db.session.commit()
            print("Dynamic configuration system initialized.")

        # ── Seed Default Roles ──
        if not Role.query.first():
            all_permissions = [
                'dashboard_view', 'dashboard_edit', 'dashboard_download',
                'route_request_view', 'route_request_create', 'route_request_edit', 'route_request_delete',
                'route_request_approve', 'route_request_reject', 'route_request_download',
                'penalty_view', 'penalty_create', 'penalty_edit', 'penalty_delete', 'penalty_download',
                'trip_operation_report_view', 'trip_operation_report_create', 'trip_operation_report_edit',
                'trip_operation_report_delete', 'trip_operation_report_download',
                'report_view', 'report_create', 'report_edit', 'report_delete',
                'report_export', 'report_print', 'report_download',
                'system_settings_view', 'system_settings_edit', 'system_settings_update',
                'department_view', 'department_create', 'department_edit', 'department_delete', 'department_download',
                'position_view', 'position_create', 'position_edit', 'position_delete', 'position_download',
                'role_view', 'role_create', 'role_edit', 'role_delete', 'role_assign_permissions', 'role_download',
                'user_view', 'user_create', 'user_edit', 'user_delete',
                'user_assign_roles', 'user_reset_password', 'user_activate', 'user_deactivate', 'user_download',
            ]
            it_staff_permissions = [
                'dashboard_view',
                'route_request_view',
                'penalty_view',
                'trip_operation_report_view', 'trip_operation_report_create',
                'report_view',
                'department_view',
                'position_view',
                'role_view',
                'user_view',
            ]
            branch_manager_permissions = [
                'dashboard_view', 'dashboard_download',
                'route_request_view', 'route_request_create', 'route_request_edit', 'route_request_download',
                'penalty_view',
                'trip_operation_report_view', 'trip_operation_report_create', 'trip_operation_report_edit',
                'report_view',
            ]
            regional_manager_permissions = [
                'dashboard_view',
                'route_request_view', 'route_request_approve', 'route_request_reject',
                'penalty_view',
                'trip_operation_report_view',
                'report_view', 'report_export', 'report_print', 'report_download',
            ]
            hr_manager_permissions = [
                'dashboard_view',
                'penalty_view', 'penalty_create', 'penalty_edit', 'penalty_download',
                'trip_operation_report_view',
                'report_view',
                'department_view', 'department_create', 'department_edit',
                'position_view', 'position_create', 'position_edit',
                'user_view',
            ]
            role_perms = {
                'admin': all_permissions,
                'it_staff': it_staff_permissions,
                'branch_manager': branch_manager_permissions,
                'regional_manager': regional_manager_permissions,
                'hr_manager': hr_manager_permissions,
            }
            default_roles = [
                ('admin', 'Administrator'),
                ('it_staff', 'IT Staff'),
                ('branch_manager', 'Branch Manager'),
                ('regional_manager', 'Regional Manager'),
                ('hr_manager', 'HR Manager'),
            ]
            for name, label in default_roles:
                r = Role(name=name, label=label, permissions=role_perms.get(name, []))
                db.session.add(r)
            db.session.commit()

        # ── Seed Users and Demo Data ──
        if not User.query.filter_by(username='admin').first():
            admin_role = Role.query.filter_by(name='admin').first()
            admin = User(full_name='System Administrator', username='admin', role='admin', branch='HQ')
            if admin_role:
                admin.role_id = admin_role.id
            admin.set_password('admin123')
            db.session.add(admin)

            users_seed = [
                ('Branch Manager A', 'branch_mgr', 'branch_manager', 'Phnom Penh Branch'),
                ('Regional Manager', 'regional_mgr', 'regional_manager', 'Region 1'),
                ('HR Manager', 'hr_mgr', 'hr_manager', 'HQ'),
                ('IT Staff', 'it_staff', 'it_staff', 'HQ'),
            ]
            for name, uname, role_key, branch in users_seed:
                u = User(full_name=name, username=uname, role=role_key, branch=branch)
                role_obj = Role.query.filter_by(name=role_key).first()
                if role_obj:
                    u.role_id = role_obj.id
                u.set_password('pass123')
                db.session.add(u)

            # Seed sample route requests
            sample_routes = [
                ('Phnom Penh', 'Siem Reap', 'PP Branch', 'ABC Co.', 'Bus', 'NR6', 25.0, '07:00', '12:00', 'Approved'),
                ('Phnom Penh', 'Kampot', 'PP Branch', 'XYZ Co.', 'Van', 'NR3', 15.0, '08:00', '11:00', 'Pending'),
                ('Siem Reap', 'Battambang', 'SR Branch', 'DEF Co.', 'Bus', 'NR5', 10.0, '09:00', '12:00', 'Pending'),
                ('Phnom Penh', 'Kampong Cham', 'PP Branch', 'GHI Co.', 'Van', 'NR7', 12.0, '06:00', '09:00', 'Rejected'),
                ('Battambang', 'Phnom Penh', 'BTB Branch', 'ABC Co.', 'Bus', 'NR5', 18.0, '07:30', '12:30', 'Approved'),
            ]
            for i, (frm, to, branch, comp, trans, road, price, dep, arr, status) in enumerate(sample_routes, 1):
                rr = RouteRequest(
                    request_id=f"RR-2024-{i:04d}",
                    requester_name='Branch Manager A',
                    destination_from=frm, destination_to=to,
                    branch_location=branch, company=comp,
                    transportation=trans, national_road=road,
                    price=price, departure_time=dep, arrival_time=arr,
                    start_date=date(2024, 1, 1), end_date=date(2024, 12, 31),
                    status=status, remarks='Sample data'
                )
                db.session.add(rr)

            # Seed sample penalties
            sample_penalties = [
                ('EMP001', 'Sok Dara', 'IT', 'Developer', 'Late Arrival', 'Arrived 2 hours late', 50.0, 'Approved'),
                ('EMP002', 'Chea Vanna', 'HR', 'Officer', 'Absenteeism', 'Absent without notice', 100.0, 'Pending'),
                ('EMP003', 'Lim Phalla', 'Finance', 'Accountant', 'Policy Violation', 'Misuse of company resources', 75.0, 'Approved'),
                ('EMP004', 'Keo Sophea', 'Operations', 'Supervisor', 'Late Arrival', 'Consistently late', 40.0, 'Rejected'),
                ('EMP005', 'Meas Pich', 'IT', 'Analyst', 'Misconduct', 'Inappropriate behavior', 150.0, 'Pending'),
            ]
            for i, (eid, ename, dept, pos, vtype, desc, amount, status) in enumerate(sample_penalties, 1):
                ep = EmployeePenalty(
                    penalty_id=f"EP-2024-{i:04d}",
                    employee_id=eid, employee_name=ename,
                    department=dept, position=pos,
                    violation_type=vtype, description=desc,
                    penalty_amount=amount, approved_by='Admin',
                    status=status
                )
                db.session.add(ep)

            # ── Seed HR Modules (Departments, Positions) ──
            if not Department.query.first():
                depts = ['Human Resources', 'Information Technology', 'Finance', 'Operations', 'Marketing', 'Sales', 'Legal', 'Logistics']
                dept_objs = {}
                for dname in depts:
                    d = Department(name=dname, description=f'{dname} Department', status='Active')
                    db.session.add(d)
                    db.session.flush()
                    dept_objs[dname] = d.id

                positions_data = [
                    ('HR Manager', 'Human Resources'), ('HR Officer', 'Human Resources'),
                    ('IT Manager', 'Information Technology'), ('Software Engineer', 'Information Technology'),
                    ('IT Support', 'Information Technology'), ('Finance Manager', 'Finance'),
                    ('Accountant', 'Finance'), ('Operations Manager', 'Operations'),
                    ('Supervisor', 'Operations'), ('Marketing Manager', 'Marketing'),
                    ('Sales Executive', 'Sales'), ('Legal Counsel', 'Legal'),
                    ('Logistics Coordinator', 'Logistics'),
                ]
                for pname, dname in positions_data:
                    pos = Position(name=pname, department_id=dept_objs[dname], status='Active')
                    db.session.add(pos)

            db.session.commit()
            print("Database seeded with sample data.")

if __name__ == '__main__':
    init_db()
    app.run(debug=True, port=5000)
