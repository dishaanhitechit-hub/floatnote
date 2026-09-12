import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/summary.dart';
import '../services/api_service.dart';
import '../theme/palette.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});
  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _api = ApiService();
  List<Summary> _summaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _summaries = await _api.fetchSummaries();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _summaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_edu,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No summaries yet.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text('Clear a date range to generate one.',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _summaries.length,
                  itemBuilder: (_, i) => _SummaryCard(summary: _summaries[i]),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Summary summary;
  const _SummaryCard({required this.summary});

  static final _colors = FNPalette.noteColors;

  @override
  Widget build(BuildContext context) {
    final color = _colors[summary.id % _colors.length];
    final doneRate = summary.taskCount == 0
        ? 0.0
        : summary.completedCount / summary.taskCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: color.withValues(alpha: 0.5),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${summary.taskCount}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
        title: Text(
          '${summary.periodFrom}  →  ${summary.periodTo}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              // completion bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: doneRate,
                    backgroundColor: Colors.black12,
                    color: Colors.green.shade400,
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.completedCount}/${summary.taskCount} done',
                style: const TextStyle(fontSize: 11),
              ),
            ]),
            const SizedBox(height: 4),
            if (summary.topTags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: summary.topTags
                    .map((t) => Chip(
                          label: Text('#$t',
                              style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: color,
                        ))
                    .toList(),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.summaryText,
                    style: const TextStyle(fontSize: 12, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: summary.summaryText));
                        HapticFeedback.lightImpact();
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
