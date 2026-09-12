from datetime import datetime, timezone
from extensions import db


class Summary(db.Model):
    __tablename__ = "summaries"

    id             = db.Column(db.Integer, primary_key=True)
    period_from    = db.Column(db.Date, nullable=False)
    period_to      = db.Column(db.Date, nullable=False)
    task_count     = db.Column(db.Integer, default=0)
    completed_count= db.Column(db.Integer, default=0)
    event_count    = db.Column(db.Integer, default=0)
    top_tags       = db.Column(db.String(300), default="")   # comma-separated
    summary_text   = db.Column(db.Text, default="")
    created_at     = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id":              self.id,
            "period_from":     self.period_from.isoformat(),
            "period_to":       self.period_to.isoformat(),
            "task_count":      self.task_count,
            "completed_count": self.completed_count,
            "event_count":     self.event_count,
            "top_tags":        self.top_tags.split(",") if self.top_tags else [],
            "summary_text":    self.summary_text,
            "created_at":      self.created_at.isoformat(),
        }
