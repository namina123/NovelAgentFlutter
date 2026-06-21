import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'anthropic_messages_request_payload_builder.dart';
import 'anthropic_messages_route_resolver.dart';
import 'anthropic_messages_stream_adapter.dart';
import 'gateway_http_transport.dart';
import 'provider_request_route_resolver.dart';
import 'system_proxy_resolver.dart';

class AnthropicLlmGateway extends LlmGateway {
  AnthropicLlmGateway({
    required String baseUrl,
    required String apiKey,
    String protocol = ProviderProfileConstants.kindAnthropicCompatible,
    Duration? timeout,
    String proxyRule = '',
    String proxyUsername = '',
    String proxyPassword = '',
    bool transportRetryEnabled = true,
    int transportRetryAttempts = 2,
    SystemProxyResolver? systemProxyResolver,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _apiKey = apiKey,
       _protocol = protocol,
       _transport = GatewayHttpTransport(
         timeout: timeout ?? const Duration(seconds: 90),
         proxyRule: proxyRule.trim(),
         proxyUsername: proxyUsername.trim(),
         proxyPassword: proxyPassword,
         transportRetryEnabled: transportRetryEnabled,
         transportRetryAttempts: transportRetryAttempts.clamp(0, 5),
         systemProxyResolver: systemProxyResolver ?? const SystemProxyResolver(),
       );

  factory AnthropicLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return AnthropicLlmGateway(
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      protocol: provider.protocol,
      timeout: GatewayNetworkSettings.timeoutFromNetworkSettings(
        networkSettings,
      ),
      proxyRule: GatewayNetworkSettings.proxyRuleFromNetworkSettings(
        networkSettings,
      ),
      proxyUsername: '${networkSettings['proxy_username'] ?? ''}',
      proxyPassword: '${networkSettings['proxy_password'] ?? ''}',
      transportRetryEnabled:
          GatewayNetworkSettings.transportRetryEnabledFromNetworkSettings(
        networkSettings,
      ),
      transportRetryAttempts:
          GatewayNetworkSettings.transportRetryAttemptsFromNetworkSettings(
        networkSettings,
      ),
    );
  }

  final String _baseUrl;
  final String _apiKey;
  final String _protocol;
  final GatewayHttpTransport _transport;
  final ProviderRequestRouteResolver _requestRouteResolver =
      ProviderRequestRouteResolver();
  final AnthropicMessagesRouteResolver _routeResolver =
      const AnthropicMessagesRouteResolver();
  final AnthropicMessagesRequestPayloadBuilder _payloadBuilder =
      const AnthropicMessagesRequestPayloadBuilder();
  final AnthropicMessagesStreamAdapter _streamAdapter =
      AnthropicMessagesStreamAdapter();

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: Anthropic gateway 现在只负责 transport 装配和请求编排，消息/流式语义下沉到 protocol adapter。
    final routeResolution = _requestRouteResolver.resolve(
      protocol: _protocol,
      apiMode: ValueReaders.stringValue(request.options['api_mode']),
    );
    if (routeResolution.routeFamily != RequestRouteFamily.messages) {
      throw UnsupportedError(
        'Anthropic gateway 只接受 messages 路由族。',
      );
    }
    final requestUri = _routeResolver.resolveRequestUri(_baseUrl);
    return _transport.execute<JsonMap>(
      requestUri: requestUri,
      cancellationToken: cancellationToken,
      onCancelled: GatewayHttpTransport.cancelledChatResult,
      shouldRetryTransportError: _shouldRetryTransportError,
      writeRequest: (httpRequest) {
        httpRequest.headers.contentType = ContentType.json;
        if (_apiKey.trim().isNotEmpty) {
          httpRequest.headers.set('x-api-key', _apiKey);
        }
        httpRequest.headers.set('anthropic-version', '2023-06-01');
        if (request.options['stream'] == true) {
          httpRequest.headers.set(
            HttpHeaders.acceptHeader,
            'text/event-stream',
          );
        }
        httpRequest.write(json.encode(_payloadBuilder.build(request)));
      },
      handleResponse: (response, responseUri, cancellationScope) {
        return _streamAdapter.handleResponse(
          response: response,
          requestUri: responseUri,
          request: request,
          cancellationToken: cancellationToken,
          onStreamUpdate: onStreamUpdate,
          cancellationScope: cancellationScope,
          retryRequest: _retryRequest,
        );
      },
    );
  }

  Future<JsonMap> _retryRequest(
    ChatRequest request, {
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 重试仍复用同一个 gateway 入口，避免 retry 变成第二条协议主链。
    return requestChat(
      request: request,
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  static String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，避免后续拼接请求路径时出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  bool _shouldRetryTransportError(Object error) {
    // 中文注释: 这里只对典型瞬时传输层故障做自动重试，避免把明确的业务错误误当成网络抖动。
    if (error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }
    final message = '$error'.toLowerCase();
    if (message.contains('connection closed before full header')) {
      return true;
    }
    if (message.contains('connection reset') ||
        message.contains('connection terminated') ||
        message.contains('broken pipe')) {
      return true;
    }
    if (message.contains('中断')) {
      return true;
    }
    return message.contains('502') ||
        message.contains('503') ||
        message.contains('504') ||
        message.contains('520') ||
        message.contains('522') ||
        message.contains('524');
  }
}
