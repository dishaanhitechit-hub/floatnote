import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme/palette.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});
  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _localCtrl;
  late TextEditingController _cloudCtrl;

  // ping status: null=unchecked, true=ok, false=fail
  bool? _localPing;
  bool? _cloudPing;
  bool _pinging = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _localCtrl = TextEditingController(text: s.localUrl);
    _cloudCtrl = TextEditingController(text: s.cloudUrl);
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _cloudCtrl.dispose();
    super.dispose();
  }

  Future<void> _ping() async {
    final s = context.read<SettingsProvider>();
    setState(() { _pinging = true; _localPing = null; _cloudPing = null; });
    final localOk = await ApiService(s.localUrl).ping();
    final cloudOk = s.cloudUrl.isNotEmpty
        ? await ApiService(s.cloudUrl).ping()
        : null;
    setState(() {
      _pinging = false;
      _localPing = localOk;
      _cloudPing = cloudOk;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connection & DB')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Mode selector ───────────────────────────────────────────────────
          _SectionHeader('Database Mode'),
          const SizedBox(height: 8),
          _ModeCard(
            mode: DbMode.local,
            current: s.dbMode,
            icon: Icons.storage_rounded,
            title: 'Local only',
            subtitle: 'SQLite via your local Flask server',
            onTap: () => s.setDbMode(DbMode.local),
          ),
          const SizedBox(height: 8),
          _ModeCard(
            mode: DbMode.cloud,
            current: s.dbMode,
            icon: Icons.cloud_rounded,
            title: 'Cloud only',
            subtitle: 'PostgreSQL via your hosted server',
            onTap: () => s.setDbMode(DbMode.cloud),
          ),
          const SizedBox(height: 8),
          _ModeCard(
            mode: DbMode.both,
            current: s.dbMode,
            icon: Icons.sync_alt_rounded,
            title: 'Both (dual-write)',
            subtitle: 'Writes go to local + cloud; reads from local',
            onTap: () => s.setDbMode(DbMode.both),
          ),

          const SizedBox(height: 28),

          // ── URL config ───────────────────────────────────────────────────────
          _SectionHeader('Server URLs'),
          const SizedBox(height: 12),
          _UrlField(
            label: 'Local URL',
            hint: 'http://10.0.2.2:5050',
            ctrl: _localCtrl,
            icon: Icons.computer_rounded,
            pingStatus: _localPing,
            onSave: () => s.setLocalUrl(_localCtrl.text.trim()),
          ),
          const SizedBox(height: 12),
          _UrlField(
            label: 'Cloud URL',
            hint: 'https://yourapp.railway.app',
            ctrl: _cloudCtrl,
            icon: Icons.cloud_queue_rounded,
            pingStatus: _cloudPing,
            onSave: () => s.setCloudUrl(_cloudCtrl.text.trim()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pinging ? null : _ping,
              icon: _pinging
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Test Connections'),
            ),
          ),

          const SizedBox(height: 32),

          // ── DB Manager ───────────────────────────────────────────────────────
          _SectionHeader('Clear Date Range'),
          const SizedBox(height: 12),
          _DbClearPanel(settings: s),
        ],
      ),
    );
  }
}

// ── DB Clear panel ─────────────────────────────────────────────────────────────

class _DbClearPanel extends StatefulWidget {
  final SettingsProvider settings;
  const _DbClearPanel({required this.settings});
  @override
  State<_DbClearPanel> createState() => _DbClearPanelState();
}

class _DbClearPanelState extends State<_DbClearPanel> {
  DateTime? _from;
  DateTime? _to;
  final _fmt = DateFormat('yyyy-MM-dd');
  bool _busy = false;
  String? _msg;

  Future<void> _clear(ApiService api, String label) async {
    if (_from == null || _to == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear $label DB?'),
        content: Text(
            'Delete all tasks & events from ${_fmt.format(_from!)} to ${_fmt.format(_to!)}.\nA summary is saved first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() { _busy = true; _msg = null; });
    try {
      final res = await api.clearRange(_fmt.format(_from!), _fmt.format(_to!));
      setState(() => _msg =
          '[$label] Cleared ${res['deleted_tasks']} tasks, ${res['deleted_events']} events. Summary saved.');
    } catch (e) {
      setState(() => _msg = '[$label] Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _clearBoth() async {
    await _clear(widget.settings.localApi, 'Local');
    final c = widget.settings.cloudApi;
    if (c != null) await _clear(c, 'Cloud');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date pickers
        Row(children: [
          Expanded(child: _DateBtn(label: 'From', date: _from,
              onPick: (d) => setState(() { _from = d; _msg = null; }))),
          const SizedBox(width: 12),
          Expanded(child: _DateBtn(label: 'To', date: _to,
              onPick: (d) => setState(() { _to = d; _msg = null; }))),
        ]),
        const SizedBox(height: 16),

        // Clear buttons
        if (_from != null && _to != null) ...[
          if (s.dbMode == DbMode.local || s.dbMode == DbMode.both)
            _ClearBtn(
              label: 'Clear Local DB',
              icon: Icons.storage_rounded,
              color: Colors.orange.shade700,
              busy: _busy,
              onTap: () => _clear(s.localApi, 'Local'),
            ),
          if (s.dbMode == DbMode.cloud || s.dbMode == DbMode.both) ...[
            const SizedBox(height: 8),
            _ClearBtn(
              label: 'Clear Cloud DB',
              icon: Icons.cloud_off_rounded,
              color: Colors.blue.shade700,
              busy: _busy,
              onTap: () {
                final c = s.cloudApi;
                if (c != null) _clear(c, 'Cloud');
              },
            ),
          ],
          if (s.dbMode == DbMode.both) ...[
            const SizedBox(height: 8),
            _ClearBtn(
              label: 'Clear Both DBs',
              icon: Icons.delete_sweep_rounded,
              color: Colors.red.shade700,
              busy: _busy,
              onTap: _clearBoth,
            ),
          ],
        ],

        if (_msg != null) ...[
          const SizedBox(height: 16),
          _StatusBanner(msg: _msg!),
        ],
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.6));
}

class _ModeCard extends StatelessWidget {
  final DbMode mode;
  final DbMode current;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode, required this.current, required this.icon,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : null,
          border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? color : Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? color : null)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )),
          if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final bool? pingStatus;
  final VoidCallback onSave;

  const _UrlField({
    required this.label, required this.hint, required this.ctrl,
    required this.icon, required this.pingStatus, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    Widget? pingIcon;
    if (pingStatus == true) {
      pingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
    } else if (pingStatus == false) {
      pingIcon = const Icon(Icons.cancel, color: Colors.red, size: 18);
    }

    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
          if (pingIcon != null) pingIcon,
          IconButton(
            icon: const Icon(Icons.save_outlined, size: 18),
            tooltip: 'Save',
            onPressed: onSave,
          ),
        ]),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: TextInputType.url,
      onSubmitted: (_) => onSave(),
    );
  }
}

class _ClearBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _ClearBtn({
    required this.label, required this.icon, required this.color,
    required this.busy, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: busy ? null : onTap,
          style: FilledButton.styleFrom(backgroundColor: color),
          icon: busy
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(icon),
          label: Text(label),
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  final String msg;
  const _StatusBanner({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isError = msg.contains('Error');
    final bg   = isError ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    // Shorten connection-refused errors to something readable
    String display = msg;
    if (msg.contains('Connection refused')) {
      final prefix = RegExp(r'^\[.*?\]').firstMatch(msg)?.group(0) ?? '';
      display = '$prefix Error: Server not reachable. Is the local Flask running?';
    } else if (msg.length > 200) {
      display = '${msg.substring(0, 200)}…';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            date != null ? DateFormat('d MMM yyyy').format(date!) : 'Pick date',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ]),
      );
}
