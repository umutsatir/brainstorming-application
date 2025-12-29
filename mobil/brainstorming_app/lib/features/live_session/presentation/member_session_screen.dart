import 'dart:async';

import 'package:flutter/material.dart';

/// 6-3-5 Member ekranı – ŞİMDİLİK sadece lokal state + dummy akış.
/// Phase 3'te WebSocket + gerçek session state ile entegre edilecek.

class SubmittedRound {
  final int roundNumber;
  final List<String> ideas;

  SubmittedRound({
    required this.roundNumber,
    required this.ideas,
  });
}

class MemberSessionScreen extends StatefulWidget {
  const MemberSessionScreen({super.key});

  @override
  State<MemberSessionScreen> createState() => _MemberSessionScreenState();
}

class _MemberSessionScreenState extends State<MemberSessionScreen> {
  // 6-3-5 temel parametreleri
  final int _totalRounds = 6;
  final Duration _roundDuration = const Duration(minutes: 5);
  final int _ideasPerRound = 3;

  late int _currentRound;
  late int _remainingSeconds;
  bool _isRoundActive = true;
  bool _hasSubmittedThisRound = false;

  Timer? _timer;

  late final List<TextEditingController> _ideaControllers;

  final List<SubmittedRound> _submittedRounds = [];

  @override
  void initState() {
    super.initState();
    _currentRound = 1;
    _remainingSeconds = _roundDuration.inSeconds;
    _ideaControllers =
        List.generate(_ideasPerRound, (_) => TextEditingController());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ideaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _roundDuration.inSeconds;
      _isRoundActive = true;
      _hasSubmittedThisRound = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRoundActive = false;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

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
    return (_roundDuration.inSeconds - _remainingSeconds) / total;
  }

  void _onSubmitIdeas() {
    if (!_isRoundActive || _hasSubmittedThisRound) return;

    final ideas = _ideaControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (ideas.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir fikir yazın.'),
          ),
        );
      return;
    }

    setState(() {
      _submittedRounds.add(
        SubmittedRound(
          roundNumber: _currentRound,
          ideas: ideas,
        ),
      );
      _hasSubmittedThisRound = true;
      _isRoundActive = false;
    });
    _timer?.cancel();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Round $_currentRound için fikirler gönderildi. Diğer katılımcılarla değişim bekleniyor...',
          ),
        ),
      );
  }

  void _onNextRoundDebug() {
    // Gerçek hayatta bu next round olayı WebSocket'ten (leader'dan) gelecek.
    if (_currentRound >= _totalRounds) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tüm roundlar tamamlandı. Oturum sona erdi.'),
          ),
        );
      return;
    }

    setState(() {
      _currentRound++;
      for (final c in _ideaControllers) {
        c.clear();
      }
      _hasSubmittedThisRound = false;
      _isRoundActive = true;
    });
    _startTimer();
  }

  Widget _buildRoundProgressBar() {
    final theme = Theme.of(context);
    final progress = _roundProgress().clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round $_currentRound / $_totalRounds',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isRoundActive
              ? 'Bu round için 3 yeni fikir yazın.'
              : _hasSubmittedThisRound
                  ? 'Fikirlerin gönderildi, bir sonraki round bekleniyor.'
                  : 'Round durduruldu. Devam etmek için bir sonraki roundu bekleyin.',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRemainingTime(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isRoundActive ? 'Kalan süre' : 'Round bitti',
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
    );
  }

  Widget _buildIdeaSlot(int index) {
    final theme = Theme.of(context);
    final controller = _ideaControllers[index];
    final isDisabled = !_isRoundActive || _hasSubmittedThisRound;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Idea slot ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (controller.text.trim().isNotEmpty)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                enabled: !isDisabled,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Bu slot için fikrini yaz...',
                  isDense: true,
                ),
                onChanged: (_) {
                  setState(() {
                    // sadece UI yeniden çizimi için
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousRounds() {
    final theme = Theme.of(context);

    if (_submittedRounds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Henüz tamamlanmış round yok. Gönderdiğiniz fikirler burada özetlenecek.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final round in _submittedRounds.reversed)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${round.roundNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...round.ideas.asMap().entries.map(
                  (entry) {
                    final i = entry.key;
                    final text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• Idea ${i + 1}: $text',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoundDots() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalRounds, (index) {
        final roundNumber = index + 1;
        final isCompleted =
            _submittedRounds.any((r) => r.roundNumber == roundNumber);
        final isCurrent = roundNumber == _currentRound;

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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: icon == null
              ? const SizedBox.shrink()
              : Icon(
                  icon,
                  size: 14,
                  color: isCurrent ? Colors.white : Colors.white,
                ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSessionFinished = _currentRound >= _totalRounds && !_isRoundActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Session (6-3-5)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Round dots
            const SizedBox(height: 8),
            _buildRoundDots(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoundProgressBar(),
                    const SizedBox(height: 16),
                    Text(
                      'Bu rounddaki fikirlerim',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _ideasPerRound; i++) _buildIdeaSlot(i),
                    const SizedBox(height: 16),
                    Text(
                      'Önceki roundlardan fikirlerim',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPreviousRounds(),
                    const SizedBox(height: 24),
                    Text(
                      'Not: Gerçek oturumda round başlangıcı / bitişi ve “next round” olayları Team Leader tarafından yönetilecek ve WebSocket ile senkronize olacak. Bu ekran şu an sadece 6-3-5 akışını simüle ediyor.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (!_isRoundActive || _hasSubmittedThisRound)
                          ? null
                          : _onSubmitIdeas,
                      icon: const Icon(Icons.send),
                      label: Text(
                        _hasSubmittedThisRound
                            ? 'Fikirler gönderildi'
                            : 'Bu rounddaki fikirleri gönder',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // DEBUG button – gerçek app'te WebSocket event ile değişecek
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: isSessionFinished ? null : _onNextRoundDebug,
                      icon: const Icon(Icons.skip_next),
                      label: Text(
                        isSessionFinished
                            ? 'Tüm roundlar tamamlandı'
                            : 'Bir sonraki rounda geç (debug)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
