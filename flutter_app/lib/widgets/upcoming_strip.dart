import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../theme/palette.dart';

class UpcomingStrip extends StatelessWidget {
  final List<FNEvent> events;

  const UpcomingStrip({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final now       = DateTime.now();
    final todayEnd  = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final upcoming  = events
        .where((e) => e.startTime.isAfter(now) && e.startTime.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.today_outlined, size: 16, color: FNPalette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: upcoming.take(4).map((e) {
                      final color = _eventColor(e.color);
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${DateFormat('HH:mm').format(e.startTime)}  ${e.title}',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return FNPalette.eventColors.first;
    }
  }
}
