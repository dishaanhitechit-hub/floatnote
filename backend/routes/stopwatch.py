import json
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models import StopwatchSession

stopwatch_bp = Blueprint("stopwatch", __name__, url_prefix="/api/stopwatch")


def _uid():
    return int(get_jwt_identity())


@stopwatch_bp.get("/")
@jwt_required()
def list_sessions():
    sessions = (
        StopwatchSession.query
        .filter_by(user_id=_uid())
        .order_by(StopwatchSession.created_at.desc())
        .limit(50)
        .all()
    )
    return jsonify([s.to_dict() for s in sessions])


@stopwatch_bp.post("/")
@jwt_required()
def save_session():
    data = request.get_json(force=True)
    laps = data.get("laps", [])

    session = StopwatchSession(
        user_id          = _uid(),
        duration_seconds = data.get("duration_seconds", 0.0),
        laps_json        = json.dumps(laps),
        label            = data.get("label", ""),
    )
    db.session.add(session)
    db.session.commit()
    return jsonify(session.to_dict()), 201


@stopwatch_bp.delete("/<int:session_id>")
@jwt_required()
def delete_session(session_id):
    session = StopwatchSession.query.filter_by(id=session_id, user_id=_uid()).first_or_404()
    db.session.delete(session)
    db.session.commit()
    return jsonify({"deleted": session_id})
