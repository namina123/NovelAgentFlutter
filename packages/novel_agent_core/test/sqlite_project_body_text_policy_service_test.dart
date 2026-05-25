import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteProjectBodyTextPolicyService', () {
    const service = SqliteProjectBodyTextPolicyService();

    test('accepts plain text body documents', () {
      // 中文注释: SQLite 正文允许普通纯文本，这里验证不会把正常小说正文误判成 Markdown blob。
      const document = SqliteProjectBodyTextDocument(
        documentId: 'chapter-001',
        documentKind: 'chapter',
        title: '第一章',
        storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
        plainText: '夜色沉了下来，主角第一次走进旧城区。\n\n风从巷口灌进来。',
      );

      expect(service.violationOf(document), isNull);
    });

    test('rejects markdown blob as plain text body storage', () {
      // 中文注释: 这里明确锁死“整篇 Markdown 文档串不能直接当正文主存储”的项目约束。
      const document = SqliteProjectBodyTextDocument(
        documentId: 'chapter-002',
        documentKind: 'chapter',
        title: '第二章',
        storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
        plainText: '# 第二章\n\n- 小节一\n- 小节二\n',
      );

      expect(service.violationOf(document), contains('Markdown blob'));
    });

    test('accepts segmented body documents with plain text segments', () {
      // 中文注释: 分段正文是 SQLite 主正文的另一种合法表达，后续可支撑局部重写和细粒度上下文选择。
      const document = SqliteProjectBodyTextDocument(
        documentId: 'scene-001',
        documentKind: 'scene',
        title: '夜访',
        storageFormat: SqliteProjectBodyTextStorageFormat.segmentedText,
        segments: <SqliteProjectBodyTextSegment>[
          SqliteProjectBodyTextSegment(
            segmentId: 'seg-001',
            ordinal: 1,
            text: '她在楼梯口停了一下，先听见楼上的脚步声。',
          ),
          SqliteProjectBodyTextSegment(
            segmentId: 'seg-002',
            ordinal: 2,
            text: '“你终于来了。”门后的人压低了声音。',
            segmentKind: 'dialogue',
          ),
        ],
      );

      expect(service.violationOf(document), isNull);
      expect(document.combinedText(), contains('你终于来了'));
    });
  });
}
