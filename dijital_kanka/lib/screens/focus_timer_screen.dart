import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/focus_provider.dart';
import '../providers/xp_provider.dart';

enum _FocusMode { free, min15, min25, min45 }

/// Odak Sayacı (Kronometre/Pomodoro) modülü — kullanıcı bir süre belirleyip
/// (15/25/45 dakika, geri sayım) veya serbest bir kronometre olarak
/// odaklanma sürelerini takip edebilir. Süre bitince (veya elle
/// durdurulduğunda) oturum `FocusProvider`'a kaydedilir + kazanılan dakika
/// kadar XP verilir (bkz. CLAUDE.md "Odak Sayacı" / "Level/XP Sistemi"
/// bölümleri). Diğer modül ekranları gibi Z-butonu menüsünden push edilir.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  _FocusMode _mode = _FocusMode.free;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  int? get _targetSeconds => switch (_mode) {
    _FocusMode.free => null,
    _FocusMode.min15 => 15 * 60,
    _FocusMode.min25 => 25 * 60,
    _FocusMode.min45 => 45 * 60,
  };

  bool get _hasProgress => _elapsedSeconds > 0;

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      final target = _targetSeconds;
      if (target != null && _elapsedSeconds >= target) {
        _finish();
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    if (mounted) setState(() => _isRunning = false);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
    });
  }

  void _finish() {
    _ticker?.cancel();
    final duration = _elapsedSeconds;
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
    });
    final l10n = AppLocalizations.of(context)!;
    final saved = context.read<FocusProvider>().addSession(duration);
    if (saved) {
      // Kazanılan XP, odaklanılan dakika kadar (en az 1, en fazla 60 —
      // tek bir oturumun aşırı büyük bir seviye atlamasına yol açmasın
      // diye üst sınır, bkz. CLAUDE.md "Level/XP Sistemi" bölümü).
      final minutes = (duration / 60).floor().clamp(1, 60);
      context.read<XpProvider>().addXp(minutes);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.focusSessionSavedMessage(minutes))),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.focusSessionTooShortMessage)));
    }
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final totalSeconds = context.watch<FocusProvider>().totalFocusSeconds;
    final target = _targetSeconds;
    final progress = target == null ? null : (_elapsedSeconds / target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.focusTimerScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // Süre seçici — çalışırken (bir ORTA seçim değişikliğinin
            // kronometreyi anlamsız hale getirmemesi için) devre dışı.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModeChip(
                  label: l10n.focusModeFreeLabel,
                  selected: _mode == _FocusMode.free,
                  onSelected: _isRunning ? null : () => setState(() => _mode = _FocusMode.free),
                ),
                _ModeChip(
                  label: l10n.focusModeMinutesLabel(15),
                  selected: _mode == _FocusMode.min15,
                  onSelected: _isRunning ? null : () => setState(() => _mode = _FocusMode.min15),
                ),
                _ModeChip(
                  label: l10n.focusModeMinutesLabel(25),
                  selected: _mode == _FocusMode.min25,
                  onSelected: _isRunning ? null : () => setState(() => _mode = _FocusMode.min25),
                ),
                _ModeChip(
                  label: l10n.focusModeMinutesLabel(45),
                  selected: _mode == _FocusMode.min45,
                  onSelected: _isRunning ? null : () => setState(() => _mode = _FocusMode.min45),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    Text(
                      _formatTimer(_elapsedSeconds),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isRunning ? _pause : _start,
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_isRunning ? l10n.focusPauseButton : l10n.focusStartButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hasProgress ? _finish : null,
                    child: Text(l10n.focusFinishButton),
                  ),
                ),
              ],
            ),
            if (_hasProgress) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _reset,
                  child: Text(l10n.focusResetButton),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.focusTotalTimeLabel),
                    Text(
                      _formatTimer(totalSeconds),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}
