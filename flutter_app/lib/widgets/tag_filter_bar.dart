import 'package:flutter/material.dart';
import '../theme/palette.dart';

class TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "All" chip
          _Chip(
            label: 'All',
            active: selected == null,
            color: FNPalette.primary,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 6),
          ...tags.asMap().entries.map((e) {
            final color = FNPalette.noteColors[e.key % FNPalette.noteColors.length];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: '#${e.value}',
                active: selected == e.value,
                color: color,
                onTap: () => onSelect(selected == e.value ? null : e.value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color : color.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
}
