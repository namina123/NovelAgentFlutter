import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentProfileNormalizerService sampling params', () {
    test('preserves top-level sampling overrides (regression for C3 rumor)', () {
      // 中文注释: 曾有审计断言“内置协作智能体把 temperature 放顶层会被归一化器丢弃，被默认值覆盖”。
      // 实际上 extractExtensions 会把顶层 temperature 拉进 extensions，extensionSampling 会保留它。
      // 这里直接复现顶层采样参数场景，确认 0.7 / 0.9 不会被默认 0.85 / 0.95 覆盖。
      final service = AgentProfileNormalizerService();
      final normalized = service.normalizeAgentProfile(<String, Object?>{
        'id': 'editor_in_chief',
        'name': '主编',
        'role': '统筹',
        'system_prompt': '你是主编。',
        'temperature': 0.7,
        'top_p': 0.9,
        'top_k': 40,
      });

      expect(ValueReaders.doubleValue(normalized['temperature']), 0.7);
      expect(ValueReaders.doubleValue(normalized['top_p']), 0.9);
      expect(ValueReaders.intValue(normalized['top_k']), 40);
    });

    test('builtin collaborator catalog keeps each preset sampling tuning', () {
      // 中文注释: 直接经内置目录验证：editor_in_chief 0.7 / writer 0.95 必须原样保留。
      final catalog = BuiltinCollaboratorCatalogService();
      final profiles = catalog.optionalCollaboratorProfiles();
      final byId = <String, JsonMap>{
        for (final profile in profiles)
          ValueReaders.stringValue(profile['id']): profile,
      };
      final editor = byId['editor_in_chief']!;
      expect(ValueReaders.doubleValue(editor['temperature']), 0.7);
      expect(ValueReaders.doubleValue(editor['top_p']), 0.9);
      final writer = byId['writer']!;
      expect(ValueReaders.doubleValue(writer['temperature']), 0.95);
      expect(ValueReaders.doubleValue(writer['top_p']), 0.97);
    });
  });
}
