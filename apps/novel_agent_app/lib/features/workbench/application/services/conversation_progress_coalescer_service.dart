import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationProgressCoalescerService {
  const ConversationProgressCoalescerService({
    this.interval = const Duration(milliseconds: 66),
  });

  final Duration interval;

  ConversationProgressCoalescerHandle bind(
    void Function(DraftGenerationProgress progress) onEmit,
  ) {
    return ConversationProgressCoalescerHandle(
      interval: interval,
      onEmit: onEmit,
    );
  }
}

class ConversationProgressCoalescerHandle {
  ConversationProgressCoalescerHandle({
    required Duration interval,
    required void Function(DraftGenerationProgress progress) onEmit,
  }) : _interval = interval,
       _onEmit = onEmit;

  final Duration _interval;
  final void Function(DraftGenerationProgress progress) _onEmit;

  DraftGenerationProgress? _pending;
  Timer? _timer;

  void schedule(DraftGenerationProgress progress) {
    _pending = progress;
    if (_timer != null) {
      return;
    }
    _timer = Timer(_interval, _flushTimerTick);
  }

  void flushNow() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    if (pending == null) {
      return;
    }
    _pending = null;
    _onEmit(pending);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void _flushTimerTick() {
    _timer = null;
    final pending = _pending;
    if (pending == null) {
      return;
    }
    _pending = null;
    _onEmit(pending);
  }
}
