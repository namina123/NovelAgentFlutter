import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Source import contract', () {
    const normalizationService = SourceImportNormalizationService();

    test('roundtrips neutral selections and requests without deconstruction语义', () {
      final request = SourceImportRequest(
        requestId: 'import_request_001',
        selections: <SourceImportSelection>[
          SourceImportSelection(
            selectionId: 'selection_directory',
            selectionKind: SourceImportSelectionKinds.directory,
            sourceIdentity: const SourceAssetIdentity(
              sourceAssetId: 'asset_directory',
              sourceKind: 'directory',
              displayName: '源目录',
              resolverUri: 'file:///imports/source_pack',
              localHintPath: 'sources/source_pack',
            ),
            sourceLocator: 'D:\\imports\\source_pack',
            sortOrder: 20,
            relativePathHint: 'imports/source_pack',
            recursive: true,
          ),
          SourceImportSelection(
            selectionId: 'selection_single',
            selectionKind: SourceImportSelectionKinds.singleFile,
            sourceIdentity: const SourceAssetIdentity(
              sourceAssetId: 'asset_single',
              sourceKind: 'file',
              displayName: '第一章',
              resolverUri: 'file:///imports/ch1.txt',
              localHintPath: 'chapters/ch1.txt',
            ),
            sourceLocator: 'D:\\imports\\ch1.txt',
            sortOrder: 10,
            mediaType: '',
            relativePathHint: 'sources\\chapters\\ch1.txt',
            recursive: false,
          ),
          SourceImportSelection(
            selectionId: 'selection_collection',
            selectionKind: SourceImportSelectionKinds.collection,
            sourceIdentity: const SourceAssetIdentity(
              sourceAssetId: 'asset_collection',
              sourceKind: 'collection',
              displayName: '辅助资料组',
            ),
            sourceLocator: 'bundle://supporting_texts',
            sortOrder: 30,
            relativePathHint: 'references/supporting_texts',
          ),
        ],
        sortMode: SourceImportSortModes.selectionOrder,
        metadata: const <String, Object?>{'request_channel': 'general_import'},
      );
      final roundTripped = SourceImportRequest.fromJson(request.toJson());

      expect(request.validateBasics(), isEmpty);
      expect(roundTripped.validateBasics(), isEmpty);
      expect(roundTripped.selections, hasLength(3));
      expect(
        roundTripped.selections
            .map((selection) => selection.selectionKind)
            .toList(growable: false),
        orderedEquals(const <String>[
          SourceImportSelectionKinds.directory,
          SourceImportSelectionKinds.singleFile,
          SourceImportSelectionKinds.collection,
        ]),
      );

      final normalized = normalizationService.normalizeRequest(request);
      expect(
        normalized.selections.map((selection) => selection.selectionId),
        orderedEquals(const <String>[
          'selection_single',
          'selection_directory',
          'selection_collection',
        ]),
      );
      expect(
        normalized.selections.first.mediaType,
        'text/plain',
      );
      expect(
        normalized.selections.first.relativePathHint,
        'sources/chapters/ch1.txt',
      );
      expect(
        normalized.selections.first.sourceIdentity.displayName,
        '第一章',
      );
      expect(
        normalized.selections
            .where(
              (selection) =>
                  selection.selectionKind ==
                  SourceImportSelectionKinds.directory,
            )
            .single
            .mediaType,
        'inode/directory',
      );
    });

    test('builds normalized documents that book deconstruction can consume', () {
      final request = SourceImportRequest(
        requestId: 'import_request_002',
        selections: <SourceImportSelection>[
          SourceImportSelection(
            selectionId: 'selection_story',
            selectionKind: SourceImportSelectionKinds.singleFile,
            sourceIdentity: const SourceAssetIdentity(
              sourceAssetId: 'asset_story',
              sourceKind: 'file',
              displayName: '海上城邦',
              resolverUri: 'file:///imports/story.txt',
              localHintPath: 'sources/story.txt',
            ),
            sourceLocator: 'D:\\imports\\story.txt',
            sortOrder: 1,
            relativePathHint: 'sources/story.txt',
          ),
        ],
      );
      final documents = normalizationService.buildDocuments(
        request,
        content: '第一章 港口风暴',
      );
      final input = BookDeconstructionInput.fromSourceImportDocuments(
        extractionId: 'extract_001',
        title: '海上城邦',
        sourceDocuments: documents,
      );

      expect(documents, hasLength(1));
      expect(documents.single.validateBasics(), isEmpty);
      expect(documents.single.toJson()['selection_kind'], 'single_file');
      expect(input.sourceDocuments, hasLength(1));
      expect(input.sourceDocuments.single.title, '海上城邦');
      expect(input.sourceDocuments.single.content, '第一章 港口风暴');
      expect(input.sourceDocuments.single.relativePathHint, 'sources/story.txt');
      expect(input.sourceDocuments.single.mediaType, 'text/plain');
      expect(
        input.sourceDocuments.single.metadata['source_identity'],
        isA<JsonMap>(),
      );
    });

    test('normalizes document projection from selection identity and ordering', () {
      final selection = SourceImportSelection(
        selectionId: 'selection_chapter',
        selectionKind: SourceImportSelectionKinds.singleFile,
        sourceIdentity: const SourceAssetIdentity(
          sourceAssetId: 'asset_chapter',
          sourceKind: 'file',
          displayName: '',
          resolverUri: '',
          localHintPath: '',
        ),
        sourceLocator: 'D:\\imports\\chapter_01.md',
        sortOrder: 7,
        mediaType: '',
        relativePathHint: 'chapters/chapter_01.md',
        recursive: false,
      );
      final document = SourceImportNormalizedDocument.fromSelection(
        selection,
        content: '第一章内容',
      );
      final roundTripped = SourceImportNormalizedDocument.fromJson(
        document.toJson(),
      );

      expect(document.validateBasics(), isEmpty);
      expect(roundTripped.validateBasics(), isEmpty);
      expect(roundTripped.documentId, 'asset_chapter');
      expect(roundTripped.title, 'chapter_01.md');
      expect(roundTripped.sourceLocator, 'D:\\imports\\chapter_01.md');
      expect(roundTripped.sequence, 7);
      expect(
        roundTripped.metadata['source_import_selection_kind'],
        SourceImportSelectionKinds.singleFile,
      );
    });
  });
}

