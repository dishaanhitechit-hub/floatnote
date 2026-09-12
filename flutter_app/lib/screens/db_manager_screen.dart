import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/palette.dart';

class DbManagerScreen extends StatefulWidget {
  const DbManagerScreen({super.key});
  @override
  State<DbManagerScreen> createState() => _DbManagerScreenState();
}

class _DbManagerScreenState extends State<DbManagerScreen> {
  final _api = ApiService();
  DateTime? _from;
  DateTime? _to;
  Map<String, dynamic>? _preview;
  bool _loadingPreview = false;
  bool _loadingClear   = false;
  String? _resultMsg;

  final _fmt = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB Manager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FNPalette.noteColors[2].withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                const Icon(Icons.auto_delete_outlined, size: 32,
                    color: Colors.black45),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Clear Date Range',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 2),
                      Text(
                          'A summary is saved before anything is deleted.',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // Date pickers
            Row(
              children: [
                Expanded(child: _DateBtn(
                  label: 'From',
                  date: _from,
                  onPick: (d) => setState(() { _from = d; _preview = null; }),
                )),
                const SizedBox(width: 14),
                Expanded(child: _DateBtn(
                  label: 'To',
                  date: _to,
                  onPick: (d) => setState(() { _to = d; _preview = null; }),
                )),
              ],
            ),

            const SizedBox(height: 20),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (_from != null && _to != null && !_loadingPreview)
                    ? _doPreview
                    : null,
                icon: _loadingPreview
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.preview_outlined),
                label: const Text('Preview'),
              ),
            ),

            // Preview result
            if (_preview != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FNPalette.noteColors[6].withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow('Tasks', '${_preview!['task_count']}'),
                    _StatRow('Completed',
                        '${_preview!['completed_count']}'),
                    _StatRow('Events', '${_preview!['event_count']}'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Clear button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadingClear ? null : _doClear,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade400),
                  icon: _loadingClear
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear & Save Summary'),
                ),
              ),
            ],

            // Result message
            if (_resultMsg != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_resultMsg!,
                          style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _doPreview() async {
    setState(() { _loadingPreview = true; _resultMsg = null; });
    try {
      final res = await _api.previewRange(
          _fmt.format(_from!), _fmt.format(_to!));
      setState(() => _preview = res);
    } catch (e) {
      _showErr(e.toString());
    } finally {
      setState(() => _loadingPreview = false);
    }
  }

  Future<void> _doClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Clear'),
        content: const Text(
            'All tasks and events in this range will be permanently deleted after a summary is saved. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loadingClear = true);
    try {
      final res = await _api.clearRange(
          _fmt.format(_from!), _fmt.format(_to!));
      setState(() {
        _preview   = null;
        _from      = null;
        _to        = null;
        _resultMsg =
            'Cleared ${res['deleted_tasks']} tasks and ${res['deleted_events']} events. Summary saved.';
      });
    } catch (e) {
      _showErr(e.toString());
    } finally {
      setState(() => _loadingClear = false);
    }
  }

  void _showErr(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onPick;
  const _DateBtn({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime(2030),
          );
          if (d != null) onPick(d);
        },
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              date != null
                  ? DateFormat('d MMM yyyy').format(date!)
                  : 'Pick date',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );
}
