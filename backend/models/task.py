from datetime import datetime, timezone
from extensions import db


class Task(db.Model):
    __tablename__ = "tasks"

    id            = db.Column(db.Integer, primary_key=True)
    user_id       = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    title         = db.Column(db.String(200), nullable=False)
    body          = db.Column(db.Text, default="")
    color         = db.Column(db.String(20), default="#FFF9C4")   # hex pastel
    font          = db.Column(db.String(60), default="Caveat")
    font_size     = db.Column(db.Integer, default=16)
    text_color    = db.Column(db.String(20), default="#212121")
    is_bold       = db.Column(db.Boolean, default=False)
    is_italic     = db.Column(db.Boolean, default=False)
    is_underline  = db.Column(db.Boolean, default=False)
    text_align    = db.Column(db.String(10), default="left")
    emoji_stamp   = db.Column(db.String(10), default="")          # single emoji
    pos_x         = db.Column(db.Float, default=50.0)
    pos_y         = db.Column(db.Float, default=100.0)
    rotation      = db.Column(db.Float, default=0.0)              # degrees
    is_done       = db.Column(db.Boolean, default=False)
    reminder_time = db.Column(db.DateTime, nullable=True)
    tag           = db.Column(db.String(60), default="")
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc),
                              onupdate=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id":           self.id,
            "title":        self.title,
            "body":         self.body,
            "color":        self.color,
            "font":         self.font,
            "font_size":    self.font_size,
            "text_color":   self.text_color,
            "is_bold":      self.is_bold,
            "is_italic":    self.is_italic,
            "is_underline": self.is_underline,
            "text_align":   self.text_align,
            "emoji_stamp":  self.emoji_stamp,
            "pos_x":        self.pos_x,
            "pos_y":        self.pos_y,
            "rotation":     self.rotation,
            "is_done":      self.is_done,
            "reminder_time": self.reminder_time.isoformat() if self.reminder_time else None,
            "tag":          self.tag,
            "created_at":   self.created_at.isoformat(),
            "updated_at":   self.updated_at.isoformat(),
        }
