import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

class NoteEditorSheet extends StatefulWidget {
  final Task task;
  final Function(Task) onSave;
  final Function(DateTime) onSetReminder;

  const NoteEditorSheet({
    super.key,
    required this.task,
    required this.onSave,
    required this.onSetReminder,
  });

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late Task _task;

  final _emojis = ['', '⭐', '🔥', '💡', '📌', '🎯', '💪', '🌈', '✨', '🍀', '🎉', '💌'];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleCtrl = TextEditingController(text: _task.title);
    _bodyCtrl  = TextEditingController(text: _task.body);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Color get _noteColor {
    try {
      return Color(int.parse(_task.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.noteColors.first;
    }
  }

  Color get _textColor {
    try {
      return Color(int.parse(_task.textColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.textDark;
    }
  }

  void _save() {
    _task.title = _titleCtrl.text.trim();
    _task.body  = _bodyCtrl.text.trim();
    widget.onSave(_task);
    Navigator.pop(context);
  }

  String _colorHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: _noteColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Toolbar
            _Toolbar(
              task: _task,
              onChanged: (t) => setState(() => _task = t),
              emojis: _emojis,
              noteColor: _noteColor,
              textColor: _textColor,
              onColorNoteChanged: (c) =>
                  setState(() => _task.color = _colorHex(c)),
              onColorTextChanged: (c) =>
                  setState(() => _task.textColor = _colorHex(c)),
            ),

            const Divider(height: 1, thickness: 1, color: Colors.black12),

            // Text fields
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: AppTheme.noteFont(
                      _task.font,
                      size: _task.fontSize.toDouble() + 4,
                      color: _textColor,
                    ).copyWith(
                      fontWeight:
                          _task.isBold ? FontWeight.bold : FontWeight.w600,
                      fontStyle: _task.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      decoration: _task.isUnderline
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    textAlign: _alignEnum(),
                    decoration: InputDecoration(
                      hintText: 'Title…',
                      hintStyle: TextStyle(color: _textColor.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyCtrl,
                    style: AppTheme.noteFont(
                      _task.font,
                      size: _task.fontSize.toDouble(),
                      color: _textColor,
                    ).copyWith(
                      fontStyle: _task.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      decoration: _task.isUnderline
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    textAlign: _alignEnum(),
                    decoration: InputDecoration(
                      hintText: 'Write something…',
                      hintStyle: TextStyle(color: _textColor.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    minLines: 6,
                  ),
                ],
              ),
            ),

            // Bottom actions
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  // Reminder
                  OutlinedButton.icon(
                    onPressed: _pickReminder,
                    icon: const Icon(Icons.alarm_add, size: 16),
                    label: Text(
                      _task.reminderTime != null ? 'Edit Reminder' : 'Remind',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textColor,
                      side: BorderSide(color: _textColor.withValues(alpha: 0.4)),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _textColor.withValues(alpha: 0.85),
                      foregroundColor: _noteColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextAlign _alignEnum() {
    switch (_task.textAlign) {
      case 'center': return TextAlign.center;
      case 'right':  return TextAlign.right;
      default:       return TextAlign.left;
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _task.reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_task.reminderTime ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _task.reminderTime = dt);
    widget.onSetReminder(dt);
  }
}

// ── Formatting toolbar ────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final Task task;
  final Function(Task) onChanged;
  final List<String> emojis;
  final Color noteColor;
  final Color textColor;
  final Function(Color) onColorNoteChanged;
  final Function(Color) onColorTextChanged;

  const _Toolbar({
    required this.task,
    required this.onChanged,
    required this.emojis,
    required this.noteColor,
    required this.textColor,
    required this.onColorNoteChanged,
    required this.onColorTextChanged,
  });

  void _update(void Function() fn) {
    fn();
    onChanged(task);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Bold
          _ToggleBtn(
            active: task.isBold,
            icon: Icons.format_bold,
            onTap: () => _update(() => task.isBold = !task.isBold),
          ),
          // Italic
          _ToggleBtn(
            active: task.isItalic,
            icon: Icons.format_italic,
            onTap: () => _update(() => task.isItalic = !task.isItalic),
          ),
          // Underline
          _ToggleBtn(
            active: task.isUnderline,
            icon: Icons.format_underlined,
            onTap: () => _update(() => task.isUnderline = !task.isUnderline),
          ),

          const _Divider(),

          // Align
          _ToggleBtn(
            active: task.textAlign == 'left',
            icon: Icons.format_align_left,
            onTap: () => _update(() => task.textAlign = 'left'),
          ),
          _ToggleBtn(
            active: task.textAlign == 'center',
            icon: Icons.format_align_center,
            onTap: () => _update(() => task.textAlign = 'center'),
          ),
          _ToggleBtn(
            active: task.textAlign == 'right',
            icon: Icons.format_align_right,
            onTap: () => _update(() => task.textAlign = 'right'),
          ),

          const _Divider(),

          // Font size
          _IconBtn(
            icon: Icons.text_decrease,
            onTap: () => _update(() {
              if (task.fontSize > 10) task.fontSize--;
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('${task.fontSize}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          _IconBtn(
            icon: Icons.text_increase,
            onTap: () => _update(() {
              if (task.fontSize < 32) task.fontSize++;
            }),
          ),

          const _Divider(),

          // Font picker
          _FontPicker(
            current: task.font,
            onPick: (f) => _update(() => task.font = f),
          ),

          const _Divider(),

          // Note background color
          _ColorSwatch(
            label: 'BG',
            color: noteColor,
            onPick: onColorNoteChanged,
            context: context,
            pastelColors: FNPalette.noteColors,
          ),

          // Text color
          _ColorSwatch(
            label: 'T',
            color: textColor,
            onPick: onColorTextChanged,
            context: context,
            pastelColors: null,
          ),

          const _Divider(),

          // Emoji stamp picker
          _EmojiPicker(
            current: task.emojiStamp,
            emojis: emojis,
            onPick: (e) => _update(() => task.emojiStamp = e),
          ),
        ],
      ),
    );
  }
}

// ── Small toolbar sub-widgets ─────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final bool active;
  final IconData icon;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.active, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        height: 24, width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.black12,
      );
}

class _FontPicker extends StatelessWidget {
  final String current;
  final Function(String) onPick;
  const _FontPicker({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final pick = await showModalBottomSheet<String>(
            context: context,
            builder: (_) => _FontSheet(current: current, onPick: (f) {
              Navigator.pop(context, f);
            }),
          );
          if (pick != null) onPick(pick);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(current, style: const TextStyle(fontSize: 12)),
        ),
      );
}

class _FontSheet extends StatelessWidget {
  final String current;
  final Function(String) onPick;
  const _FontSheet({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Choose Font',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...AppTheme.noteFonts.map((f) => ListTile(
                title: Text(f,
                    style: AppTheme.noteFont(f, size: 16)),
                trailing: f == current
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => onPick(f),
              )),
          const SizedBox(height: 12),
        ],
      );
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final Function(Color) onPick;
  final BuildContext context;
  final List<Color>? pastelColors;

  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.onPick,
    required this.context,
    required this.pastelColors,
  });

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: () => _showPicker(ctx),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 1.5),
          ),
          child: Center(
              child: Text(label,
                  style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.bold))),
        ),
      );

  void _showPicker(BuildContext ctx) {
    if (pastelColors != null) {
      showModalBottomSheet(
        context: ctx,
        builder: (_) => _PastelPicker(
          colors: pastelColors!,
          current: color,
          onPick: onPick,
        ),
      );
    } else {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Text Color'),
          content: ColorPicker(
            color: color,
            onColorChanged: onPick,
            pickersEnabled: const {ColorPickerType.wheel: true},
            width: 40, height: 40,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}

class _PastelPicker extends StatelessWidget {
  final List<Color> colors;
  final Color current;
  final Function(Color) onPick;
  const _PastelPicker(
      {required this.colors, required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note Color',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: colors.map((c) => GestureDetector(
                    onTap: () {
                      onPick(c);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == current
                              ? Colors.black54
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: c == current
                          ? const Icon(Icons.check, size: 18, color: Colors.black54)
                          : null,
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
}

class _EmojiPicker extends StatelessWidget {
  final String current;
  final List<String> emojis;
  final Function(String) onPick;
  const _EmojiPicker(
      {required this.current, required this.emojis, required this.onPick});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Stamp',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: emojis.map((e) => GestureDetector(
                        onTap: () {
                          onPick(e);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: e == current
                                ? Colors.black12
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: e.isEmpty
                                ? const Icon(Icons.block,
                                    size: 22, color: Colors.black38)
                                : Text(e,
                                    style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      )).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: current.isEmpty
              ? const Icon(Icons.emoji_emotions_outlined, size: 18)
              : Text(current, style: const TextStyle(fontSize: 18)),
        ),
      );
}
