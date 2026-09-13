class FNEvent {
  int id;           // local SQLite ID
  int? serverId;    // cloud server ID
  bool synced;

  String title;
  String description;
  String color;
  DateTime startTime;
  DateTime? endTime;
  String repeatType;
  int reminderOffsetMin;
  final DateTime createdAt;

  FNEvent({
    required this.id,
    this.serverId,
    this.synced = false,
    required this.title,
    this.description = '',
    this.color = '#B2EBF2',
    required this.startTime,
    this.endTime,
    this.repeatType = 'once',
    this.reminderOffsetMin = 15,
    required this.createdAt,
  });

  factory FNEvent.fromJson(Map<String, dynamic> j) => FNEvent(
        id:                 j['id'],
        serverId:           j['id'],
        synced:             true,
        title:              j['title'],
        description:        j['description'] ?? '',
        color:              j['color'] ?? '#B2EBF2',
        startTime:          DateTime.parse(j['start_time']),
        endTime:            j['end_time'] != null ? DateTime.parse(j['end_time']) : null,
        repeatType:         j['repeat_type'] ?? 'once',
        reminderOffsetMin:  j['reminder_offset_min'] ?? 15,
        createdAt:          DateTime.parse(j['created_at']),
      );

  factory FNEvent.fromDb(Map<String, dynamic> row) => FNEvent(
        id:                 row['id'] as int,
        serverId:           row['server_id'] as int?,
        synced:             (row['synced'] as int) == 1,
        title:              row['title'] as String,
        description:        row['description'] as String? ?? '',
        color:              row['color'] as String? ?? '#B2EBF2',
        startTime:          DateTime.parse(row['start_time'] as String),
        endTime:            row['end_time'] != null
            ? DateTime.tryParse(row['end_time'] as String)
            : null,
        repeatType:         row['repeat_type'] as String? ?? 'once',
        reminderOffsetMin:  row['reminder_offset_min'] as int? ?? 15,
        createdAt:          DateTime.parse(row['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title':               title,
        'description':         description,
        'color':               color,
        'start_time':          startTime.toIso8601String(),
        'end_time':            endTime?.toIso8601String(),
        'repeat_type':         repeatType,
        'reminder_offset_min': reminderOffsetMin,
      };

  Map<String, dynamic> toDbRow() => {
        if (serverId != null) 'server_id': serverId,
        'title':               title,
        'description':         description,
        'color':               color,
        'start_time':          startTime.toIso8601String(),
        'end_time':            endTime?.toIso8601String(),
        'repeat_type':         repeatType,
        'reminder_offset_min': reminderOffsetMin,
        'synced':              synced ? 1 : 0,
        'updated_at':          DateTime.now().toIso8601String(),
      };
}
