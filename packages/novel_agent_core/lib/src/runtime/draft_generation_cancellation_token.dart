class DraftGenerationCancellationToken {
  bool _isCancellationRequested = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancellationRequested => _isCancellationRequested;

  bool cancel() {
    // 中文注释: core 取消令牌只表达合作式停止意图，不承担底层 IO 强制中断职责。
    if (_isCancellationRequested) {
      return false;
    }
    _isCancellationRequested = true;
    final listeners = List<void Function()>.from(_listeners);
    for (final listener in listeners) {
      listener();
    }
    return true;
  }

  void addListener(void Function() listener) {
    if (_isCancellationRequested) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }
}
