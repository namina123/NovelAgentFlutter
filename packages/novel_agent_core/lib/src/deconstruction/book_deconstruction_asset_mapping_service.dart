import '../inspiration/inspiration_premise.dart';
import 'book_deconstruction_application_action.dart';
import 'book_deconstruction_application_item.dart';
import 'book_deconstruction_artifact_kind.dart';
import 'book_deconstruction_extraction_result.dart';
import 'book_deconstruction_target_path_service.dart';

class BookDeconstructionAssetMappingService {
  const BookDeconstructionAssetMappingService({
    BookDeconstructionTargetPathService? targetPathService,
  }) : _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService();

  final BookDeconstructionTargetPathService _targetPathService;

  List<BookDeconstructionApplicationItem> map(
    BookDeconstructionExtractionResult result,
  ) {
    // 中文注释: 这里只负责把提取结果映射为“可应用条目”，不直接决定写盘或覆盖策略。
    final items = <BookDeconstructionApplicationItem>[];
    _addPremiseItems(items, result.premises);
    _addStoryOutlineItem(items, result.storyOutlineSummary);
    _addChapterOutlineItems(items, result);
    _addAssetItems(items, result);
    return items;
  }

  void _addPremiseItems(
    List<BookDeconstructionApplicationItem> items,
    List<InspirationPremise> premises,
  ) {
    for (var index = 0; index < premises.length; index++) {
      final premise = premises[index];
      items.add(
        BookDeconstructionApplicationItem(
          id: 'premise:${premise.id}',
          sourceKind: BookDeconstructionArtifactKind.premise,
          sourceId: premise.id,
          targetKind: BookDeconstructionArtifactKind.premise,
          action: BookDeconstructionApplicationAction.createOrMergeDocument,
          displayName: premise.displayName,
          summary: premise.summary,
          relativePathHint: _targetPathService.premisePath(premise, index + 1),
        ),
      );
    }
  }

  void _addStoryOutlineItem(
    List<BookDeconstructionApplicationItem> items,
    String storyOutlineSummary,
  ) {
    final cleanSummary = storyOutlineSummary.trim();
    if (cleanSummary.isEmpty) {
      return;
    }
    items.add(
      BookDeconstructionApplicationItem(
        id: 'story_outline:main',
        sourceKind: BookDeconstructionArtifactKind.storyOutline,
        sourceId: 'main',
        targetKind: BookDeconstructionArtifactKind.storyOutline,
        action: BookDeconstructionApplicationAction.createOrMergeDocument,
        displayName: '拆书故事总纲',
        summary: cleanSummary,
        relativePathHint: _targetPathService.storyOutlinePath(),
      ),
    );
  }

  void _addChapterOutlineItems(
    List<BookDeconstructionApplicationItem> items,
    BookDeconstructionExtractionResult result,
  ) {
    for (var index = 0; index < result.chapterOutlines.length; index++) {
      final outline = result.chapterOutlines[index];
      items.add(
        BookDeconstructionApplicationItem(
          id: 'chapter_outline:${outline.id}',
          sourceKind: BookDeconstructionArtifactKind.chapterOutline,
          sourceId: outline.id,
          targetKind: BookDeconstructionArtifactKind.chapterOutline,
          action: BookDeconstructionApplicationAction.createOrMergeDocument,
          displayName: outline.title,
          summary: outline.summary,
          relativePathHint: _targetPathService.chapterOutlinePath(
            outline,
            index + 1,
          ),
        ),
      );
    }
  }

  void _addAssetItems(
    List<BookDeconstructionApplicationItem> items,
    BookDeconstructionExtractionResult result,
  ) {
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.styleProfile,
      entries: result.styleProfiles
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.worldRuleSet,
      entries: result.worldRuleSets
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.characterProfile,
      entries: result.characterProfiles
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.organizationProfile,
      entries: result.organizationProfiles
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.foreshadowRecord,
      entries: result.foreshadowRecords
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.title,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.timelineRecord,
      entries: result.timelineRecords
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
    _addGenericAssetItems(
      items,
      artifactKind: BookDeconstructionArtifactKind.relationshipRecord,
      entries: result.relationshipRecords
          .map(
            (item) => _AssetEntry(
              id: item.id,
              displayName: item.displayName,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
    );
  }

  void _addGenericAssetItems(
    List<BookDeconstructionApplicationItem> items, {
    required String artifactKind,
    required List<_AssetEntry> entries,
  }) {
    for (final entry in entries) {
      items.add(
        BookDeconstructionApplicationItem(
          id: '$artifactKind:${entry.id}',
          sourceKind: artifactKind,
          sourceId: entry.id,
          targetKind: artifactKind,
          action: BookDeconstructionApplicationAction.createOrMergeAsset,
          displayName: entry.displayName,
          summary: entry.summary,
          relativePathHint: _targetPathService.assetPath(artifactKind, entry.id),
        ),
      );
    }
  }
}

class _AssetEntry {
  const _AssetEntry({
    required this.id,
    required this.displayName,
    required this.summary,
  });

  final String id;
  final String displayName;
  final String summary;
}
