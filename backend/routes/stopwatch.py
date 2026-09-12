import json
from flask import Blueprint, request, jsonify
from extensions import db
from models import StopwatchSession

stopwatch_bp = Blueprint("stopwatch", __name__, url_prefix="/api/stopwatch")


@stopwatch_bp.get("/")
def list_sessions():
    sessions = StopwatchSession.query.order_by(StopwatchSession.created_at.desc()).limit(50).all()
    return jsonify([s.to_dict() for s in sessions])


@stopwatch_bp.post("/")
def save_session():
    data = request.get_json(force=True)
    laps = data.get("laps", [])

    session = StopwatchSession(
        duration_seconds = data.get("duration_seconds", 0.0),
        laps_json        = json.dumps(laps),
        label            = data.get("label", ""),
    )
    db.session.add(session)
    db.session.commit()
    return jsonify(session.to_dict()), 201


@stopwatch_bp.delete("/<int:session_id>")
def delete_session(session_id):
    session = StopwatchSession.query.get_or_404(session_id)
    db.session.delete(session)
    db.session.commit()
    return jsonify({"deleted": session_id})
