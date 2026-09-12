import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/palette.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final dayEvents = provider.eventsForDay(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: TableCalendar<FNEvent>(
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (d) => provider.eventsForDay(d),
              onDaySelected: (sel, foc) =>
                  setState(() { _selected = sel; _focused = foc; }),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: FNPalette.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: FNPalette.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: FNPalette.accent,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: FNPalette.primary),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          // Day events list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, d MMM').format(_selected),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text('${dayEvents.length} events',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          Expanded(
            child: dayEvents.isEmpty
                ? const Center(
                    child: Text('No events  —  tap + to add one',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: dayEvents.length,
                    itemBuilder: (_, i) =>
                        _EventCard(event: dayEvents[i], provider: provider),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEvent(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addEvent(BuildContext context, EventProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddEventSheet(
        initialDate: _selected,
        onAdd: (data) => provider.addEvent(data),
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final FNEvent event;
  final EventProvider provider;
  const _EventCard({required this.event, required this.provider});

  Color get _color {
    try {
      return Color(int.parse(event.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.eventColors.first;
    }
  }

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey(event.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => provider.deleteEvent(event),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(event.description,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(event.startTime),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(children: [
                    const Icon(Icons.alarm, size: 11, color: Colors.black38),
                    Text(' ${event.reminderOffsetMin}m',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── Add event bottom sheet ────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final DateTime initialDate;
  final Function(Map<String, dynamic>) onAdd;
  const _AddEventSheet({required this.initialDate, required this.onAdd});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  late DateTime _start;
  String _repeat   = 'once';
  int _reminder    = 15;
  String _color    = '#B2EBF2';

  @override
  void initState() {
    super.initState();
    _start = widget.initialDate.copyWith(
        hour: TimeOfDay.now().hour, minute: TimeOfDay.now().minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Event',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 14),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            // Date & time
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule),
              label: Text(DateFormat('d MMM yyyy  HH:mm').format(_start)),
            ),
            const SizedBox(height: 10),

            // Repeat
            DropdownButtonFormField<String>(
              value: _repeat,
              decoration: const InputDecoration(
                  labelText: 'Repeat', border: OutlineInputBorder()),
              items: ['once', 'daily', 'weekly', 'monthly']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _repeat = v!),
            ),
            const SizedBox(height: 10),

            // Reminder offset
            Row(children: [
              const Text('Remind before: '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _reminder,
                items: [5, 10, 15, 30, 60]
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text('$v min')))
                    .toList(),
                onChanged: (v) => setState(() => _reminder = v!),
              ),
            ]),
            const SizedBox(height: 10),

            // Color row
            Wrap(
              spacing: 10,
              children: FNPalette.eventColors.map((c) {
                final hex =
                    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == hex
                            ? Colors.black54
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Add Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null) return;
    setState(() => _start =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.onAdd({
      'title':               _titleCtrl.text.trim(),
      'description':         _descCtrl.text.trim(),
      'color':               _color,
      'start_time':          _start.toIso8601String(),
      'repeat_type':         _repeat,
      'reminder_offset_min': _reminder,
    });
    Navigator.pop(context);
  }
}
