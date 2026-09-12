import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

class StickyNote extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Function(double x, double y) onDragEnd;
  final VoidCallback onToggleDone;

  const StickyNote({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onTap,
    required this.onDragEnd,
    required this.onToggleDone,
  });

  @override
  State<StickyNote> createState() => _StickyNoteState();
}

class _StickyNoteState extends State<StickyNote>
    with SingleTickerProviderStateMixin {
  late Offset _pos;
  late AnimationController _lift;
  late Animation<double> _scale;
  late Animation<double> _shadow;

  @override
  void initState() {
    super.initState();
    _pos = Offset(widget.task.posX, widget.task.posY);

    _lift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _lift, curve: Curves.easeOut),
    );
    _shadow = Tween<double>(begin: 6, end: 18).animate(
      CurvedAnimation(parent: _lift, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  Color _noteColor() {
    try {
      return Color(int.parse(widget.task.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.noteColors.first;
    }
  }

  Color _textColor() {
    try {
      return Color(int.parse(widget.task.textColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.textDark;
    }
  }

  TextAlign _align() {
    switch (widget.task.textAlign) {
      case 'center': return TextAlign.center;
      case 'right':  return TextAlign.right;
      default:       return TextAlign.left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = _noteColor();
    final textColor = _textColor();

    return Positioned(
      left: _pos.dx,
      top:  _pos.dy,
      child: GestureDetector(
        onPanStart: (_) {
          HapticFeedback.selectionClick();
          _lift.forward();
        },
        onPanUpdate: (d) => setState(() => _pos += d.delta),
        onPanEnd: (_) {
          _lift.reverse();
          widget.onDragEnd(_pos.dx, _pos.dy);
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _lift,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: widget.task.rotation * 3.14159 / 180,
              child: child,
            ),
          ),
          child: AnimatedBuilder(
            animation: _shadow,
            builder: (_, child) => Container(
              width: 190,
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: noteColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: _shadow.value,
                    offset: Offset(3, _shadow.value / 2),
                  ),
                ],
              ),
              child: child,
            ),
            child: Stack(
              children: [
                // Pin dot at top
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: noteColor.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                // Note content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 26, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji stamp
                      if (widget.task.emojiStamp.isNotEmpty)
                        Text(widget.task.emojiStamp,
                            style: const TextStyle(fontSize: 20)),

                      // Title
                      Text(
                        widget.task.title,
                        style: AppTheme.noteFont(
                          widget.task.font,
                          size: widget.task.fontSize.toDouble() + 2,
                          color: textColor,
                        ).copyWith(
                          fontWeight: widget.task.isBold
                              ? FontWeight.bold
                              : FontWeight.w600,
                          decoration: widget.task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        textAlign: _align(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (widget.task.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.task.body,
                          style: AppTheme.noteFont(
                            widget.task.font,
                            size: widget.task.fontSize.toDouble(),
                            color: textColor.withValues(alpha: 0.85),
                          ).copyWith(
                            fontStyle: widget.task.isItalic
                                ? FontStyle.italic
                                : FontStyle.normal,
                            decoration: widget.task.isUnderline
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          textAlign: _align(),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (widget.task.tag.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${widget.task.tag}',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],

                      if (widget.task.reminderTime != null) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.alarm, size: 12,
                              color: textColor.withValues(alpha: 0.6)),
                          const SizedBox(width: 3),
                          Text(
                            _formatReminder(widget.task.reminderTime!),
                            style: TextStyle(
                                fontSize: 10,
                                color: textColor.withValues(alpha: 0.6)),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),

                // Done tick + delete row
                Positioned(
                  bottom: 6, right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: widget.onToggleDone,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: widget.task.isDone
                                ? Colors.green.shade400
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: widget.task.isDone
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Icon(Icons.close,
                            size: 16,
                            color: textColor.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatReminder(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}  $h:$m';
  }
}
