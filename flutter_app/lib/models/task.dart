class Task {
  int id;           // local SQLite ID (primary key in app)
  int? serverId;    // cloud server ID (null = not synced yet)
  bool synced;      // true = local matches cloud

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
    this.serverId,
    this.synced = false,
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

  // From cloud API response
  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id:           j['id'],
        serverId:     j['id'],
        synced:       true,
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

  // From local SQLite row
  factory Task.fromDb(Map<String, dynamic> row) => Task(
        id:           row['id'] as int,
        serverId:     row['server_id'] as int?,
        synced:       (row['synced'] as int) == 1,
        title:        row['title'] as String,
        body:         row['body'] as String? ?? '',
        color:        row['color'] as String? ?? '#FFF9C4',
        font:         row['font'] as String? ?? 'Caveat',
        fontSize:     row['font_size'] as int? ?? 16,
        textColor:    row['text_color'] as String? ?? '#212121',
        isBold:       (row['is_bold'] as int? ?? 0) == 1,
        isItalic:     (row['is_italic'] as int? ?? 0) == 1,
        isUnderline:  (row['is_underline'] as int? ?? 0) == 1,
        textAlign:    row['text_align'] as String? ?? 'left',
        emojiStamp:   row['emoji_stamp'] as String? ?? '',
        posX:         (row['pos_x'] as num?)?.toDouble() ?? 50,
        posY:         (row['pos_y'] as num?)?.toDouble() ?? 100,
        rotation:     (row['rotation'] as num?)?.toDouble() ?? 0,
        isDone:       (row['is_done'] as int? ?? 0) == 1,
        reminderTime: row['reminder_time'] != null
            ? DateTime.tryParse(row['reminder_time'] as String)
            : null,
        tag:          row['tag'] as String? ?? '',
        createdAt:    DateTime.parse(row['created_at'] as String),
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

  Map<String, dynamic> toDbRow() => {
        if (serverId != null) 'server_id': serverId,
        'title':        title,
        'body':         body,
        'color':        color,
        'font':         font,
        'font_size':    fontSize,
        'text_color':   textColor,
        'is_bold':      isBold ? 1 : 0,
        'is_italic':    isItalic ? 1 : 0,
        'is_underline': isUnderline ? 1 : 0,
        'text_align':   textAlign,
        'emoji_stamp':  emojiStamp,
        'pos_x':        posX,
        'pos_y':        posY,
        'rotation':     rotation,
        'is_done':      isDone ? 1 : 0,
        'reminder_time': reminderTime?.toIso8601String(),
        'tag':          tag,
        'synced':       synced ? 1 : 0,
        'updated_at':   DateTime.now().toIso8601String(),
      };
}
