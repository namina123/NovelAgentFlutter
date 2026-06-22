import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/settings/application/services/provider_connection_probe_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

// 中文注释: 这组测试确认"测试连接"现在真的联网，并能把常见失败映射成用户能懂的人话，
// 不再用本地表单校验冒充联网成功。

class _FakeGateway extends LlmGateway {
  _FakeGateway(this.behavior);

  final Future<JsonMap> Function() behavior;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    return behavior();
  }
}

ProviderEndpointSettings _provider() {
  return const ProviderEndpointSettings(
    id: 'probe_test',
    title: '探测测试',
    protocol: 'openai_compatible',
    baseUrl: 'https://example.test/v1',
    apiKey: 'sk-test',
    modelId: 'gpt-test',
    description: '',
  );
}

void main() {
  group('ProviderConnectionProbeService', () {
    test('reports success when the gateway returns a readable response', () async {
      final service = ProviderConnectionProbeService(
        gatewayFactory: (_, __) => _FakeGateway(
          () async => <String, Object?>{'content': 'pong'},
        ),
      );

      final result = await service.probe(provider: _provider(), modelId: 'gpt-test');

      expect(result.success, isTrue);
      expect(result.summary, contains('通过'));
      expect(result.detail, contains('example.test'));
    });

    test('classifies a socket error as unreachable', () async {
      final service = ProviderConnectionProbeService(
        gatewayFactory: (_, __) => _FakeGateway(
          () async => throw const SocketException('connection refused'),
        ),
      );

      final result = await service.probe(provider: _provider(), modelId: 'gpt-test');

      expect(result.success, isFalse);
      expect(result.summary, contains('无法连接'));
    });

    test('classifies a 401 as an auth failure', () async {
      final service = ProviderConnectionProbeService(
        gatewayFactory: (_, __) => _FakeGateway(
          () async => throw Exception('HTTP 401 Unauthorized'),
        ),
      );

      final result = await service.probe(provider: _provider(), modelId: 'gpt-test');

      expect(result.success, isFalse);
      expect(result.summary, contains('鉴权失败'));
    });

    test('classifies a timeout as unreachable within the time limit', () async {
      final service = ProviderConnectionProbeService(
        gatewayFactory: (_, __) => _FakeGateway(
          () async => throw TimeoutException('timed out'),
        ),
      );

      final result = await service.probe(provider: _provider(), modelId: 'gpt-test');

      expect(result.success, isFalse);
      expect(result.summary, contains('超时'));
    });

    test('describeConnectionError maps the common shapes to human text', () {
      expect(
        ProviderConnectionProbeService.describeConnectionError(
          TimeoutException('x'),
        ),
        contains('超时'),
      );
      expect(
        ProviderConnectionProbeService.describeConnectionError(
          const SocketException('x'),
        ),
        contains('无法连接'),
      );
      expect(
        ProviderConnectionProbeService.describeConnectionError(
          Exception('HTTP 403 Forbidden'),
        ),
        contains('权限'),
      );
      expect(
        ProviderConnectionProbeService.describeConnectionError(
          Exception('HTTP 404 Not Found'),
        ),
        contains('404'),
      );
      expect(
        ProviderConnectionProbeService.describeConnectionError(
          Exception('some other failure'),
        ),
        contains('联网验证失败'),
      );
    });
  });
}
