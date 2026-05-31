import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class OpenAiGatewayCancellationScope {
  OpenAiGatewayCancellationScope({
    required HttpClient client,
    required DraftGenerationCancellationToken? cancellationToken,
  }) : _client = client,
       _cancellationToken = cancellationToken;

  final HttpClient _client;
  final DraftGenerationCancellationToken? _cancellationToken;

  bool _isBound = false;
  bool _isCancellationRequested = false;

  bool get isCancellationRequested =>
      _isCancellationRequested ||
      (_cancellationToken?.isCancellationRequested ?? false);

  void bind() {
    // 中文注释: transport 侧只负责监听取消并尽快关闭连接，不向 core 暴露 HTTP 细节。
    if (_isBound) {
      return;
    }
    _isBound = true;
    _cancellationToken?.addListener(_onCancellationRequested);
    if (_cancellationToken?.isCancellationRequested ?? false) {
      _onCancellationRequested();
    }
  }

  void dispose() {
    if (!_isBound) {
      return;
    }
    _isBound = false;
    _cancellationToken?.removeListener(_onCancellationRequested);
  }

  void _onCancellationRequested() {
    _isCancellationRequested = true;
    try {
      _client.close(force: true);
    } catch (_) {
      // 中文注释: 取消时连接可能已由其他分支收尾，这里静默兜住即可。
    }
  }
}
