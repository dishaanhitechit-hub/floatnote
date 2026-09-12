from datetime import datetime, timezone
from flask import Blueprint, request, jsonify
from extensions import db, scheduler
from models import Task

tasks_bp = Blueprint("tasks", __name__, url_prefix="/api/tasks")


@tasks_bp.get("/")
def list_tasks():
    tasks = Task.query.order_by(Task.created_at.desc()).all()
    return jsonify([t.to_dict() for t in tasks])


@tasks_bp.post("/")
def create_task():
    data = request.get_json(force=True)
    if not data or not data.get("title"):
        return jsonify({"error": "title is required"}), 400

    task = Task(
        title        = data["title"],
        body         = data.get("body", ""),
        color        = data.get("color", "#FFF9C4"),
        font         = data.get("font", "Caveat"),
        font_size    = data.get("font_size", 16),
        text_color   = data.get("text_color", "#212121"),
        is_bold      = data.get("is_bold", False),
        is_italic    = data.get("is_italic", False),
        is_underline = data.get("is_underline", False),
        text_align   = data.get("text_align", "left"),
        emoji_stamp  = data.get("emoji_stamp", ""),
        pos_x        = data.get("pos_x", 50.0),
        pos_y        = data.get("pos_y", 100.0),
        rotation     = data.get("rotation", 0.0),
        tag          = data.get("tag", ""),
    )
    db.session.add(task)
    db.session.commit()
    return jsonify(task.to_dict()), 201


@tasks_bp.put("/<int:task_id>")
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json(force=True)

    allowed = [
        "title", "body", "color", "font", "font_size", "text_color",
        "is_bold", "is_italic", "is_underline", "text_align", "emoji_stamp",
        "pos_x", "pos_y", "rotation", "is_done", "tag",
    ]
    for field in allowed:
        if field in data:
            setattr(task, field, data[field])

    task.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(task.to_dict())


@tasks_bp.delete("/<int:task_id>")
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return jsonify({"deleted": task_id})


@tasks_bp.post("/<int:task_id>/remind")
def set_reminder(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json(force=True)

    reminder_iso = data.get("reminder_time")
    if not reminder_iso:
        return jsonify({"error": "reminder_time (ISO 8601) is required"}), 400

    reminder_dt = datetime.fromisoformat(reminder_iso)
    if reminder_dt.tzinfo is None:
        reminder_dt = reminder_dt.replace(tzinfo=timezone.utc)

    task.reminder_time = reminder_dt
    db.session.commit()

    job_id = f"task_reminder_{task_id}"
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)

    scheduler.add_job(
        func=_fire_reminder,
        trigger="date",
        run_date=reminder_dt,
        id=job_id,
        args=[task_id, task.title],
        replace_existing=True,
    )

    return jsonify({"scheduled": reminder_dt.isoformat()})


def _fire_reminder(task_id, title):
    print(f"[REMINDER] Task #{task_id}: {title}")


@tasks_bp.get("/search")
def search_tasks():
    """
    GET /api/tasks/search?q=<text>&tag=<tag>&done=<0|1>
    Any combination of filters; all are optional.
    """
    q    = request.args.get("q", "").strip()
    tag  = request.args.get("tag", "").strip()
    done = request.args.get("done")

    query = Task.query
    if q:
        like = f"%{q}%"
        query = query.filter(
            (Task.title.ilike(like)) | (Task.body.ilike(like))
        )
    if tag:
        query = query.filter(Task.tag.ilike(f"%{tag}%"))
    if done is not None:
        query = query.filter(Task.is_done == (done == "1"))

    tasks = query.order_by(Task.updated_at.desc()).all()
    return jsonify([t.to_dict() for t in tasks])


@tasks_bp.get("/tags")
def list_tags():
    """Return all unique non-empty tags with their counts."""
    rows = (
        db.session.query(Task.tag, db.func.count(Task.id))
        .filter(Task.tag != "")
        .group_by(Task.tag)
        .order_by(db.func.count(Task.id).desc())
        .all()
    )
    return jsonify([{"tag": r[0], "count": r[1]} for r in rows])
