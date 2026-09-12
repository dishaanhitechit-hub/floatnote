import 'package:flutter/material.dart';

class NoteTemplate {
  final String name;
  final String emoji;
  final String title;
  final String body;
  final String color;
  final String tag;

  const NoteTemplate({
    required this.name,
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
    required this.tag,
  });
}

const _templates = [
  NoteTemplate(
    name: 'Blank',
    emoji: '📝',
    title: 'New Note',
    body: '',
    color: '#FFF9C4',
    tag: '',
  ),
  NoteTemplate(
    name: 'To-Do',
    emoji: '✅',
    title: 'To-Do List',
    body: '□  \n□  \n□  ',
    color: '#C8E6C9',
    tag: 'todo',
  ),
  NoteTemplate(
    name: 'Meeting',
    emoji: '🤝',
    title: 'Meeting Notes',
    body: 'Date:\nAttendees:\nAgenda:\n\nAction items:\n•  ',
    color: '#BBDEFB',
    tag: 'meeting',
  ),
  NoteTemplate(
    name: 'Idea',
    emoji: '💡',
    title: 'Idea',
    body: 'What:\n\nWhy:\n\nNext step:',
    color: '#FFF3E0',
    tag: 'idea',
  ),
  NoteTemplate(
    name: 'Daily',
    emoji: '☀️',
    title: 'Daily Plan',
    body: 'Morning:\n\nAfternoon:\n\nEvening:\n\nGrateful for:',
    color: '#FCE4EC',
    tag: 'daily',
  ),
  NoteTemplate(
    name: 'Bug',
    emoji: '🐛',
    title: 'Bug Report',
    body: 'Steps to reproduce:\n1. \n\nExpected:\nActual:\n\nFix idea:',
    color: '#E1BEE7',
    tag: 'bug',
  ),
  NoteTemplate(
    name: 'Shopping',
    emoji: '🛒',
    title: 'Shopping List',
    body: '□  \n□  \n□  \n□  ',
    color: '#DCEDC8',
    tag: 'shopping',
  ),
  NoteTemplate(
    name: 'Quote',
    emoji: '💬',
    title: 'Quote',
    body: '"  "\n\n— ',
    color: '#E8EAF6',
    tag: 'quote',
  ),
];

class NoteTemplateSheet extends StatelessWidget {
  final void Function(NoteTemplate) onSelect;

  const NoteTemplateSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Choose a template',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _templates.length,
            itemBuilder: (_, i) {
              final t = _templates[i];
              final bg = Color(
                  int.parse(t.color.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(t);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(t.emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.name,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
