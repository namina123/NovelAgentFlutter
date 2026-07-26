import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_http_transport.dart';
import 'openai_chat_request_payload_builder.dart';
import 'openai_chat_response_parser.dart';
import 'openai_chat_route_resolver.dart';
import 'openai_chat_stream_adapter.dart';
import 'openai_responses_request_payload_builder.dart';
import 'openai_responses_response_parser.dart';
import 'openai_responses_route_resolver.dart';
import 'openai_responses_stream_adapter.dart';
import 'provider_request_route_resolver.dart';
import 'system_proxy_resolver.dart';

class OpenAiLlmGateway extends LlmGateway {
  OpenAiLlmGateway({
    required String baseUrl,
    required String apiKey,
    String protocol = ProviderProfileConstants.kindOpenAiCompatible,
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
         systemProxyResolver:
             systemProxyResolver ?? const SystemProxyResolver(),
       );

  factory OpenAiLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return OpenAiLlmGateway(
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
  final OpenAiChatRouteResolver _routeResolver =
      const OpenAiChatRouteResolver();
  final OpenAiChatStreamAdapter _streamAdapter = OpenAiChatStreamAdapter();
  final OpenAiChatResponseParser _jsonResponseParser =
      const OpenAiChatResponseParser();
  final OpenAiChatRequestPayloadBuilder _payloadBuilder =
      const OpenAiChatRequestPayloadBuilder();
  final OpenAiResponsesRouteResolver _responsesRouteResolver =
      const OpenAiResponsesRouteResolver();
  final OpenAiResponsesStreamAdapter _responsesStreamAdapter =
      OpenAiResponsesStreamAdapter();
  final OpenAiResponsesResponseParser _responsesResponseParser =
      const OpenAiResponsesResponseParser();
  final OpenAiResponsesRequestPayloadBuilder _responsesPayloadBuilder =
      const OpenAiResponsesRequestPayloadBuilder();

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 这里按 api_mode 真正分流 Chat 与 Responses，避免两个 endpoint 再共用同一套协议语义。
    final apiMode = ValueReaders.stringValue(
      request.options['api_mode'],
      ProviderProfileConstants.apiModeChat,
    );
    final routeResolution = _requestRouteResolver.resolve(
      protocol: _protocol,
      apiMode: apiMode,
    );
    final isResponsesRoute =
        routeResolution.routeFamily == RequestRouteFamily.responses;
    final requestUri = isResponsesRoute
        ? _responsesRouteResolver.resolveRequestUri(_baseUrl)
        : _routeResolver.resolveRequestUri(
            _baseUrl,
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
          httpRequest.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_apiKey',
          );
        }
        final payload = isResponsesRoute
            ? _responsesPayloadBuilder.build(request)
            : _payloadBuilder.build(request);
        httpRequest.write(jsonEncode(payload));
      },
      handleResponse: (response, requestUri, cancellationScope) async {
        if (isResponsesRoute) {
          if (_responsesStreamAdapter.responseMayStream(
            response,
            request.options,
          )) {
            return _responsesStreamAdapter.parseHttpStream(
              response,
              requestUri,
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
              '模型请求失败(${response.statusCode}): $body',
              uri: requestUri,
            );
          }
          if (_responsesStreamAdapter.looksLikeEventStream(body)) {
            return _responsesStreamAdapter.parseEventStreamBody(
              body,
              cancellationScope: cancellationScope,
              onStreamUpdate: onStreamUpdate,
            );
          }
          return _responsesResponseParser.parseBody(body);
        }
        if (_streamAdapter.responseMayStream(response, request.options)) {
          return _streamAdapter.parseHttpStream(
            response,
            requestUri,
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
            '模型请求失败(${response.statusCode}): $body',
            uri: requestUri,
          );
        }
        if (_streamAdapter.looksLikeEventStream(body)) {
          return _streamAdapter.parseEventStreamBody(
            body,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
        }
        return _jsonResponseParser.parseBody(body);
      },
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
    if (message.contains('流式响应在完成前被中断')) {
      return true;
    }
    return message.contains('模型请求失败(502)') ||
        message.contains('模型请求失败(503)') ||
        message.contains('模型请求失败(504)') ||
        message.contains('模型请求失败(520)') ||
        message.contains('模型请求失败(522)') ||
        message.contains('模型请求失败(524)');
  }
}
