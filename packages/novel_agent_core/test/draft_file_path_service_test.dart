import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('DraftFilePathService', () {
    test('prefers markdown heading over prompt-like title for chapter drafts', () {
      final service = DraftFilePathService();

      final path = service.buildPath(
        title: '继续写第三章',
        content: '# 第03章 雪夜折返\n\n正文。',
      );

      expect(path, 'chapters/第03章_雪夜折返.md');
    });

    test('falls back to timestamp naming for generic untitled content', () {
      final service = DraftFilePathService();

      final path = service.buildPath(
        title: '',
        content: '',
        contentType: 'chapter',
        now: DateTime(2026, 6, 14, 9, 8, 7),
      );

      expect(path, 'chapters/20260614_090807.md');
    });

    test('routes sample and analysis drafts into dedicated content roots', () {
      final service = DraftFilePathService();

      final samplePath = service.buildPath(
        title: '样章：第01章',
        content: '# 第01章 开篇\n\n正文。',
        contentType: 'sample',
        now: DateTime(2026, 6, 14, 9, 8, 7),
      );
      final analysisPath = service.buildPath(
        title: '第01章 连续性分析',
        content: '# 分析\n\n结论。',
        contentType: 'analysis',
        now: DateTime(2026, 6, 14, 9, 8, 7),
      );

      expect(samplePath, 'samples/20260614_090807_样章_第01章.md');
      expect(analysisPath, 'analysis/20260614_090807_第01章_连续性分析.md');
    });
  });
}
