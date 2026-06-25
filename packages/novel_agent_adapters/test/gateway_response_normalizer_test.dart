import 'package:novel_agent_adapters/src/providers/gateway_response_normalizer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayResponseNormalizer.normalizeOpenAiToolCalls', () {
    test('parses plain JSON arguments', () {
      final calls = GatewayResponseNormalizer.normalizeOpenAiToolCalls(
        <Object?>[
          <String, Object?>{
            'id': 'call_1',
            'function': <String, Object?>{
              'name': 'read_project_file',
              'arguments': '{"relative_path":"chapters/a.md"}',
            },
          },
        ],
      );
      expect(calls, hasLength(1));
      final args = ValueReaders.mapValue(calls.first['arguments']);
      expect(ValueReaders.stringValue(args['relative_path']), 'chapters/a.md');
    });

    test('strips markdown code fence around arguments (compat mode)', () {
      // 中文注释: 兼容模式（deepseek/qwen/第三方网关）常把 arguments 用 ```json``` 包裹，
      // 剥离后应正确解析，而不是静默清空成 {} 导致工具收到空入参。
      final calls = GatewayResponseNormalizer.normalizeOpenAiToolCalls(
        <Object?>[
          <String, Object?>{
            'id': 'call_2',
            'function': <String, Object?>{
              'name': 'write_project_file',
              'arguments': '```json\n{"relative_path":"outline/b.md"}\n```',
            },
          },
        ],
      );
      expect(calls, hasLength(1));
      final args = ValueReaders.mapValue(calls.first['arguments']);
      expect(ValueReaders.stringValue(args['relative_path']), 'outline/b.md');
      // raw_arguments 保留原始串（含代码块）供诊断。
      expect(
        ValueReaders.stringValue(calls.first['raw_arguments']),
        contains('```json'),
      );
    });

    test('returns empty map when arguments truly unparseable', () {
      final calls = GatewayResponseNormalizer.normalizeOpenAiToolCalls(
        <Object?>[
          <String, Object?>{
            'id': 'call_3',
            'function': <String, Object?>{
              'name': 'read_project_file',
              'arguments': 'totally not json',
            },
          },
        ],
      );
      expect(calls, hasLength(1));
      expect(ValueReaders.mapValue(calls.first['arguments']), isEmpty);
    });
  });
}
