class FNEvent {
  final int id;
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
        title:              j['title'],
        description:        j['description'] ?? '',
        color:              j['color'] ?? '#B2EBF2',
        startTime:          DateTime.parse(j['start_time']),
        endTime:            j['end_time'] != null ? DateTime.parse(j['end_time']) : null,
        repeatType:         j['repeat_type'] ?? 'once',
        reminderOffsetMin:  j['reminder_offset_min'] ?? 15,
        createdAt:          DateTime.parse(j['created_at']),
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
}
