from datetime import datetime, timezone
from extensions import db


class Event(db.Model):
    __tablename__ = "events"

    id                  = db.Column(db.Integer, primary_key=True)
    title               = db.Column(db.String(200), nullable=False)
    description         = db.Column(db.Text, default="")
    color               = db.Column(db.String(20), default="#B2EBF2")
    start_time          = db.Column(db.DateTime, nullable=False)
    end_time            = db.Column(db.DateTime, nullable=True)
    # once | daily | weekly | monthly
    repeat_type         = db.Column(db.String(20), default="once")
    # minutes before event to fire reminder
    reminder_offset_min = db.Column(db.Integer, default=15)
    created_at          = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id":                   self.id,
            "title":                self.title,
            "description":          self.description,
            "color":                self.color,
            "start_time":           self.start_time.isoformat(),
            "end_time":             self.end_time.isoformat() if self.end_time else None,
            "repeat_type":          self.repeat_type,
            "reminder_offset_min":  self.reminder_offset_min,
            "created_at":           self.created_at.isoformat(),
        }
