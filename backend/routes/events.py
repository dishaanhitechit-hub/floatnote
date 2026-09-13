from datetime import datetime, timezone, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db, scheduler
from models import Event

events_bp = Blueprint("events", __name__, url_prefix="/api/events")


def _uid():
    return int(get_jwt_identity())


@events_bp.get("/")
@jwt_required()
def list_events():
    events = Event.query.filter_by(user_id=_uid()).order_by(Event.start_time.asc()).all()
    return jsonify([e.to_dict() for e in events])


@events_bp.get("/<int:event_id>")
@jwt_required()
def get_event(event_id):
    event = Event.query.filter_by(id=event_id, user_id=_uid()).first_or_404()
    return jsonify(event.to_dict())


@events_bp.post("/")
@jwt_required()
def create_event():
    data = request.get_json(force=True)
    if not data or not data.get("title") or not data.get("start_time"):
        return jsonify({"error": "title and start_time are required"}), 400

    start_dt = datetime.fromisoformat(data["start_time"])
    end_dt   = datetime.fromisoformat(data["end_time"]) if data.get("end_time") else None

    event = Event(
        user_id             = _uid(),
        title               = data["title"],
        description         = data.get("description", ""),
        color               = data.get("color", "#B2EBF2"),
        start_time          = start_dt,
        end_time            = end_dt,
        repeat_type         = data.get("repeat_type", "once"),
        reminder_offset_min = data.get("reminder_offset_min", 15),
    )
    db.session.add(event)
    db.session.commit()
    _schedule_event_reminder(event)
    return jsonify(event.to_dict()), 201


@events_bp.put("/<int:event_id>")
@jwt_required()
def update_event(event_id):
    event = Event.query.filter_by(id=event_id, user_id=_uid()).first_or_404()
    data  = request.get_json(force=True)

    allowed = ["title", "description", "color", "repeat_type", "reminder_offset_min"]
    for field in allowed:
        if field in data:
            setattr(event, field, data[field])

    if "start_time" in data:
        event.start_time = datetime.fromisoformat(data["start_time"])
    if "end_time" in data:
        event.end_time = datetime.fromisoformat(data["end_time"])

    db.session.commit()
    _schedule_event_reminder(event)
    return jsonify(event.to_dict())


@events_bp.delete("/<int:event_id>")
@jwt_required()
def delete_event(event_id):
    event = Event.query.filter_by(id=event_id, user_id=_uid()).first_or_404()
    _remove_event_reminder(event_id)
    db.session.delete(event)
    db.session.commit()
    return jsonify({"deleted": event_id})


# ── Scheduler helpers ────────────────────────────────────────────────────────

def _schedule_event_reminder(event: Event):
    job_id = f"event_reminder_{event.id}"
    _remove_event_reminder(event.id)

    fire_at  = event.start_time - timedelta(minutes=event.reminder_offset_min)
    now      = datetime.now(timezone.utc)
    start_dt = event.start_time
    if start_dt.tzinfo is None:
        start_dt = start_dt.replace(tzinfo=timezone.utc)
        fire_at  = fire_at.replace(tzinfo=timezone.utc)

    if fire_at > now:
        scheduler.add_job(
            func=_fire_event_reminder,
            trigger="date",
            run_date=fire_at,
            id=job_id,
            args=[event.id, event.title],
            replace_existing=True,
        )


def _remove_event_reminder(event_id: int):
    job_id = f"event_reminder_{event_id}"
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)


def _fire_event_reminder(event_id, title):
    print(f"[EVENT REMINDER] Event #{event_id}: {title}")
