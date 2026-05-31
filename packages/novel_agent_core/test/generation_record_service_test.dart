import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationRecordService', () {
    test('sanitizes provider and builds summary record', () {
      // 中文注释: 这里验证生成记录会对 provider 脱敏，并只保留上下文包的轻量摘要。
      final service = GenerationRecordService();

      final record = service.buildRecord(<String, Object?>{
        'run_id': 'run_1',
        'provider': <String, Object?>{
          'api_key': 'secret',
          'base_url': 'https://api.example.com',
        },
        'prompt': '写一个很长很长的提示词',
        'context_pack': <String, Object?>{
          'id': 'cp_1',
          'summary': '1000/2000',
          'intent': 'draft',
          'budget_chars': 2000,
          'used_chars': 1000,
          'sections': <Object?>[
            <String, Object?>{'title': '项目概况'},
          ],
          'omitted_sections': <Object?>[],
        },
        'output_paths': <Object?>['chapters/ch1.md'],
      }, createdAt: '2026-05-23T00:00:00Z');

      expect((record['provider'] as Map<String, Object?>)['api_key'], '***');
      expect(
        ((record['context_pack_summary']
                    as Map<String, Object?>)['section_titles']
                as List<String>)
            .first,
        '项目概况',
      );
      expect(
        service.generationRunFilePath(record, dateCompact: '20260523'),
        contains('runs/20260523/'),
      );
    });
  });
}

