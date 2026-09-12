class Summary {
  final int id;
  final String periodFrom;
  final String periodTo;
  final int taskCount;
  final int completedCount;
  final int eventCount;
  final List<String> topTags;
  final String summaryText;
  final DateTime createdAt;

  Summary({
    required this.id,
    required this.periodFrom,
    required this.periodTo,
    required this.taskCount,
    required this.completedCount,
    required this.eventCount,
    required this.topTags,
    required this.summaryText,
    required this.createdAt,
  });

  factory Summary.fromJson(Map<String, dynamic> j) => Summary(
        id:             j['id'],
        periodFrom:     j['period_from'],
        periodTo:       j['period_to'],
        taskCount:      j['task_count'],
        completedCount: j['completed_count'],
        eventCount:     j['event_count'],
        topTags:        List<String>.from(j['top_tags'] ?? []),
        summaryText:    j['summary_text'],
        createdAt:      DateTime.parse(j['created_at']),
      );
}
