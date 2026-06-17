import 'dart:async';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'openai_gateway_cancellation_scope.dart';
import 'system_proxy_resolver.dart';

class GatewayHttpTransport {
  const GatewayHttpTransport({
    required Duration timeout,
    required String proxyRule,
    required String proxyUsername,
    required String proxyPassword,
    required bool transportRetryEnabled,
    required int transportRetryAttempts,
    required SystemProxyResolver systemProxyResolver,
  }) : _timeout = timeout,
       _proxyRule = proxyRule,
       _proxyUsername = proxyUsername,
       _proxyPassword = proxyPassword,
       _transportRetryEnabled = transportRetryEnabled,
       _transportRetryAttempts = transportRetryAttempts,
       _systemProxyResolver = systemProxyResolver;

  final Duration _timeout;
  final String _proxyRule;
  final String _proxyUsername;
  final String _proxyPassword;
  final bool _transportRetryEnabled;
  final int _transportRetryAttempts;
  final SystemProxyResolver _systemProxyResolver;

  Future<T> execute<T>({
    required Uri requestUri,
    required DraftGenerationCancellationToken? cancellationToken,
    required FutureOr<void> Function(HttpClientRequest request) writeRequest,
    required Future<T> Function(
      HttpClientResponse response,
      Uri requestUri,
      OpenAiGatewayCancellationScope cancellationScope,
    )
    handleResponse,
    required bool Function(Object error) shouldRetryTransportError,
    required T Function() onCancelled,
  }) async {
    final totalAttempts = _transportRetryEnabled
        ? _transportRetryAttempts + 1
        : 1;
    for (var attempt = 1; attempt <= totalAttempts; attempt += 1) {
      final client = HttpClient()..connectionTimeout = _timeout;
      final cancellationScope = OpenAiGatewayCancellationScope(
        client: client,
        cancellationToken: cancellationToken,
      )..bind();
      try {
        if (cancellationScope.isCancellationRequested) {
          return onCancelled();
        }
        await _configureProxy(client, requestUri);
        final httpRequest = await client.postUrl(requestUri).timeout(_timeout);
        if (cancellationScope.isCancellationRequested) {
          httpRequest.abort();
          return onCancelled();
        }
        await writeRequest(httpRequest);
        final response = await httpRequest.close().timeout(_timeout);
        if (cancellationScope.isCancellationRequested) {
          return onCancelled();
        }
        return await handleResponse(response, requestUri, cancellationScope);
      } catch (error) {
        if (cancellationScope.isCancellationRequested) {
          return onCancelled();
        }
        if (attempt >= totalAttempts || !shouldRetryTransportError(error)) {
          rethrow;
        }
        await Future<void>.delayed(_retryDelay(attempt));
      } finally {
        cancellationScope.dispose();
        client.close(force: true);
      }
    }
    throw StateError('unreachable');
  }

  Future<void> _configureProxy(HttpClient client, Uri requestUri) async {
    if (_shouldBypassProxy(requestUri)) {
      // 中文注释: 本地 loopback 请求必须显式直连，否则默认系统代理会把测试流量误导到外部代理层。
      client.findProxy = (_) => 'DIRECT';
      return;
    }
    final proxyRule = _proxyRule.isNotEmpty
        ? _proxyRule
        : (await _systemProxyResolver.resolveFor(requestUri)).trim();
    if (proxyRule.isEmpty || proxyRule.toUpperCase() == 'DIRECT') {
      return;
    }
    client.findProxy = (_) => proxyRule;
    if (_proxyUsername.isEmpty) {
      return;
    }
    client.authenticateProxy = (host, port, scheme, realm) async {
      client.addProxyCredentials(
        host,
        port,
        realm ?? '',
        HttpClientBasicCredentials(_proxyUsername, _proxyPassword),
      );
      return true;
    };
  }

  bool _shouldBypassProxy(Uri requestUri) {
    final host = requestUri.host.trim().toLowerCase();
    if (host.isEmpty) {
      return true;
    }
    if (host == 'localhost') {
      return true;
    }
    return InternetAddress.tryParse(host)?.isLoopback ?? false;
  }

  Duration _retryDelay(int attempt) {
    final milliseconds = 800 * attempt;
    return Duration(milliseconds: milliseconds);
  }

  static JsonMap cancelledChatResult() {
    return const <String, Object?>{
      'ok': true,
      'content': '',
      'reasoning_content': '',
      'message': <String, Object?>{
        'role': 'assistant',
        'content': '',
        'tool_calls': <Object?>[],
      },
      'tool_calls': <Object?>[],
      'raw_response': <String, Object?>{},
    };
  }
}

class GatewayNetworkSettings {
  const GatewayNetworkSettings._();

  static Duration timeoutFromNetworkSettings(JsonMap networkSettings) {
    final seconds = int.tryParse(
      '${networkSettings['timeout_seconds'] ?? ''}'.trim(),
    );
    if (seconds == null || seconds <= 0) {
      return const Duration(seconds: 90);
    }
    return Duration(seconds: seconds);
  }

  static String proxyRuleFromNetworkSettings(JsonMap networkSettings) {
    final mode = '${networkSettings['proxy_mode'] ?? 'system'}'
        .trim()
        .toLowerCase();
    if (mode != 'custom') {
      return '';
    }
    final protocol = '${networkSettings['proxy_protocol'] ?? ''}'
        .trim()
        .toLowerCase();
    final host = '${networkSettings['proxy_host'] ?? ''}'.trim();
    final port = '${networkSettings['proxy_port'] ?? ''}'.trim();
    if (host.isEmpty || port.isEmpty) {
      return '';
    }
    if (protocol == 'socks5') {
      return 'SOCKS $host:$port';
    }
    return 'PROXY $host:$port';
  }

  static bool transportRetryEnabledFromNetworkSettings(
    JsonMap networkSettings,
  ) {
    if (!networkSettings.containsKey('transport_retry_enabled')) {
      return true;
    }
    return networkSettings['transport_retry_enabled'] == true;
  }

  static int transportRetryAttemptsFromNetworkSettings(
    JsonMap networkSettings,
  ) {
    final raw = '${networkSettings['transport_retry_attempts'] ?? ''}'.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return 2;
    }
    return parsed.clamp(0, 5);
  }
}
