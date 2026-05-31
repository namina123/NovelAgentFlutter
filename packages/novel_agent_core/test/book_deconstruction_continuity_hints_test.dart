import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionContinuityHints', () {
    test('extraction result carries companion continuity hints separately', () {
      const extraction = BookDeconstructionExtractionResult(
        extractionId: 'extract_001',
        sourceTitle: '样本小说',
        continuityHints: BookDeconstructionContinuityHints(
          coverage: BookDeconstructionCoverageHint(
            sourceLabel: '原著全本',
            sourcePaths: <String>['imports/source_book.txt'],
            chapterStart: 1,
            chapterEnd: 128,
            sourceRanges: <BookDeconstructionSourceRangeHint>[
              BookDeconstructionSourceRangeHint(
                id: 'range_mainline',
                displayName: '主线正文',
                chapterStart: 1,
                chapterEnd: 128,
                sourcePaths: <String>['imports/source_book.txt'],
              ),
            ],
          ),
          scopeMap: BookDeconstructionScopeMap(
            defaultScopeId: 'scope_mainline',
            scopes: <BookDeconstructionScopeHint>[
              BookDeconstructionScopeHint(
                id: 'scope_mainline',
                displayName: '主线世界',
                scopeKind: ContinuationScopeKind.world,
                chapterStart: 1,
                chapterEnd: 128,
                sourcePaths: <String>['imports/source_book.txt'],
                sourceKind: BookDeconstructionHintSourceKind.sourceFact,
              ),
            ],
          ),
          identityMappings: <BookDeconstructionIdentityMappingHint>[
            BookDeconstructionIdentityMappingHint(
              id: 'identity_hero_alt',
              canonicalEntityId: 'hero',
              scopedEntityId: 'hero_alt',
              scopedDisplayName: '镜像主角',
              scopeHintId: 'scope_mainline',
              chapterStart: 64,
              chapterEnd: 80,
              sourcePaths: <String>['imports/source_book.txt'],
              sourceKind: BookDeconstructionHintSourceKind.inferredHint,
              mappingReason: '同一主体在异常线中的身份偏移',
            ),
          ],
          mechanicHints: <BookDeconstructionMechanicHint>[
            BookDeconstructionMechanicHint(
              id: 'mechanic_loop',
              displayName: '回档机制',
              scopeHintId: 'scope_mainline',
              branchModeHint: ContinuityBranchMode.forkOnTransition,
              memoryModeHint: ContinuityMemoryMode.continuous,
              stateModeHint: ContinuityStateMode.resetPerFrame,
              sourcePaths: <String>['imports/source_book.txt'],
              sourceKind: BookDeconstructionHintSourceKind.inferredHint,
            ),
          ],
        ),
      );

      expect(extraction.continuityHints.hasContent, isTrue);
      expect(extraction.continuityHints.hasInferredHints, isTrue);
      expect(extraction.characterProfiles, isEmpty);
      expect(
        extraction.continuityHints.scopeMap.defaultScopeId,
        'scope_mainline',
      );
    });

    test('source facts remain distinguishable from inferred hints', () {
      const factualHints = BookDeconstructionContinuityHints(
        coverage: BookDeconstructionCoverageHint(
          sourceLabel: '卷一至卷三',
          sourceRanges: <BookDeconstructionSourceRangeHint>[
            BookDeconstructionSourceRangeHint(
              id: 'volume_range',
              displayName: '卷一到卷三',
              chapterStart: 1,
              chapterEnd: 90,
              sourceKind: BookDeconstructionHintSourceKind.sourceFact,
            ),
          ],
        ),
        scopeMap: BookDeconstructionScopeMap(
          scopes: <BookDeconstructionScopeHint>[
            BookDeconstructionScopeHint(
              id: 'scope_city',
              displayName: '核心城邦',
              scopeKind: ContinuationScopeKind.arc,
              sourceKind: BookDeconstructionHintSourceKind.sourceFact,
            ),
          ],
        ),
      );

      expect(factualHints.hasContent, isTrue);
      expect(factualHints.hasInferredHints, isFalse);
    });
  });
}
