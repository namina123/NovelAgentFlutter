class ConversationRequestCancellationToken {
  bool _isCancellationRequested = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancellationRequested => _isCancellationRequested;

  bool cancel() {
    // 中文注释: 取消令牌当前只做合作式传播，不直接触达底层 gateway。
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
    // 中文注释: 新监听器在取消已发生时立即回放，避免后绑定方漏掉状态。
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
