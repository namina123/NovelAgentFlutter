import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceDocumentExtractionService', () {
    test(
      'extracts structured entries from source document with Chinese target language',
      () {
        const service = ReferenceSourceDocumentExtractionService();
        final result = service.extract(
          const ReferenceSourceDocumentIngestionRequest(
            sourceText: '''
CHAPTER ONE
Mr and Mrs Dursley, of number four, Privet Drive, were proud to say that they were perfectly normal.

CHAPTER TWO
Harry Potter lived in the cupboard under the stairs and watched the letters arrive.

CHAPTER THREE
Hagrid knocked down the door and told Harry that Hogwarts was waiting for him.
''',
            sourceTitle: 'Harry Potter Sample.txt',
            packageId: 'pkg_hp_sample',
            packageKind: ReferencePackageKinds.referenceWorkPackage,
            displayName: '哈利波特样本文稿包',
            packageVersionId: 'v1',
            versionLabel: '1.0.0',
            createdAt: '2026-06-07T13:00:00Z',
          ),
        );

        expect(result.targetLanguage, 'zh-CN');
        expect(result.sourceLanguage, 'en');
        expect(result.generatedEntryCount, greaterThanOrEqualTo(5));
        expect(result.snapshot.packageRecord.targetLanguage, 'zh-CN');
        expect(
          result.snapshot.entries.any(
            (entry) => entry.entryKind == ReferenceEntryKinds.styleTechnique,
          ),
          isTrue,
        );
        expect(
          result.snapshot.entries.first.summary.contains('章节片段') ||
              result.snapshot.entries.first.summary.contains('源文档'),
          isTrue,
        );
      },
    );

    test('emits narrative clue entries from shared source analysis substrate', () {
      const service = ReferenceSourceDocumentExtractionService();
      final result = service.extract(
        const ReferenceSourceDocumentIngestionRequest(
          sourceText: '''
第一章 港口风暴
林砚在港口撞见黑潮议会的密使，议长的命令让更大的追捕就要开始。

第二章 议会阴影
林砚与议长的第一次正面交锋，让黑潮议会的真正规则逐渐浮出水面。

第三章 真相回声
林砚意识到港口航线与城邦权力之间存在更深的契约与禁忌。
''',
          sourceTitle: 'Harbor Story Sample.txt',
          packageId: 'pkg_harbor_sample',
          packageKind: ReferencePackageKinds.referenceWorkPackage,
          displayName: '港口样本文稿包',
          packageVersionId: 'v1',
          versionLabel: '1.0.0',
          createdAt: '2026-06-20T08:00:00Z',
        ),
      );

      final namespaces = result.snapshot.entries
          .map((entry) => entry.entryNamespace)
          .toSet();
      expect(namespaces, contains('character_clues'));
      expect(namespaces, contains('relationship_clues'));
      expect(namespaces, contains('timeline_clues'));
      expect(
        result.snapshot.entries.any(
          (entry) =>
              entry.entryNamespace == 'world_rule_clues' ||
              entry.entryNamespace == 'foreshadow_clues',
        ),
        isTrue,
      );
    });
  });
}
