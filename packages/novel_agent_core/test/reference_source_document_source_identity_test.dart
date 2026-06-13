import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceDocumentExtractionService source identity', () {
    test('source identity no longer depends on absolute path', () {
      const service = ReferenceSourceDocumentExtractionService();

      final result = service.extract(
        const ReferenceSourceDocumentIngestionRequest(
          sourceText:
              'Chapter 1\n\nMr Dursley was proud to say that he was perfectly normal.',
          sourceTitle: 'Harry Potter - Volume 1 Raw',
          sourceRef: r'D:\books\Harry Potter - Volume 1 Raw.txt',
          packageId: 'pkg-hp-v1',
          packageKind: ReferencePackageKinds.referenceWorkPackage,
          displayName: 'Harry Potter V1',
          packageVersionId: 'v1',
          versionLabel: '2026.06.08',
          createdAt: '2026-06-08T12:00:00Z',
        ),
      );

      final sourceRef =
          result.snapshot.entries.first.sourceRefs.first.sourceRef;
      final evidenceRef = result.snapshot.entries.first.evidenceRefs.first;

      expect(sourceRef.sourceIdentity.validateBasics(), isEmpty);
      expect(sourceRef.sourceKind, 'source_document_file');
      expect(
        sourceRef.sourceAssetId,
        isNot(r'D:\books\Harry Potter - Volume 1 Raw.txt'),
      );
      expect(sourceRef.localHintPath, 'Harry Potter - Volume 1 Raw.txt');
      expect(
        sourceRef.sourceIdentity.metadata['debug_local_absolute_path'],
        isNull,
      );
      expect(
        ValueReaders.stringValue(sourceRef.sourceIdentity.metadata['source_language']),
        'en',
      );
      expect(
        ValueReaders.stringValue(sourceRef.sourceIdentity.metadata['target_language']),
        'zh-CN',
      );
      expect(
        sourceRef.resolverUri,
        'workspace-file://Harry%20Potter%20-%20Volume%201%20Raw.txt',
      );
      expect(
        evidenceRef.targetRef!.sourcePath,
        'Harry Potter - Volume 1 Raw.txt',
      );
      expect(
        evidenceRef.targetRef!.metadata['debug_local_absolute_path'],
        isNull,
      );
    });
  });
}
