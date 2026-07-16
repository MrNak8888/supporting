import requests
import logging
import json
from datetime import datetime

logger = logging.getLogger(__name__)
logger.setLevel(logging.WARNING)

TELEGRAM_API_SEND = 'https://api.telegram.org/bot{token}/sendMessage'


def _api_get(token, method, params=None):
    url = f'https://api.telegram.org/bot{token}/{method}'
    try:
        resp = requests.get(url, params=params, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            if data.get('ok'):
                return data.get('result'), None
            return None, data.get('description', 'Unknown error')
        return None, f'HTTP {resp.status_code}'
    except Exception as e:
        logger.error('Telegram API %s failed: %s', method, str(e))
        return None, str(e)


def get_bot_info(token):
    if not token:
        return None, 'No token provided'
    return _api_get(token, 'getMe')


def get_chat_info(token, chat_id):
    if not token or not chat_id:
        return None, 'Missing token or chat ID'
    return _api_get(token, 'getChat', {'chat_id': chat_id})


def validate_token(token):
    info, error = get_bot_info(token)
    return info is not None, info, error


def send_message(bot_token, chat_id, text, event_name='unknown', reply_markup=None):
    if not bot_token or not chat_id:
        logger.warning('[EVENT=%s] send_message skipped: bot_token=%s chat_id=%s', event_name, bool(bot_token), bool(chat_id))
        return False, 'Bot token or chat ID not configured'
    try:
        url = TELEGRAM_API_SEND.format(token=bot_token)
        payload = {
            'chat_id': chat_id,
            'text': text,
            'parse_mode': 'HTML'
        }
        if reply_markup:
            payload['reply_markup'] = reply_markup
        resp = requests.post(url, json=payload, timeout=10)
        if resp.status_code != 200:
            err_data = resp.json()
            err = err_data.get('description', 'Unknown error')
            logger.error('Telegram send failed: event=%s chat=%s error=%s', event_name, chat_id, err)
            return False, err
        return True, None
    except requests.exceptions.Timeout:
        logger.error('=== TELEGRAM TIMEOUT === Event=%s chat_id=%s', event_name, chat_id)
        return False, 'Request timed out'
    except requests.exceptions.ConnectionError as e:
        logger.error('=== TELEGRAM CONNECTION ERROR === Event=%s chat_id=%s error=%s', event_name, chat_id, str(e))
        return False, f'Connection error: {str(e)}'
    except Exception as e:
        logger.error('=== TELEGRAM EXCEPTION === Event=%s chat_id=%s error=%s', event_name, chat_id, str(e))
        return False, str(e)


def _build_inline_keyboard(base_url, record_type, record_id):
    if not base_url or not record_id:
        return None
    path = f'/{record_type}/{record_id}'
    url = f'{base_url.rstrip("/")}{path}'
    # Telegram requires HTTPS for inline keyboard button URLs
    if not url.startswith('https://'):
        return None
    return json.dumps({
        'inline_keyboard': [
            [{'text': '🔗 View Request Details', 'url': url}]
        ]
    })


SEPARATOR = '\n━━━━━━━━━━━━━━━━━━\n'


def _fmt_dt(dt):
    if not dt:
        return '—'
    return dt.strftime('%d %b %Y %I:%M %p')


def _fmt_date(d):
    if not d:
        return '—'
    return d.strftime('%d %b %Y')


def _build_transport_text(tr, event_type, event_emoji, event_title, base_url):
    lines = [
        SEPARATOR,
        f'{event_emoji} <b>{event_title}</b>',
        '',
        f'🆔 <b>ID:</b> #{tr.request_id or tr.id}',
        f'👤 <b>Requested By:</b> {tr.requester_name or "—"}',
        f'📂 <b>Branch:</b> {tr.branch_location or "—"}',
        f'📌 <b>Type:</b> {tr.request_type or "—"}',
        f'🏁 <b>Route:</b> {tr.destination_from or "—"} → {tr.destination_to or "—"}',
    ]
    if tr.transportation_type:
        lines.append(f'🚗 <b>Transport:</b> {tr.transportation_type}')
    if tr.vehicle_no:
        lines.append(f'🚙 <b>Vehicle:</b> {tr.vehicle_no}')
    if tr.active_start_date:
        lines.append(f'📅 <b>Date:</b> {_fmt_date(tr.active_start_date)}')
    if tr.departure_time:
        lines.append(f'⏰ <b>Departure:</b> {tr.departure_time}')
    if tr.price:
        lines.append(f'💰 <b>Price:</b> ${tr.price:.2f}')
    if tr.company:
        lines.append(f'🏢 <b>Company:</b> {tr.company}')
    if tr.remarks:
        lines.append(f'📄 <b>Remarks:</b> {tr.remarks}')

    status_emoji = {'Pending': '⏳', 'Approved': '✅', 'Rejected': '❌', 'Cancelled': '🚫', 'Completed': '✅'}.get(tr.status, '📌')
    lines.append(f'{SEPARATOR}{status_emoji} <b>Status:</b> {tr.status}')

    if event_type == 'new':
        if tr.created_date:
            lines.append(f'📅 <b>Created:</b> {_fmt_dt(tr.created_date)}')
    elif event_type in ('approved', 'rejected'):
        if tr.reviewer:
            lines.append(f'👨‍⚖️ <b>Reviewed By:</b> {tr.reviewer.full_name}')
        if tr.review_note:
            lines.append(f'📝 <b>Review Note:</b> {tr.review_note}')
    elif event_type == 'updated':
        if tr.updated_date:
            lines.append(f'📅 <b>Updated:</b> {_fmt_dt(tr.updated_date)}')

    # Add plain text link fallback if URL is not HTTPS (Telegram requires HTTPS for inline keyboard)
    if base_url and not base_url.startswith('https://'):
        url = f'{base_url.rstrip("/")}/transport-requests/{tr.id}'
        lines.append(f'{SEPARATOR}🔗 <a href="{url}"><b>View Request Details</b></a>')

    lines.append(SEPARATOR)
    return '\n'.join(lines)


def _build_penalty_text(ep, event_type, event_emoji, event_title, base_url):
    creator_name = ep.creator.full_name if ep.creator else (ep.employee_name or '')
    lines = [
        SEPARATOR,
        f'{event_emoji} <b>{event_title}</b>',
        '',
        f'🆔 <b>ID:</b> #{ep.penalty_id or ep.id}',
        f'👤 <b>Employee:</b> {ep.employee_name or "—"}',
        f'🆔 <b>Employee ID:</b> {ep.employee_id or "—"}',
        f'📂 <b>Department:</b> {ep.department or "—"}',
        f'📌 <b>Violation Type:</b> {ep.violation_type or "—"}',
    ]
    if ep.description:
        lines.append(f'📄 <b>Description:</b> {ep.description}')
    if ep.penalty_amount:
        lines.append(f'💰 <b>Amount:</b> ${ep.penalty_amount:.2f}')
    if ep.incident_date:
        lines.append(f'📅 <b>Incident Date:</b> {_fmt_date(ep.incident_date)}')

    status_emoji = '⏳' if ep.status == 'Pending' else ('✅' if ep.status in ('Approved', 'Completed') else '❌')
    lines.append(f'{SEPARATOR}{status_emoji} <b>Status:</b> {ep.status}')

    if event_type in ('approved', 'rejected'):
        approver_name = ep.approver.full_name if hasattr(ep, 'approver') and ep.approver else (ep.approved_by or '')
        if approver_name:
            lines.append(f'👨‍⚖️ <b>Approved By:</b> {approver_name}')
    elif event_type == 'deleted':
        lines.append(f'🗑️ <b>Deleted By:</b> {creator_name}')

    lines.append(f'👤 <b>Created By:</b> {creator_name}')
    if ep.created_date:
        lines.append(f'📅 <b>Created:</b> {_fmt_dt(ep.created_date)}')

    # Add plain text link fallback if URL is not HTTPS (Telegram requires HTTPS for inline keyboard)
    if base_url and not base_url.startswith('https://'):
        url = f'{base_url.rstrip("/")}/penalties/{ep.id}'
        lines.append(f'{SEPARATOR}🔗 <a href="{url}"><b>View Penalty Details</b></a>')

    lines.append(SEPARATOR)
    return '\n'.join(lines)


TRANSPORT_EVENT_MAP = {
    'new': ('🆕', 'NEW TRANSPORT REQUEST'),
    'approved': ('✅', 'REQUEST APPROVED'),
    'rejected': ('❌', 'REQUEST REJECTED'),
    'updated': ('📝', 'REQUEST UPDATED'),
    'cancelled': ('🚫', 'REQUEST CANCELLED'),
    'completed': ('✅', 'REQUEST COMPLETED'),
}

PENALTY_EVENT_MAP = {
    'new': ('🆕', 'NEW PENALTY RECORD'),
    'updated': ('📝', 'PENALTY UPDATED'),
    'approved': ('✅', 'PENALTY APPROVED'),
    'rejected': ('❌', 'PENALTY REJECTED'),
    'deleted': ('🗑️', 'PENALTY DELETED'),
}


def send_transport_notification(bot_token, chat_id, tr, event_type='new', base_url=None):
    emoji, title = TRANSPORT_EVENT_MAP.get(event_type, ('🔔', 'TRANSPORT REQUEST'))
    text = _build_transport_text(tr, event_type, emoji, title, base_url)
    event_name = f'transport_{event_type}'
    record_id = getattr(tr, 'request_id', None) or getattr(tr, 'id', None)
    keyboard = _build_inline_keyboard(base_url, 'transport-requests', tr.id) if base_url else None
    logger.info('Sending transport notification: event=%s record_id=%s chat_id=%s has_keyboard=%s', event_name, record_id, chat_id, bool(keyboard))
    return send_message(bot_token, chat_id, text, event_name=event_name, reply_markup=keyboard)


def send_penalty_notification(bot_token, chat_id, ep, event_type='new', base_url=None):
    emoji, title = PENALTY_EVENT_MAP.get(event_type, ('🔔', 'PENALTY NOTICE'))
    text = _build_penalty_text(ep, event_type, emoji, title, base_url)
    event_name = f'penalty_{event_type}'
    record_id = getattr(ep, 'penalty_id', None) or getattr(ep, 'id', None)
    keyboard = _build_inline_keyboard(base_url, 'penalties', ep.id) if base_url else None
    logger.info('Sending penalty notification: event=%s record_id=%s chat_id=%s has_keyboard=%s', event_name, record_id, chat_id, bool(keyboard))
    return send_message(bot_token, chat_id, text, event_name=event_name, reply_markup=keyboard)
