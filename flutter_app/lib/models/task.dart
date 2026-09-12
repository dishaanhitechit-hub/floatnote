class Task {
  final int id;
  String title;
  String body;
  String color;
  String font;
  int fontSize;
  String textColor;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textAlign;
  String emojiStamp;
  double posX;
  double posY;
  double rotation;
  bool isDone;
  DateTime? reminderTime;
  String tag;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.body = '',
    this.color = '#FFF9C4',
    this.font = 'Caveat',
    this.fontSize = 16,
    this.textColor = '#212121',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = 'left',
    this.emojiStamp = '',
    this.posX = 50,
    this.posY = 100,
    this.rotation = 0,
    this.isDone = false,
    this.reminderTime,
    this.tag = '',
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id:           j['id'],
        title:        j['title'],
        body:         j['body'] ?? '',
        color:        j['color'] ?? '#FFF9C4',
        font:         j['font'] ?? 'Caveat',
        fontSize:     j['font_size'] ?? 16,
        textColor:    j['text_color'] ?? '#212121',
        isBold:       j['is_bold'] ?? false,
        isItalic:     j['is_italic'] ?? false,
        isUnderline:  j['is_underline'] ?? false,
        textAlign:    j['text_align'] ?? 'left',
        emojiStamp:   j['emoji_stamp'] ?? '',
        posX:         (j['pos_x'] as num).toDouble(),
        posY:         (j['pos_y'] as num).toDouble(),
        rotation:     (j['rotation'] as num).toDouble(),
        isDone:       j['is_done'] ?? false,
        reminderTime: j['reminder_time'] != null
            ? DateTime.parse(j['reminder_time'])
            : null,
        tag:          j['tag'] ?? '',
        createdAt:    DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title':        title,
        'body':         body,
        'color':        color,
        'font':         font,
        'font_size':    fontSize,
        'text_color':   textColor,
        'is_bold':      isBold,
        'is_italic':    isItalic,
        'is_underline': isUnderline,
        'text_align':   textAlign,
        'emoji_stamp':  emojiStamp,
        'pos_x':        posX,
        'pos_y':        posY,
        'rotation':     rotation,
        'is_done':      isDone,
        'tag':          tag,
      };
}
