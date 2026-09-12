from collections import Counter
from datetime import date, datetime, timezone
from flask import Blueprint, request, jsonify
from extensions import db
from models import Task, Event, Summary

db_manager_bp = Blueprint("db_manager", __name__, url_prefix="/api/db")


@db_manager_bp.get("/preview")
def preview_range():
    """Return counts for the given date range without deleting anything."""
    from_str = request.args.get("from")
    to_str   = request.args.get("to")

    if not from_str or not to_str:
        return jsonify({"error": "from and to query params required (YYYY-MM-DD)"}), 400

    from_date = date.fromisoformat(from_str)
    to_date   = date.fromisoformat(to_str)

    tasks  = _tasks_in_range(from_date, to_date)
    events = _events_in_range(from_date, to_date)

    return jsonify({
        "from":           from_str,
        "to":             to_str,
        "task_count":     len(tasks),
        "completed_count": sum(1 for t in tasks if t.is_done),
        "event_count":    len(events),
    })


@db_manager_bp.post("/clear-range")
def clear_range():
    """
    Summarise all tasks/events in [from, to], save the summary,
    then hard-delete those records.
    """
    data = request.get_json(force=True)
    from_str = data.get("from")
    to_str   = data.get("to")

    if not from_str or not to_str:
        return jsonify({"error": "from and to are required (YYYY-MM-DD)"}), 400

    from_date = date.fromisoformat(from_str)
    to_date   = date.fromisoformat(to_str)

    tasks  = _tasks_in_range(from_date, to_date)
    events = _events_in_range(from_date, to_date)

    # Build summary
    tag_counts = Counter(t.tag for t in tasks if t.tag)
    top_tags   = ",".join(tag for tag, _ in tag_counts.most_common(5))

    lines = [f"Period: {from_str} → {to_str}"]
    lines.append(f"Tasks: {len(tasks)} total, {sum(1 for t in tasks if t.is_done)} completed.")
    lines.append(f"Events: {len(events)} scheduled.")
    if top_tags:
        lines.append(f"Top tags: {top_tags}.")
    for task in tasks:
        status = "✓" if task.is_done else "○"
        lines.append(f"  [{status}] {task.title}")

    summary = Summary(
        period_from     = from_date,
        period_to       = to_date,
        task_count      = len(tasks),
        completed_count = sum(1 for t in tasks if t.is_done),
        event_count     = len(events),
        top_tags        = top_tags,
        summary_text    = "\n".join(lines),
    )
    db.session.add(summary)

    for task in tasks:
        db.session.delete(task)
    for event in events:
        db.session.delete(event)

    db.session.commit()
    return jsonify({"summary": summary.to_dict(), "deleted_tasks": len(tasks), "deleted_events": len(events)})


@db_manager_bp.get("/summaries")
def list_summaries():
    summaries = Summary.query.order_by(Summary.created_at.desc()).all()
    return jsonify([s.to_dict() for s in summaries])


@db_manager_bp.get("/summaries/<int:summary_id>")
def get_summary(summary_id):
    s = Summary.query.get_or_404(summary_id)
    return jsonify(s.to_dict())


# ── helpers ──────────────────────────────────────────────────────────────────

def _tasks_in_range(from_date: date, to_date: date):
    from_dt = datetime(from_date.year, from_date.month, from_date.day, 0, 0, 0, tzinfo=timezone.utc)
    to_dt   = datetime(to_date.year,   to_date.month,   to_date.day,   23, 59, 59, tzinfo=timezone.utc)
    return Task.query.filter(Task.created_at >= from_dt, Task.created_at <= to_dt).all()


def _events_in_range(from_date: date, to_date: date):
    from_dt = datetime(from_date.year, from_date.month, from_date.day, 0, 0, 0, tzinfo=timezone.utc)
    to_dt   = datetime(to_date.year,   to_date.month,   to_date.day,   23, 59, 59, tzinfo=timezone.utc)
    return Event.query.filter(Event.start_time >= from_dt, Event.start_time <= to_dt).all()
