import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme/palette.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});
  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _elapsedMs = 0;
  bool _running = false;
  final List<int> _laps = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _pauseDropCtrl;
  late Animation<double> _pauseDrop;
  late AnimationController _startPopCtrl;
  late Animation<double> _startPop;
  late ConfettiController _confetti;

  final _player = AudioPlayer();
  int _lastTickSec = -1;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _pauseDropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pauseDrop = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _pauseDropCtrl, curve: Curves.bounceOut),
    );

    _startPopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _startPop = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _startPopCtrl, curve: Curves.elasticOut),
    );

    _confetti = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _pauseDropCtrl.dispose();
    _startPopCtrl.dispose();
    _confetti.dispose();
    _player.dispose();
    super.dispose();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      setState(() => _elapsedMs += 10);
      _maybePlayTick();
    });
    setState(() => _running = true);
    _pulseCtrl.repeat(reverse: true);
    _startPopCtrl.forward().then((_) => _startPopCtrl.reverse());
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
    _pulseCtrl.stop();
    _pulseCtrl.animateTo(0);
    _pauseDropCtrl.forward().then((_) => _pauseDropCtrl.reverse());
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _elapsedMs = 0;
      _laps.clear();
      _lastTickSec = -1;
    });
    _pulseCtrl.stop();
    _pulseCtrl.value = 0;
  }

  void _lap() {
    if (!_running) return;
    HapticFeedback.mediumImpact();
    setState(() => _laps.insert(0, _elapsedMs));
    _confetti.play();
  }

  Future<void> _saveSession(BuildContext context) async {
    if (_elapsedMs == 0) return;
    String label = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Save Session'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Label (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => label = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ApiService().saveStopwatchSession(
        durationSeconds: _elapsedMs / 1000.0,
        laps: _laps.map((ms) => ms / 1000.0).toList(),
        label: label,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved!'),
            backgroundColor: Colors.green),
      );
      _reset();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _maybePlayTick() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.stopwatchSound) return;
    final sec = _elapsedMs ~/ 1000;
    if (sec != _lastTickSec) {
      _lastTickSec = sec;
      // Play a short beep via AssetSource or UrlSource
      // Using a synthetic tick via AudioPlayer with BytesSource
      await _player.play(
        AssetSource('tick.mp3'),
        volume: 0.3,
      ).catchError((_) {}); // silently skip if asset missing
    }
  }

  Color _ringColor() {
    final secs = _elapsedMs / 1000;
    if (secs < 300)  return const Color(0xFF69F0AE); // green
    if (secs < 1200) return const Color(0xFFFFD740); // yellow
    if (secs < 3600) return const Color(0xFFFF6D00); // orange
    return const Color(0xFFFF1744);                  // red
  }

  String _format(int ms) {
    final h  = ms ~/ 3600000;
    final m  = (ms % 3600000) ~/ 60000;
    final s  = (ms % 60000) ~/ 1000;
    final cs = (ms % 1000) ~/ 10;
    if (h > 0) {
      return '${_p(h)}:${_p(m)}:${_p(s)}';
    }
    return '${_p(m)}:${_p(s)}.${_p(cs)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final settings  = context.watch<SettingsProvider>();
    final ringColor = _ringColor();
    final progress  = (_elapsedMs % 60000) / 60000.0;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          // Save session
          if (_elapsedMs > 0)
            IconButton(
              tooltip: 'Save session',
              icon: const Icon(Icons.save_outlined),
              onPressed: () => _saveSession(context),
            ),
          // Sound toggle
          IconButton(
            tooltip: settings.stopwatchSound ? 'Mute ticks' : 'Unmute ticks',
            icon: Icon(settings.stopwatchSound
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded),
            onPressed: settings.toggleStopwatchSound,
          ),
          // Theme toggle
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => settings.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            emissionFrequency: 0.6,
            numberOfParticles: 20,
            colors: FNPalette.noteColors,
          ),

          Column(
            children: [
              const SizedBox(height: 36),

              // ── Dial ───────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_pulse, _pauseDrop, _startPop]),
                builder: (_, __) {
                  double scale = _running ? _pulse.value : 1.0;
                  scale *= _startPop.value;
                  return Transform.translate(
                    offset: Offset(0, _pauseDrop.value),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 250,
                        height: 250,
                        child: CustomPaint(
                          painter: _DialPainter(
                            progress: progress,
                            color: ringColor,
                            running: _running,
                            isDark: isDark,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _format(_elapsedMs),
                                  style: GoogleFonts.nunito(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : FNPalette.textDark,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (_laps.isNotEmpty)
                                  Text(
                                    'Lap ${_laps.length + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // ── Buttons ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: Icons.refresh_rounded,
                    bg: isDark
                        ? Colors.white12
                        : Colors.grey.shade200,
                    iconColor: isDark ? Colors.white70 : Colors.black54,
                    shadow: Colors.transparent,
                    onTap: _reset,
                    size: 58,
                  ),
                  const SizedBox(width: 22),
                  _CircleBtn(
                    icon: _running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    bg: ringColor,
                    iconColor: Colors.white,
                    shadow: ringColor.withValues(alpha: 0.45),
                    onTap: _running ? _pause : _start,
                    size: 76,
                  ),
                  const SizedBox(width: 22),
                  _CircleBtn(
                    icon: Icons.flag_outlined,
                    bg: FNPalette.accent.withValues(alpha: _running ? 1 : 0.4),
                    iconColor: Colors.white,
                    shadow: _running
                        ? FNPalette.accent.withValues(alpha: 0.4)
                        : Colors.transparent,
                    onTap: _running ? _lap : null,
                    size: 58,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Laps ───────────────────────────────────────────────────────
              if (_laps.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _laps.length,
                    itemBuilder: (_, i) {
                      final lapColor = FNPalette
                          .noteColors[i % FNPalette.noteColors.length];
                      final best = _laps.reduce(min);
                      final worst = _laps.reduce(max);
                      Color labelColor = Colors.black54;
                      if (_laps[i] == best && _laps.length > 1) {
                        labelColor = Colors.green.shade600;
                      } else if (_laps[i] == worst && _laps.length > 1) {
                        labelColor = Colors.red.shade400;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: lapColor.withValues(alpha: isDark ? 0.35 : 0.6),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Text(
                            'Lap ${_laps.length - i}',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: labelColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _format(_laps[i]),
                            style: GoogleFonts.nunito(fontSize: 14),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dial painter ──────────────────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool running;
  final bool isDark;

  _DialPainter({
    required this.progress,
    required this.color,
    required this.running,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Outer glow (dark mode)
    if (isDark && running) {
      canvas.drawCircle(
        center, radius + 8,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Track ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = color.withValues(alpha: isDark ? 0.15 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks (60)
    for (int i = 0; i < 60; i++) {
      final angle  = 2 * pi * i / 60 - pi / 2;
      final isMaj  = i % 5 == 0;
      final inner  = radius - (isMaj ? 18 : 11);
      final outer  = radius - 2;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        Paint()
          ..color = color.withValues(alpha: isMaj ? 0.5 : 0.18)
          ..strokeWidth = isMaj ? 2.0 : 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color || old.isDark != isDark;
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final Color shadow;
  final VoidCallback? onTap;
  final double size;

  const _CircleBtn({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.shadow,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: size * 0.42),
        ),
      );
}
