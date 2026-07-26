import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionApplicationPlan', () {
    test('use case maps structured extraction into existing asset paths', () {
      // 中文注释: 这里验证拆书结果不会落成一套新野目录，而是映射回现有 premise/outlines/assets 体系。
      final useCase = BuildBookDeconstructionApplicationPlanUseCase();
      final input = BookDeconstructionInput(
        extractionId: 'extract_001',
        title: '示例拆书任务',
        sourceDocuments: const <BookDeconstructionSourceDocument>[
          BookDeconstructionSourceDocument(
            id: 'source_1',
            title: '样本小说',
            content: '外部作品内容',
          ),
        ],
      );
      final extraction = BookDeconstructionExtractionResult(
        extractionId: 'extract_001',
        sourceTitle: '样本小说',
        premises: const <InspirationPremise>[
          InspirationPremise(
            id: 'premise_1',
            displayName: '核心前提',
            summary: '世界濒临坍塌，主角必须回收失落的秩序碎片。',
          ),
        ],
        storyOutlineSummary: '主角从边陲进入核心城邦，逐步揭开秩序断裂的真相。',
        chapterOutlines: const <BookDeconstructionChapterOutline>[
          BookDeconstructionChapterOutline(
            id: 'chapter_1',
            title: '第一章',
            summary: '主角被迫离开故乡。',
            sequence: 1,
          ),
        ],
        styleProfiles: const <StyleProfile>[
          StyleProfile(
            id: 'commercial_clean',
            displayName: '商业干净文风',
            summary: '节奏快、句式利落、强调钩子和爽点。',
          ),
        ],
        worldRuleSets: const <WorldRuleSet>[
          WorldRuleSet(
            id: 'world_rules',
            displayName: '秩序规则',
            summary: '所有超常能力都来自秩序碎片。',
          ),
        ],
        characterProfiles: const <CharacterProfile>[
          CharacterProfile(
            id: 'lead_role',
            displayName: '主角映射',
            summary: '背负家族旧债，被迫进入主线。',
          ),
        ],
        organizationProfiles: const <OrganizationProfile>[
          OrganizationProfile(
            id: 'core_council',
            displayName: '核心议会',
            summary: '控制世界秩序解释权的组织。',
          ),
        ],
        foreshadowRecords: const <ForeshadowRecord>[
          ForeshadowRecord(
            id: 'first_mark',
            title: '第一枚印记',
            status: 'planted',
            summary: '印记将对应最终真相。',
          ),
        ],
        timelineRecords: const <TimelineRecord>[
          TimelineRecord(
            id: 'timeline_origin',
            displayName: '旧秩序崩塌',
            summary: '一切冲突的源头事件。',
          ),
        ],
        relationshipRecords: const <RelationshipRecord>[
          RelationshipRecord(
            id: 'lead_vs_council',
            displayName: '主角与议会',
            leftEntityId: 'lead_role',
            rightEntityId: 'core_council',
            summary: '从依附逐步走向对立。',
          ),
        ],
        continuityHints: const BookDeconstructionContinuityHints(
          coverage: BookDeconstructionCoverageHint(
            sourceLabel: '原著正文',
            sourceRanges: <BookDeconstructionSourceRangeHint>[
              BookDeconstructionSourceRangeHint(
                id: 'main_range',
                displayName: '主线正文',
                chapterStart: 1,
                chapterEnd: 200,
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
              ),
            ],
          ),
          identityMappings: <BookDeconstructionIdentityMappingHint>[
            BookDeconstructionIdentityMappingHint(
              id: 'identity_lead_alt',
              canonicalEntityId: 'lead_role',
              scopedEntityId: 'lead_role_alt',
            ),
          ],
          mechanicHints: <BookDeconstructionMechanicHint>[
            BookDeconstructionMechanicHint(
              id: 'mechanic_loop',
              displayName: '循环机制',
              memoryModeHint: ContinuityMemoryMode.continuous,
            ),
          ],
        ),
      );

      final plan = useCase.execute(input: input, extractionResult: extraction);

      expect(plan.planId, 'plan_extract_001');
      expect(
        plan.targetProjectTypeId,
        BookDeconstructionConstants.projectTypeId,
      );
      expect(
        plan.targetProjectStrategyId,
        BookDeconstructionConstants.projectStrategyId,
      );
      expect(plan.modeId, BookDeconstructionConstants.modeAssetExtraction);
      expect(plan.items, hasLength(10));
      expect(
        plan.items.map((item) => item.relativePathHint),
        containsAll(<String>[
          'premise/book_deconstruction_premise_1_核心前提.md',
          'outlines/story/book_deconstruction_story_outline.md',
          'outlines/chapters/book_deconstruction_chapter_1.md',
          'assets/styles/commercial_clean.md',
          'assets/world/world_rules.md',
          'assets/characters/lead_role.md',
          'assets/organizations/core_council.md',
          'assets/foreshadows/first_mark.foreshadow.md',
          'assets/timeline/timeline_origin.timeline.md',
          'assets/relationships/lead_vs_council.relationship.md',
        ]),
      );
      expect(
        plan.items.any(
          (item) =>
              item.displayName.contains('主线世界') ||
              item.displayName.contains('循环机制'),
        ),
        isFalse,
      );
    });

    test('catalogs expose formal book deconstruction project entry', () {
      // 中文注释: 这里确认拆书不是临时字符串，而是正式登记在项目类型和策略目录中的平行入口。
      const projectTypeCatalog = ProjectTypeCatalogService();
      const strategyCatalog = StrategyCatalogService();

      final projectType = projectTypeCatalog.definitionOf(
        BookDeconstructionConstants.projectTypeId,
      );
      final projectStrategy = strategyCatalog.projectStrategies().firstWhere(
        (item) => item.id == BookDeconstructionConstants.projectStrategyId,
      );
      final mode = strategyCatalog.modeDefinitions().firstWhere(
        (item) => item.id == BookDeconstructionConstants.modeAssetExtraction,
      );

      expect(projectType.id, BookDeconstructionConstants.projectTypeId);
      expect(projectType.requiresRuntimeBaselineSelection, isFalse);
      expect(
        projectStrategy.supportedModeIds,
        contains(BookDeconstructionConstants.modeAssetExtraction),
      );
      expect(
        mode.projectStrategyId,
        BookDeconstructionConstants.projectStrategyId,
      );
      expect(
        mode.workflowStrategyId,
        BookDeconstructionConstants.workflowInteractiveSession,
      );
    });

    test(
      'uses SQLite projection paths when the target storage strategy is SQLite',
      () {
        final plan = BuildBookDeconstructionApplicationPlanUseCase().execute(
          input: const BookDeconstructionInput(
            extractionId: 'extract_sqlite_001',
            title: 'SQLite 拆书任务',
            sourceDocuments: <BookDeconstructionSourceDocument>[
              BookDeconstructionSourceDocument(
                id: 'source_1',
                title: '样本小说',
                content: '外部作品内容',
              ),
            ],
          ),
          extractionResult: const BookDeconstructionExtractionResult(
            extractionId: 'extract_sqlite_001',
            sourceTitle: '样本小说',
            premises: <InspirationPremise>[
              InspirationPremise(
                id: 'premise_1',
                displayName: '核心前提',
                summary: '主角必须回收失落的秩序碎片。',
              ),
            ],
            storyOutlineSummary: '主角进入城邦并揭开秩序断裂真相。',
            chapterOutlines: <BookDeconstructionChapterOutline>[
              BookDeconstructionChapterOutline(
                id: 'chapter_1',
                title: '第一章',
                summary: '主角离开故乡。',
                sequence: 1,
              ),
            ],
            characterProfiles: <CharacterProfile>[
              CharacterProfile(
                id: 'lead_role',
                displayName: '主角映射',
                summary: '背负家族旧债。',
              ),
            ],
            foreshadowRecords: <ForeshadowRecord>[
              ForeshadowRecord(
                id: 'first_mark',
                title: '第一枚印记',
                status: 'planted',
                summary: '印记指向最终真相。',
              ),
            ],
          ),
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        expect(
          plan.items.map((item) => item.relativePathHint),
          containsAll(<String>[
            'imports/analysis/premise/book_deconstruction_premise_1_核心前提.md',
            'imports/analysis/outlines/book_deconstruction_story_outline.md',
            'imports/analysis/chapter_outlines/book_deconstruction_chapter_1.md',
            'imports/analysis/assets/characters/lead_role.md',
            'imports/analysis/assets/foreshadows/first_mark.foreshadow.md',
          ]),
        );
      },
    );
  });
}
