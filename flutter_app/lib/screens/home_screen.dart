import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sticky_note.dart';
import '../widgets/note_editor_sheet.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/upcoming_strip.dart';
import '../widgets/note_template_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rng = Random();
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;
  String _searchQuery = '';
  String? _activeTag;

  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<EventProvider>().loadEvents();
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  List<Task> _filtered(List<Task> tasks) {
    return tasks.where((t) {
      final matchesTag = _activeTag == null ||
          t.tag.toLowerCase() == _activeTag!.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery) ||
          t.body.toLowerCase().contains(_searchQuery) ||
          t.tag.toLowerCase().contains(_searchQuery);
      return matchesTag && matchesSearch;
    }).toList();
  }

  List<String> _allTags(List<Task> tasks) => tasks
      .map((t) => t.tag)
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final taskProv  = context.watch<TaskProvider>();
    final eventProv = context.watch<EventProvider>();
    final settings  = context.watch<SettingsProvider>();
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final filtered  = _filtered(taskProv.tasks);
    final tags      = _allTags(taskProv.tasks);

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes…',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text('FloatNote'),
        actions: [
          // Search toggle
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon: Icon(_searchOpen ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          // Dot grid toggle
          IconButton(
            tooltip: settings.showDotGrid ? 'Hide grid' : 'Show grid',
            icon: Icon(settings.showDotGrid
                ? Icons.grid_on_rounded
                : Icons.grid_off_rounded),
            onPressed: settings.toggleDotGrid,
          ),
          // Dark mode toggle
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => settings.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: taskProv.loadTasks,
          ),
        ],
      ),
      body: taskProv.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tag filter strip
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TagFilterBar(
                    tags: tags,
                    selected: _activeTag,
                    onSelect: (t) => setState(() => _activeTag = t),
                  ),
                  const SizedBox(height: 4),
                ],

                // Canvas
                Expanded(
                  child: Stack(
                    children: [
                      // Dot grid
                      if (settings.showDotGrid)
                        CustomPaint(
                          painter: _DotGridPainter(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                          child: const SizedBox.expand(),
                        ),

                      // Zoom-and-pan canvas
                      InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale: 0.4,
                        maxScale: 2.0,
                        constrained: false,
                        child: SizedBox(
                          width: 2400,
                          height: 2400,
                          child: Stack(
                            children: [
                              // Empty state
                              if (filtered.isEmpty && taskProv.tasks.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sticky_note_2_outlined,
                                          size: 72,
                                          color: Colors.grey.withValues(
                                              alpha: 0.3)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No notes yet',
                                        style: TextStyle(
                                          color: Colors.grey.withValues(
                                              alpha: 0.5),
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap + to add your first floating note',
                                        style: TextStyle(
                                          color: Colors.grey.withValues(
                                              alpha: 0.4),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Sticky notes
                              ...filtered.map((task) => StickyNote(
                                    key: ValueKey(task.id),
                                    task: task,
                                    onDelete: () => _confirmDelete(
                                        context, taskProv, task),
                                    onTap: () => _openEditor(
                                        context, taskProv, task),
                                    onDragEnd: (x, y) =>
                                        taskProv.updatePosition(task, x, y),
                                    onToggleDone: () {
                                      HapticFeedback.lightImpact();
                                      taskProv.toggleDone(task);
                                    },
                                  )),
                            ],
                          ),
                        ),
                      ),

                      // Upcoming events strip (floating above canvas)
                      UpcomingStrip(events: eventProv.events),

                      // Zoom reset button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'zoom_reset',
                          onPressed: () => _transformCtrl.value =
                              Matrix4.identity(),
                          tooltip: 'Reset zoom',
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          elevation: 0,
                          child: Icon(Icons.fit_screen_rounded,
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_note',
        onPressed: () => _pickTemplate(context, taskProv),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  // ── Template picker → add note ─────────────────────────────────────────────

  void _pickTemplate(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NoteTemplateSheet(
        onSelect: (tmpl) => _addFromTemplate(context, provider, tmpl),
      ),
    );
  }

  void _addFromTemplate(
      BuildContext context, TaskProvider provider, NoteTemplate tmpl) {
    final size = MediaQuery.of(context).size;
    final x    = 20.0 + _rng.nextDouble() * (size.width - 230);
    final y    = 80.0 + _rng.nextDouble() * max(size.height - 300, 200);
    final rot  = (_rng.nextDouble() - 0.5) * 5;

    HapticFeedback.mediumImpact();

    provider.addTask({
      'title':    tmpl.title,
      'body':     tmpl.body,
      'color':    tmpl.color,
      'tag':      tmpl.tag,
      'pos_x':    x,
      'pos_y':    y,
      'rotation': rot,
    }).then((_) {
      if (!mounted) return;
      final task = provider.tasks.first;
      _openEditor(context, provider, task); // ignore: use_build_context_synchronously
    });
  }

  void _openEditor(BuildContext context, TaskProvider provider, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(
        task: task,
        onSave: provider.updateTask,
        onSetReminder: (dt) => provider.setReminder(task, dt),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TaskProvider provider, Task task) async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Note?'),
        content: Text('"${task.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) provider.deleteTask(task);
  }
}

// ── Dot grid painter ──────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
