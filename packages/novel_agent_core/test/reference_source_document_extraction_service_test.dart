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
  });
}
