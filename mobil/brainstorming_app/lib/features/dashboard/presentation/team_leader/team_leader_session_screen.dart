import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/session_repository.dart';

/// ------------------------------------------------------------
/// UI MODEL – Leader canlı session için temel config
/// (Bu hala navigation ile geliyor: SessionHistory’den vs.)
/// ------------------------------------------------------------
class UiLeaderLiveSessionConfig {
  final int sessionId;
  final int teamId;
  final String eventName;
  final String topicTitle;
  final String teamName;
  final int teamSize;
  final int totalRounds;
  final int roundDurationSeconds; // örn. 300 (5 dk)

  const UiLeaderLiveSessionConfig({
    required this.sessionId,
    required this.teamId,
    required this.eventName,
    required this.topicTitle,
    required this.teamName,
    required this.teamSize,
    required this.totalRounds,
    required this.roundDurationSeconds,
  });
}

/// ------------------------------------------------------------
/// Round summary modeli (UI için – şimdilik dummy)
/// ------------------------------------------------------------
class RoundInfo {
  final int roundNumber;
  final int participants;
  final int submittedIdeas;

  RoundInfo({
    required this.roundNumber,
    required this.participants,
    required this.submittedIdeas,
  });
}

/// ------------------------------------------------------------
/// LEADER SESSION SCREEN – 6-3-5 (Backend entegre)
/// ------------------------------------------------------------
/// Kontrol tarafı:
/// - POST  /api/sessions/{sessionId}/control { action: START/PAUSE/RESUME/END }
/// - POST  /api/sessions/{sessionId}/rounds/advance
/// - POST  /api/ai/sessions/{sessionId}/suggestions
/// - GET   /api/sessions/{sessionId} (state sync)
///
/// WebSocket entegrasyonu için TODO noktaları yorumlarda.
/// Şimdilik timer client-side’da dönüyor ama state backend’e yazılıyor.
class LeaderSessionScreen extends ConsumerStatefulWidget {
  final UiLeaderLiveSessionConfig config;

  const LeaderSessionScreen({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<LeaderSessionScreen> createState() =>
      _LeaderSessionScreenState();
}

class _LeaderSessionScreenState extends ConsumerState<LeaderSessionScreen> {
  // Config’ten convenience getter’lar
  int get _totalRounds => widget.config.totalRounds;
  Duration get _roundDuration =>
      Duration(seconds: widget.config.roundDurationSeconds);

  String get _topicTitle => widget.config.topicTitle;
  String get _eventName => widget.config.eventName;
  String get _teamName => widget.config.teamName;
  int get _teamSize => widget.config.teamSize;
  int get _sessionId => widget.config.sessionId;
  int get _teamId => widget.config.teamId;

  // Session state (backend karşılığı: status, currentRound, timerRemainingSeconds)
  int _currentRound = 0; // 0 = PENDING
  int _remainingSeconds = 0;

  bool _isSessionActive = false; // RUNNING/PAUSED/WAITING
  bool _isRoundActive = false;
  bool _isPaused = false;

  bool _isActionLoading = false; // START / PAUSE / RESUME / NEXT / END call’ları

  Timer? _timer;

  // Rounds summary (dummy) – Phase 3’te GET /reports/sessions/{id} ile gelecek
  final List<RoundInfo> _roundsSummary = [];

  // UI için insan okunur status (backend enum’una denk gelecek)
  String get _sessionStatusLabel {
    if (!_isSessionActive && _currentRound == 0) {
      return 'PENDING – session not started';
    }
    if (_isSessionActive && _isRoundActive && !_isPaused) {
      return 'RUNNING – Round $_currentRound';
    }
    if (_isSessionActive && _isRoundActive && _isPaused) {
      return 'PAUSED – Round $_currentRound';
    }
    if (!_isSessionActive && _currentRound >= _totalRounds) {
      return 'COMPLETED – all rounds finished';
    }
    return 'WAITING – next round not started';
  }

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında mevcut state’i backend’den çekelim.
    _syncFromBackendInitial();
    // TODO (WebSocket):
    // Burada sessionId için WebSocket’e subscribe olunabilir.
  }

  @override
  void dispose() {
    _timer?.cancel();
    // TODO (WebSocket):
    // WebSocket bağlantısını kapat.
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BACKEND STATE SYNC
  // ---------------------------------------------------------------------------

  Future<void> _syncFromBackendInitial() async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.getLiveSessionState(_sessionId);

      setState(() {
        _currentRound = state.currentRound;
        _remainingSeconds = state.timerRemainingSeconds;
        _isSessionActive =
            !(state.isPending || state.isCompleted); // RUNNING/PAUSED/WAITING
        _isPaused = state.isPaused;
        _isRoundActive = state.isRunning;

        // Eğer timerRemaining 0 geldiyse, henüz start edilmemiş olabilir
        if (_currentRound == 0) {
          _isSessionActive = false;
          _isRoundActive = false;
          _isPaused = false;
          _remainingSeconds = _roundDuration.inSeconds;
        } else if (_remainingSeconds == 0 && state.isRunning) {
          _remainingSeconds = _roundDuration.inSeconds;
        }
      });

      if (_isSessionActive && _isRoundActive && !_isPaused) {
        _startTimer();
      }
    } catch (_) {
      // Sessiz geçiyoruz; kullanıcı ekranı zaten "PENDING" gibi görecek.
    }
  }

  // ---------------------------------------------------------------------------
  // SESSION CONTROL (START / PAUSE / RESUME / NEXT ROUND / END)
  // ---------------------------------------------------------------------------

  Future<void> _startSession() async {
    if (_isSessionActive || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.controlSession(
        sessionId: _sessionId,
        action: 'START',
      );

      setState(() {
        _isSessionActive = true;
        _currentRound = state.currentRound == 0 ? 1 : state.currentRound;
        _isRoundActive = state.isRunning || _currentRound > 0;
        _isPaused = false;
        _remainingSeconds = state.timerRemainingSeconds > 0
            ? state.timerRemainingSeconds
            : _roundDuration.inSeconds;
        _roundsSummary.clear();
      });

      _startTimer();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Session started. Round 1 is now live.'),
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (!_isRoundActive || _isPaused) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRoundActive = false;
        });
        _onRoundAutoFinished();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _onRoundAutoFinished() async {
    // Timer client-side bittiğinde:
    // Backend’de round advance tetikleyelim.
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.advanceRound(_sessionId);

      // Dummy summary: gerçek idea sayıları rapor endpoint’inden gelecek.
      setState(() {
        _roundsSummary.add(
          RoundInfo(
            roundNumber: _currentRound,
            participants: _teamSize,
            submittedIdeas: _teamSize * 3,
          ),
        );

        _currentRound = state.currentRound;
        _remainingSeconds = state.timerRemainingSeconds > 0
            ? state.timerRemainingSeconds
            : _roundDuration.inSeconds;
        _isSessionActive = !(state.isPending || state.isCompleted);
        _isPaused = state.isPaused;
        _isRoundActive = state.isRunning;
      });

      if (_isSessionActive && _isRoundActive && !_isPaused) {
        _startTimer();
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Round $_currentRound finished (auto).'),
          ),
        );
    } catch (e) {
      // Eğer backend round advance’i kabul etmediyse, en azından uyar.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Round auto-finish failed on backend: $e',
            ),
          ),
        );
    }

    // TODO (WebSocket):
    // Aslında gerçek product’ta timer server’da çalışır
    // ve round advance event’i WebSocket ile gelir.
  }

  Future<void> _togglePauseResume() async {
    if (!_isSessionActive || !_isRoundActive || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    final action = _isPaused ? 'RESUME' : 'PAUSE';

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.controlSession(
        sessionId: _sessionId,
        action: action,
      );

      setState(() {
        _isPaused = state.isPaused;
        _isSessionActive = !(state.isPending || state.isCompleted);
        _isRoundActive = state.isRunning;
        _remainingSeconds = state.timerRemainingSeconds > 0
            ? state.timerRemainingSeconds
            : _remainingSeconds;
      });

      if (_isPaused) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content:
                  Text('Round paused. Participants cannot edit ideas.'),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Round resumed. Timer is running again.'),
            ),
          );
        _startTimer();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to $action round: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _goToNextRound() async {
    if (!_isSessionActive || _isActionLoading) return;

    if (_currentRound >= _totalRounds) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'All $_totalRounds rounds have already been completed. Please end the session.',
            ),
          ),
        );
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.advanceRound(_sessionId);

      // Önceki round’u dummy olarak summary’e ekle
      setState(() {
        _roundsSummary.add(
          RoundInfo(
            roundNumber: _currentRound == 0 ? 1 : _currentRound,
            participants: _teamSize,
            submittedIdeas: _teamSize * 3,
          ),
        );

        _currentRound = state.currentRound;
        _remainingSeconds = state.timerRemainingSeconds > 0
            ? state.timerRemainingSeconds
            : _roundDuration.inSeconds;
        _isSessionActive = !(state.isPending || state.isCompleted);
        _isPaused = state.isPaused;
        _isRoundActive = state.isRunning;
      });

      if (_isSessionActive && _isRoundActive && !_isPaused) {
        _startTimer();
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Round $_currentRound started.'),
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to go to next round: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _endSession() async {
    if (!_isSessionActive || _isActionLoading) return;

    setState(() => _isActionLoading = true);
    _timer?.cancel();

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final state = await repo.controlSession(
        sessionId: _sessionId,
        action: 'END',
      );

      // Son round özetini de ekleyelim (dummy)
      if (_currentRound > 0) {
        _roundsSummary.add(
          RoundInfo(
            roundNumber: _currentRound,
            participants: _teamSize,
            submittedIdeas: _teamSize * 3,
          ),
        );
      }

      setState(() {
        _isSessionActive = false;
        _isRoundActive = false;
        _isPaused = false;
        _remainingSeconds = 0;
        _currentRound = state.currentRound;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Session ended. You can now check the report & AI summary for this session.',
            ),
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to end session: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _askAiSuggestions() async {
    if (!_isSessionActive || !_isRoundActive || _isActionLoading) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'AI suggestions are only available while a round is running.',
            ),
          ),
        );
      return;
    }

    setState(() => _isActionLoading = true);

    try {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.requestAiSuggestions(
        sessionId: _sessionId,
        roundNumber: _currentRound,
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Requesting AI suggestions for Round $_currentRound...',
            ),
          ),
        );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to request AI suggestions: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI HELPER’LAR
  // ---------------------------------------------------------------------------

  String _formatRemainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  double _roundProgress() {
    final total = _roundDuration.inSeconds.toDouble();
    if (total == 0) return 0;
    if (_remainingSeconds == 0 && !_isRoundActive) return 1.0;
    return (_roundDuration.inSeconds - _remainingSeconds) / total;
  }

  Widget _buildHeaderCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eventName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Team: $_teamName',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Topic: $_topicTitle',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_teamSize participants',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.all_inclusive, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalRounds rounds · '
                      '${_roundDuration.inMinutes} min each',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundInfoCard() {
    final theme = Theme.of(context);
    final isFinished =
        _isSessionActive == false && _currentRound > 0 && !_isRoundActive;
    final progress = _roundProgress().clamp(0.0, 1.0);

    String statusText;
    if (!_isSessionActive && _currentRound == 0) {
      statusText = 'Session not started';
    } else if (_isRoundActive && !_isPaused) {
      statusText = 'Round $_currentRound in progress';
    } else if (_isRoundActive && _isPaused) {
      statusText = 'Round $_currentRound is paused';
    } else if (isFinished && _currentRound >= _totalRounds) {
      statusText = 'All $_totalRounds rounds completed';
    } else {
      statusText = 'Waiting to start next round';
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sessionStatusLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: !_isSessionActive ? 0 : progress,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _isSessionActive ? _formatRemainingTime() : '--:--',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _isRoundActive
                          ? (_isPaused ? 'Paused' : 'Time left')
                          : 'Not running',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundDots() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalRounds, (index) {
        final roundNumber = index + 1;
        final isCurrent = roundNumber == _currentRound && _isSessionActive;
        final isCompleted = _roundsSummary
            .any((r) => r.roundNumber == roundNumber); // dummy info

        Color bg;
        IconData? icon;

        if (isCurrent) {
          bg = theme.colorScheme.primary;
          icon = Icons.edit;
        } else if (isCompleted) {
          bg = Colors.green;
          icon = Icons.check;
        } else {
          bg = theme.colorScheme.surfaceContainerHighest;
          icon = null;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: icon == null
              ? Text(
                  '$roundNumber',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface,
                  ),
                )
              : Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
        );
      }),
    );
  }

  Widget _buildRoundsSummary() {
    final theme = Theme.of(context);

    if (_roundsSummary.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Completed rounds summary will appear here. '
          'Each row shows how many ideas were submitted in that round.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _roundsSummary.map((round) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'Round ${round.roundNumber}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${round.participants} participants · ${round.submittedIdeas} ideas',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllRoundsDone =
        _currentRound >= _totalRounds && _roundsSummary.length >= _totalRounds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leader – Live Session (6-3-5)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildRoundDots(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 12),
                    _buildRoundInfoCard(),
                    const SizedBox(height: 16),
                    const Text(
                      'Rounds summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRoundsSummary(),
                    const SizedBox(height: 24),
                    Text(
                      'Note: In the real app, round start/stop and timer sync '
                      'will be driven by backend + WebSocket events. This screen '
                      'currently stores state to the backend and simulates the '
                      'countdown locally.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom controls
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Start / Next round
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isActionLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              !_isSessionActive
                                  ? Icons.play_arrow
                                  : (_currentRound >= _totalRounds
                                      ? Icons.check
                                      : Icons.skip_next),
                            ),
                      label: Text(
                        !_isSessionActive
                            ? 'Start session (Round 1)'
                            : (_currentRound >= _totalRounds
                                ? 'All $_totalRounds rounds completed'
                                : 'Start next round'),
                      ),
                      onPressed: _isActionLoading
                          ? null
                          : (!_isSessionActive
                              ? _startSession
                              : (_currentRound >= _totalRounds
                                  ? null
                                  : _goToNextRound)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pause / Resume
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      icon: _isActionLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                            ),
                      label: Text(
                        !_isSessionActive
                            ? 'Pause / resume (session not started)'
                            : (_isPaused ? 'Resume round' : 'Pause round'),
                      ),
                      onPressed: _isActionLoading ||
                              (!_isSessionActive || !_isRoundActive)
                          ? null
                          : _togglePauseResume,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // AI suggestions
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      icon: _isActionLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Ask AI for suggestions'),
                      onPressed: _isActionLoading ||
                              (!_isSessionActive || !_isRoundActive)
                          ? null
                          : _askAiSuggestions,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // End session
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: TextButton.icon(
                      icon: Icon(
                        Icons.stop,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'End session',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      onPressed:
                          _isActionLoading || !_isSessionActive ? null : _endSession,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isAllRoundsDone)
                    Text(
                      'You can now open the session report & AI summary from the leader reports screen.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
