import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_http_transport.dart';
import 'gemini_native_request_payload_builder.dart';
import 'gemini_native_response_parser.dart';
import 'gemini_native_route_resolver.dart';
import 'gemini_native_stream_adapter.dart';
import 'system_proxy_resolver.dart';

class GeminiNativeLlmGateway extends LlmGateway {
  GeminiNativeLlmGateway({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    Duration? timeout,
    String proxyRule = '',
    String proxyUsername = '',
    String proxyPassword = '',
    bool transportRetryEnabled = true,
    int transportRetryAttempts = 2,
    SystemProxyResolver? systemProxyResolver,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _apiKey = apiKey,
       _modelId = modelId,
       _transport = GatewayHttpTransport(
         timeout: timeout ?? const Duration(seconds: 90),
         proxyRule: proxyRule.trim(),
         proxyUsername: proxyUsername.trim(),
         proxyPassword: proxyPassword,
         transportRetryEnabled: transportRetryEnabled,
         transportRetryAttempts: transportRetryAttempts.clamp(0, 5),
         systemProxyResolver: systemProxyResolver ?? const SystemProxyResolver(),
       );

  factory GeminiNativeLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return GeminiNativeLlmGateway(
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      modelId: provider.modelId,
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
  final String _modelId;
  final GatewayHttpTransport _transport;
  final GeminiNativeRouteResolver _routeResolver =
      const GeminiNativeRouteResolver();
  final GeminiNativeRequestPayloadBuilder _payloadBuilder =
      const GeminiNativeRequestPayloadBuilder();
  final GeminiNativeStreamAdapter _streamAdapter =
      GeminiNativeStreamAdapter();
  final GeminiNativeResponseParser _responseParser =
      const GeminiNativeResponseParser();

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: Gemini native 单独按 generateContent / streamGenerateContent 处理，不借用 OpenAI-compatible 的 route 解析。
    final apiMode = ValueReaders.stringValue(
      request.options['api_mode'],
      ProviderProfileConstants.apiModeGenerateContent,
    );
    final routeResolution = _routeResolver.resolve(apiMode: apiMode);
    final requestUri = _routeResolver.resolveRequestUri(
      _baseUrl,
      modelId: _modelId,
      apiMode: routeResolution.apiMode,
    );
    return _transport.execute<JsonMap>(
      requestUri: requestUri,
      cancellationToken: cancellationToken,
      onCancelled: GatewayHttpTransport.cancelledChatResult,
      shouldRetryTransportError: _shouldRetryTransportError,
      writeRequest: (httpRequest) {
        httpRequest.headers.contentType = ContentType.json;
        if (_apiKey.trim().isNotEmpty) {
          httpRequest.headers.set('x-goog-api-key', _apiKey);
          httpRequest.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_apiKey',
          );
        }
        final runtimeRequest = ChatRequest(
          modelId: request.modelId,
          messages: request.messages,
          tools: request.tools,
          options: _normalizeOptions(request.options, routeResolution.apiMode),
          attachments: request.attachments,
          capability: request.capability,
        );
        final payload = _payloadBuilder.build(runtimeRequest);
        httpRequest.write(jsonEncode(payload));
      },
      handleResponse: (response, responseUri, cancellationScope) async {
        if (_streamAdapter.responseMayStream(response, request.options)) {
          return _streamAdapter.parseHttpStream(
            response,
            responseUri,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
        }
        final body = await response.transform(utf8.decoder).join();
        if (cancellationScope.isCancellationRequested) {
          return GatewayHttpTransport.cancelledChatResult();
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Gemini 模型请求失败(${response.statusCode}): $body',
            uri: responseUri,
          );
        }
        if (_streamAdapter.looksLikeEventStream(body)) {
          return _streamAdapter.parseEventStreamBody(
            body,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
        }
        return _responseParser.parseBody(body);
      },
    );
  }

  static String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，避免后续拼接时出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  JsonMap _normalizeOptions(JsonMap options, String apiMode) {
    // 中文注释: Gemini native 请求只保留正式 route 投影和生成配置相关字段。
    final result = ValueReaders.deepCopyMap(options);
    result['api_mode'] = apiMode;
    result['protocol_kind'] = ProtocolKind.geminiNative.id;
    result['route_family'] = _routeResolver.resolve(apiMode: apiMode).routeFamily.id;
    return result;
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
    return message.contains('502') ||
        message.contains('503') ||
        message.contains('504') ||
        message.contains('520') ||
        message.contains('522') ||
        message.contains('524');
  }
}
