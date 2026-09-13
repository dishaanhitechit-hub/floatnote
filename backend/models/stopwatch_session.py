import json
from datetime import datetime, timezone
from extensions import db


class StopwatchSession(db.Model):
    __tablename__ = "stopwatch_sessions"

    id               = db.Column(db.Integer, primary_key=True)
    user_id          = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    duration_seconds = db.Column(db.Float, default=0.0)
    laps_json        = db.Column(db.Text, default="[]")   # JSON array of lap floats
    label            = db.Column(db.String(120), default="")
    created_at       = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id":               self.id,
            "duration_seconds": self.duration_seconds,
            "laps":             json.loads(self.laps_json),
            "label":            self.label,
            "created_at":       self.created_at.isoformat(),
        }
