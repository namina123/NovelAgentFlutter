import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifestCodecService.parse tolerance', () {
    final service = ProjectManifestCodecService();

    test('returns a fallback manifest for malformed JSON instead of throwing', () {
      // 中文注释: 损坏/截断的 manifest（先前崩溃、编辑器、磁盘满）必须能兜底成可打开的普通小说，
      // 而不是抛 FormatException 炸掉项目打开（默认项目启动时自动恢复，影响最大）。
      final manifest = service.parse(
        '{ "title": "未闭合的 JSON',
        fallbackTitle: '兜底作品',
      );
      expect(manifest.title, '兜底作品');
      expect(manifest.projectType, 'novel');
    });

    test('parses well-formed JSON normally', () {
      final manifest = service.parse(
        '{"title":"正常作品","project_type":"novel"}',
      );
      expect(manifest.title, '正常作品');
    });

    test('returns fallback for empty source', () {
      final manifest = service.parse('', fallbackTitle: '空兜底');
      expect(manifest.title, '空兜底');
    });
  });
}
