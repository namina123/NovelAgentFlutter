import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('RevisionDiffPreviewService', () {
    test('builds changed pair with preview', () {
      // 中文注释: 这里验证 diff 预览会标出变更行，并为后续报告提供可读摘要。
      final service = RevisionDiffPreviewService();

      final pair = service.buildPair(
        targetPath: 'chapters/ch1.md',
        backupPath: 'backups/ch1.bak',
        beforeText: 'hello\nworld',
        afterText: 'hello\nnovel',
      );

      expect(pair['status'], 'changed');
      expect(pair['changed_line_estimate'], 1);
      expect((pair['preview'] as String), contains('@@ line 2 @@'));
    });
  });
}
