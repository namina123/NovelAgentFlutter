import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Writing continuity validation matrix', () {
    const defaultsService = GeneralProjectContinuityDefaultsService();
    const resolver = ContinuityRuntimeResolverService();
    const followupMenuBuilder = BookDeconstructionFollowupMenuBuilderService();
    const derivedPlanBuilder =
        BookDeconstructionDerivedProjectPlanBuilderService();

    test('covers ordinary single-line project defaults', () {
      const project = ProjectDescriptor(
        id: 'ordinary_project',
        name: '普通长篇',
        rootPath: 'D:/tmp/ordinary_project',
        projectType: 'novel',
      );

      final bundle = defaultsService.buildBundle(project);
      final result = resolver.resolve(bundle);

      expect(result.scopeChain.scopeIds, <String>['global']);
      expect(result.activeFrame.frame?.id, 'mainline');
      expect(
        result.mechanicProfile.branchMode,
        ContinuityBranchMode.singleLine,
      );
      expect(result.mechanicProfile.causalMode, ContinuityCausalMode.linear);
      expect(result.inheritsParentState, isFalse);
      expect(result.inheritsParentMemory, isFalse);
    });

    test(
      'covers multi-world scoped overlays for fast-travel style writing',
      () {
        const bundle = ProjectContinuityBundle(
          id: 'world_travel',
          displayName: '多世界快穿',
          scopes: <ContinuationScope>[
            ContinuationScope(
              id: 'global',
              displayName: '全局',
              kind: ContinuationScopeKind.global,
            ),
            ContinuationScope(
              id: 'world_a',
              displayName: '侯府线',
              kind: ContinuationScopeKind.world,
              parentScopeId: 'global',
            ),
            ContinuationScope(
              id: 'world_b',
              displayName: '星际线',
              kind: ContinuationScopeKind.world,
              parentScopeId: 'global',
            ),
          ],
          scopeOverlays: <ContinuationScopeOverlay>[
            ContinuationScopeOverlay(
              id: 'world_a_identity',
              scopeId: 'world_a',
              displayName: '侯府身份覆盖',
              priority: 10,
              assetReferences: <ContinuityAssetReference>[
                ContinuityAssetReference(
                  assetKind: ContinuityAssetKind.characterProfile,
                  assetId: 'hero_mansion_alias',
                  role: ContinuityAssetReferenceRole.scopeOverlay,
                ),
              ],
            ),
            ContinuationScopeOverlay(
              id: 'world_b_identity',
              scopeId: 'world_b',
              displayName: '星际身份覆盖',
              priority: 10,
              assetReferences: <ContinuityAssetReference>[
                ContinuityAssetReference(
                  assetKind: ContinuityAssetKind.characterProfile,
                  assetId: 'hero_academy_alias',
                  role: ContinuityAssetReferenceRole.scopeOverlay,
                ),
              ],
            ),
          ],
          mechanicProfiles: <ContinuityMechanicProfile>[
            ContinuityMechanicProfile(
              id: 'travel_profile',
              displayName: '多世界承接',
              identityMode: ContinuityIdentityMode.scopeOverlay,
              branchMode: ContinuityBranchMode.forkOnTransition,
              memoryMode: ContinuityMemoryMode.protagonistOnly,
              stateMode: ContinuityStateMode.partialCarryOver,
            ),
          ],
          frames: <ContinuityFrame>[
            ContinuityFrame(
              id: 'world_b_frame',
              displayName: '星际当前线',
              scopeId: 'world_b',
              mechanicProfileId: 'travel_profile',
            ),
          ],
          defaultFrameId: 'world_b_frame',
          defaultMechanicProfileId: 'travel_profile',
        );

        final result = resolver.resolve(bundle);

        expect(result.scopeChain.scopeIds, <String>['global', 'world_b']);
        expect(
          result.overlayAssetReferences.map((item) => item.assetId),
          <String>['hero_academy_alias'],
        );
        expect(
          result.mechanicProfile.identityMode,
          ContinuityIdentityMode.scopeOverlay,
        );
        expect(
          result.mechanicProfile.memoryMode,
          ContinuityMemoryMode.protagonistOnly,
        );
      },
    );

    test('covers replay or death-return reset lines', () {
      const bundle = ProjectContinuityBundle(
        id: 'replay_loop',
        displayName: '死亡回归',
        scopes: <ContinuationScope>[
          ContinuationScope(
            id: 'global',
            displayName: '全局',
            kind: ContinuationScopeKind.global,
          ),
        ],
        mechanicProfiles: <ContinuityMechanicProfile>[
          ContinuityMechanicProfile(
            id: 'loop_profile',
            displayName: '回档机制',
            memoryMode: ContinuityMemoryMode.continuous,
            stateMode: ContinuityStateMode.resetPerFrame,
            causalMode: ContinuityCausalMode.replayAware,
            branchMode: ContinuityBranchMode.forkOnTransition,
          ),
        ],
        frames: <ContinuityFrame>[
          ContinuityFrame(
            id: 'loop_1',
            displayName: '周目一',
            scopeId: 'global',
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'hero_state_loop_1',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
          ContinuityFrame(
            id: 'loop_2',
            displayName: '周目二',
            scopeId: 'global',
            mechanicProfileId: 'loop_profile',
            parentFrameId: 'loop_1',
            relation: ContinuityFrameRelation.reset,
            stateReferences: <ContinuityAssetReference>[
              ContinuityAssetReference(
                assetKind: ContinuityAssetKind.characterStageStateRecord,
                assetId: 'hero_state_loop_2',
                role: ContinuityAssetReferenceRole.runtimeState,
              ),
            ],
          ),
        ],
      );

      final result = resolver.resolve(bundle, frameId: 'loop_2');

      expect(result.replayAware, isTrue);
      expect(result.inheritsParentState, isFalse);
      expect(result.inheritsParentMemory, isFalse);
      expect(result.stateAssetReferences.map((item) => item.assetId), <String>[
        'hero_state_loop_2',
      ]);
    });

    test(
      'covers dream or illusion local abnormal lines without polluting mainline',
      () {
        const bundle = ProjectContinuityBundle(
          id: 'dream_line',
          displayName: '梦境异常线',
          scopes: <ContinuationScope>[
            ContinuationScope(
              id: 'global',
              displayName: '全局',
              kind: ContinuationScopeKind.global,
            ),
            ContinuationScope(
              id: 'dream_arc',
              displayName: '梦境线',
              kind: ContinuationScopeKind.arc,
              parentScopeId: 'global',
            ),
          ],
          scopeOverlays: <ContinuationScopeOverlay>[
            ContinuationScopeOverlay(
              id: 'dream_overlay',
              scopeId: 'dream_arc',
              displayName: '梦境设定覆盖',
              priority: 10,
              assetReferences: <ContinuityAssetReference>[
                ContinuityAssetReference(
                  assetKind: ContinuityAssetKind.worldRuleSet,
                  assetId: 'dream_rules',
                  role: ContinuityAssetReferenceRole.scopeOverlay,
                ),
              ],
            ),
          ],
          mechanicProfiles: <ContinuityMechanicProfile>[
            ContinuityMechanicProfile(
              id: 'dream_profile',
              displayName: '局部异常线',
              identityMode: ContinuityIdentityMode.forkedAlias,
              memoryMode: ContinuityMemoryMode.hiddenMetaOnly,
              stateMode: ContinuityStateMode.scopedOverlay,
              causalMode: ContinuityCausalMode.overwritten,
              branchMode: ContinuityBranchMode.overwriteParent,
              visibilityMode: ContinuityVisibilityMode.frameScoped,
            ),
          ],
          frames: <ContinuityFrame>[
            ContinuityFrame(
              id: 'mainline',
              displayName: '主线',
              scopeId: 'global',
              stateReferences: <ContinuityAssetReference>[
                ContinuityAssetReference(
                  assetKind: ContinuityAssetKind.characterStageStateRecord,
                  assetId: 'hero_state_mainline',
                  role: ContinuityAssetReferenceRole.runtimeState,
                ),
              ],
            ),
            ContinuityFrame(
              id: 'dream_frame',
              displayName: '梦境帧',
              scopeId: 'dream_arc',
              mechanicProfileId: 'dream_profile',
              parentFrameId: 'mainline',
              relation: ContinuityFrameRelation.overwrite,
              stateReferences: <ContinuityAssetReference>[
                ContinuityAssetReference(
                  assetKind: ContinuityAssetKind.characterStageStateRecord,
                  assetId: 'hero_state_dream',
                  role: ContinuityAssetReferenceRole.runtimeState,
                ),
              ],
            ),
          ],
          defaultFrameId: 'mainline',
        );

        final result = resolver.resolve(bundle, frameId: 'dream_frame');

        expect(result.scopeChain.scopeIds, <String>['global', 'dream_arc']);
        expect(
          result.overlayAssetReferences.map((item) => item.assetId),
          <String>['dream_rules'],
        );
        expect(result.inheritsParentState, isFalse);
        expect(result.inheritsParentMemory, isFalse);
        expect(
          result.mechanicProfile.visibilityMode,
          ContinuityVisibilityMode.frameScoped,
        );
        expect(
          result.stateAssetReferences.map((item) => item.assetId),
          <String>['hero_state_dream'],
        );
      },
    );

    test(
      'covers deconstruction quick-bridge followup for general continuation',
      () {
        final menu = followupMenuBuilder.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.generalNovelPreferred,
        );
        final input = BookDeconstructionInput(
          extractionId: 'extract_quick',
          title: '旧都回声',
          sourceDocuments: const <BookDeconstructionSourceDocument>[
            BookDeconstructionSourceDocument(
              id: 'source_1',
              title: '旧都回声',
              content: '正文',
            ),
          ],
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.generalNovelPreferred,
        );

        final plan = derivedPlanBuilder.build(
          input: input,
          followupMenu: menu,
          followupOptionId: 'continuation_novel',
        );

        expect(menu.highlightedBuildTier, ContinuityBuildTier.quickBridge);
        expect(plan.targetProjectTypeId, 'novel');
        expect(plan.recommendedBuildTier, ContinuityBuildTier.quickBridge);
      },
    );

    test(
      'covers deconstruction standard foundation for preferred long-task continuation',
      () {
        final menu = followupMenuBuilder.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );
        final input = BookDeconstructionInput(
          extractionId: 'extract_standard',
          title: '海上城邦',
          sourceDocuments: const <BookDeconstructionSourceDocument>[
            BookDeconstructionSourceDocument(
              id: 'source_1',
              title: '海上城邦',
              content: '正文',
            ),
          ],
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );

        final plan = derivedPlanBuilder.build(
          input: input,
          followupMenu: menu,
          followupOptionId: 'fanfic_seed_autopilot_novel',
        );

        expect(menu.highlightedGroupId, 'fanfic');
        expect(
          menu.highlightedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
        expect(plan.targetProjectTypeId, 'long_novel');
        expect(plan.targetModeId, 'seed_autopilot_novel');
        expect(
          plan.recommendedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
      },
    );

    test(
      'covers deep reconstruction and multiple derived plans from one source project',
      () {
        final menu = followupMenuBuilder.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );
        final input = BookDeconstructionInput(
          extractionId: 'extract_deep',
          title: '群星尽头',
          sourceDocuments: const <BookDeconstructionSourceDocument>[
            BookDeconstructionSourceDocument(
              id: 'source_1',
              title: '群星尽头',
              content: '正文',
            ),
          ],
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );

        final deepPlan = derivedPlanBuilder.build(
          input: input,
          followupMenu: menu,
          followupOptionId: 'fanfic_full_outline_consensus',
        );
        final siblingPlan = derivedPlanBuilder.build(
          input: input,
          followupMenu: menu,
          followupOptionId: 'fanfic_chapter_brief_supervised',
        );

        expect(deepPlan.sourceExtractionId, siblingPlan.sourceExtractionId);
        expect(deepPlan.planId, isNot(equals(siblingPlan.planId)));
        expect(deepPlan.targetModeId, 'full_outline_consensus');
        expect(
          deepPlan.recommendedBuildTier,
          ContinuityBuildTier.deepReconstruction,
        );
        expect(siblingPlan.targetModeId, 'chapter_brief_supervised');
        expect(
          siblingPlan.recommendedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
      },
    );
  });
}
