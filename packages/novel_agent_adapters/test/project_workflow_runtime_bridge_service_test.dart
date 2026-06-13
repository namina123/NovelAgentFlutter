import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWorkflowRuntimeBridgeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkflowRuntimeBridgeService service;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-workflow-bridge-',
      );
      workspacePort = LocalProjectWorkspacePort();
      service = ProjectWorkflowRuntimeBridgeService(
        contextActivationService: ProjectContextActivationService(
          workspacePort: workspacePort,
        ),
      );
      project = ProjectDescriptor(
        id: 'workflow_bridge_project',
        name: '工作流桥接项目',
        rootPath: tempDirectory.path,
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outline/总纲.md',
        '# 总纲\n第一章需要迅速进入冲突。',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'chapter workflow exposes research request tools while keeping heavy extraction gated for writing groups',
      () async {
        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'chapter',
            'source_paths': <Object?>['outline/总纲.md'],
          },
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'starter_story_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
        );

        final toolIds = ValueReaders.stringList(bridge['workflow_tool_ids']);
        final exposureResolution = ValueReaders.mapValue(
          bridge['workflow_tool_exposure_resolution'],
        );

        expect(
          toolIds,
          contains(NarrativeDomainToolNames.submitChapterDelivery),
        );
        expect(
          toolIds,
          contains(NarrativeDomainToolNames.requestExternalResearch),
        );
        expect(
          toolIds,
          isNot(contains(NarrativeDomainToolNames.proposeKnowledgeCard)),
        );
        expect(
          ValueReaders.stringList(
            exposureResolution['default_open_capability_family_ids'],
          ),
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
            ToolCapabilityFamilyCatalogService.writing,
            ToolCapabilityFamilyCatalogService.review,
          ]),
        );
        expect(
          ValueReaders.stringList(
            exposureResolution['requires_confirmation_tool_ids'],
          ),
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
          ]),
        );
        expect(
          ValueReaders.stringList(exposureResolution['visible_tool_ids']),
          contains(NarrativeDomainToolNames.requestExternalResearch),
        );
      },
    );

    test(
      'reference extraction task opens heavy extraction tools only for extraction-oriented groups',
      () async {
        final writingBridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'chapter',
            'metadata': <String, Object?>{
              'task_family_id': ContinuousTaskFamilies.referenceExtraction,
            },
          },
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'starter_story_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
        );
        final extractionBridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'chapter',
            'metadata': <String, Object?>{
              'task_family_id': ContinuousTaskFamilies.referenceExtraction,
            },
          },
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'reference_extraction_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
                ToolCapabilityFamilyCatalogService.referenceExtraction,
              ],
            },
          },
        );

        final writingToolIds = ValueReaders.stringList(
          writingBridge['workflow_tool_ids'],
        );
        final extractionToolIds = ValueReaders.stringList(
          extractionBridge['workflow_tool_ids'],
        );
        final extractionResolution = ValueReaders.mapValue(
          extractionBridge['workflow_tool_exposure_resolution'],
        );

        expect(
          writingToolIds,
          isNot(contains(NarrativeDomainToolNames.proposeKnowledgeCard)),
        );
        expect(
          extractionToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ]),
        );
        expect(
          extractionToolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              extractionResolution['task_profile'],
            )['family_id'],
          ),
          ContinuousTaskFamilies.referenceExtraction,
        );
        expect(
          ValueReaders.stringList(
            extractionResolution['default_open_capability_family_ids'],
          ),
          containsAll(const <String>[
            ToolCapabilityFamilyCatalogService.research,
            ToolCapabilityFamilyCatalogService.referenceExtraction,
          ]),
        );
      },
    );

    test(
      'planning-stage agent task uses planning tool surface instead of chapter delivery tools',
      () async {
        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'agent_task',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'output_paths': <Object?>['outlines/story/读取现有种子材料.md'],
            'metadata': <String, Object?>{
              'stage': 'planning',
              'plan_id': 'plan_test',
              'generated_by': 'LongTaskPlanner',
              'runtime_baseline_id': 'continuous_autonomous',
            },
          },
        );

        final toolIds = ValueReaders.stringList(bridge['workflow_tool_ids']);
        final exposureResolution = ValueReaders.mapValue(
          bridge['workflow_tool_exposure_resolution'],
        );

        expect(
          toolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
        expect(toolIds, contains('write_project_file'));
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(exposureResolution['metadata'])['intent'],
          ),
          'workflow_task',
        );
      },
    );

    test(
      'continuous autonomous formal writing steps do not expose set_agent_tasks',
      () async {
        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'metadata': <String, Object?>{
              'plan_id': 'plan_test',
              'generated_by': 'LongTaskRevision',
              'runtime_baseline_id': 'continuous_autonomous',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'stage': 'draft',
            },
          },
        );

        final toolIds = ValueReaders.stringList(bridge['workflow_tool_ids']);
        expect(toolIds, contains('submit_chapter_delivery'));
        expect(toolIds, isNot(contains('set_agent_tasks')));
      },
    );

    test(
      'workflow bridge exposes mounted reference continuity summary from production substrate',
      () async {
        final substrate = SqliteReferenceEvidenceSubstrate(
          substrateRootPath:
              '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}reference_extraction${Platform.pathSeparator}substrate',
        );
        final extraction = const ReferenceSourceDocumentExtractionService()
            .extract(
              const ReferenceSourceDocumentIngestionRequest(
                sourceText: 'CHAPTER ONE\nHarry uses the holly wand.',
                sourceTitle: 'Harry Potter Sample',
                packageId: 'pkg_hp',
                packageKind: 'reference_work_package',
                displayName: '哈利波特样例',
                packageVersionId: 'v1',
                versionLabel: 'v1',
                createdAt: '2026-06-08T12:00:00Z',
                targetLanguage: 'zh-CN',
              ),
            );
        await substrate.upsertPackageSnapshot(extraction.snapshot);
        await SqliteProjectReferenceAttachmentLayer().upsertAttachment(
          project,
          const ProjectReferenceAttachment(
            attachmentId: 'attach_pkg_hp_v1',
            projectId: 'workflow_bridge_project',
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            visibilityMode: ReferenceVisibilityModes.discoverable,
            accessLevel: ReferenceAccessLevels.manager,
            displayLabel: '哈利波特样例',
            allowsDiscoveryExpansion: true,
            allowsProjection: true,
            allowsPromotion: true,
            attachedAt: '2026-06-08T12:00:00Z',
          ),
        );
        await substrate.upsertContinuityLedger(
          ReferenceEvidenceContinuityLedger(
            packageId: 'pkg_hp',
            packageVersionId: 'v1',
            conflictClusters: <NarrativeConflictCluster>[
              NarrativeConflictCluster.fromJson(<String, Object?>{
                'cluster_id': 'cluster_hp_1',
                'subject_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.asset,
                  'ref_id': 'harry',
                },
                'attribute_key': 'wand_owner',
                'classification':
                    NarrativeConflictClassifications.unexplainedConflict,
                'cluster_status':
                    NarrativeConflictClusterStatuses.needsDecision,
                'summary': '魔杖归属说法不一致。',
                'fact_evidences': <Object?>[
                  <String, Object?>{
                    'fact_evidence_id': 'fact_hp_1',
                    'subject_ref': <String, Object?>{
                      'ref_type': NarrativeRefTypes.asset,
                      'ref_id': 'harry',
                    },
                    'attribute_key': 'wand_owner',
                    'value_payload': <String, Object?>{'value': 'Harry'},
                    'value_summary': 'Harry 持有冬青木魔杖',
                    'claim_snapshot': <String, Object?>{
                      'claim_id': 'claim_hp_1',
                      'subject_ref': <String, Object?>{
                        'ref_type': NarrativeRefTypes.asset,
                        'ref_id': 'harry',
                      },
                      'claim_namespace': 'continuity.character',
                      'claim_key': 'wand_owner',
                      'claim_value': <String, Object?>{'value': 'Harry'},
                    },
                    'source': <String, Object?>{
                      'source_type': 'reference_package',
                      'source_id': 'pkg_hp',
                    },
                  },
                ],
              }),
            ],
            canonDecisions: <ProjectCanonDecision>[
              ProjectCanonDecision.fromJson(<String, Object?>{
                'decision_id': 'decision_hp_1',
                'cluster_id': 'cluster_hp_1',
                'decision_kind': ProjectCanonDecisionKinds.deferUnresolved,
                'decided_at': '2026-06-08T12:10:00Z',
                'review_required': true,
              }),
            ],
            reviewAlerts: <ContinuityReviewAlert>[
              ContinuityReviewAlert.fromJson(<String, Object?>{
                'alert_id': 'alert_hp_1',
                'cluster_id': 'cluster_hp_1',
                'alert_kind': ContinuityReviewAlertKinds.unresolvedConflict,
                'severity': ContinuityReviewAlertSeverities.high,
                'summary': '哈利的魔杖归属仍需人工确认。',
                'requires_manual_review': true,
                'source': <String, Object?>{
                  'source_type': 'reference_package',
                  'source_id': 'pkg_hp',
                },
              }),
            ],
            updatedAt: '2026-06-08T12:15:00Z',
          ),
        );

        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{'task_type': 'chapter'},
        );
        final continuityReport = ValueReaders.mapValue(
          bridge['reference_continuity_report'],
        );
        final packages = ValueReaders.mapList(continuityReport['packages']);

        expect(
          ValueReaders.stringValue(continuityReport['summary']),
          contains('1 个 conflict cluster'),
        );
        expect(packages, hasLength(1));
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              packages.single['continuity_summary'],
            )['review_alert_count'],
          ),
          1,
        );
        expect(
          ValueReaders.stringValue(
            bridge['reference_continuity_context_markdown'],
          ),
          contains('哈利的魔杖归属仍需人工确认'),
        );
        expect(
          ValueReaders.mapValue(continuityReport['metadata']).containsKey(
            'substrate_root_path',
          ),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(bridge['activation_context_markdown']),
          contains('Mounted Reference Continuity'),
        );
      },
    );

    test(
      'chaptered continuation tasks surface explicit continuity checkpoint in activation summary',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'summaries/第02章：摸底.summary.md',
          '第02章摘要：章末已经把落脚请求说出口，下一章应直接承接回应。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'assets/timeline/第02章_摸底.timeline.md',
          '第02章时间线：王保正已经开门，陆安已说明来意。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章_摸底.md',
          '# 第02章\n\n陆安把话说完，只等门里的人给一句回音。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
          '{"submission":{"summary":"第02章交付：章末已提出落脚请求。","final_state_summary":{"location":"王保正家门口","next_chapter_handoff":"直接从对方回应继续。"}}}',
        );

        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'book_deconstruction_continuation',
            'chapter': '第03章',
            'source_paths': <Object?>['outline/总纲.md'],
          },
        );

        final markdown = ValueReaders.stringValue(
          bridge['activation_context_markdown'],
        );
        expect(markdown, contains('continuity_checkpoint'));
        expect(markdown, contains('## Chapter Continuity Guard'));
        expect(markdown, contains('下一章必须直接承接：直接从对方回应继续。'));
        expect(markdown, contains('上一章已完成，不要重演：第02章交付：章末已提出落脚请求。'));
        expect(markdown, contains('当前落点：王保正家门口'));
        expect(markdown, contains('不要把上一章末尾已完成的动作、对话或到达重新播放一遍'));
        expect(markdown, contains('不要从同一动作重新起笔'));
      },
    );

    test(
      'chaptered continuation workflow falls back to previous chapter tail guard even without delivery sidecar',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章_摸底.md',
          '# 第02章\n\n门里的人把门栓拨开半寸，先隔着门缝问他到底来镇上做什么。陆安已经把落脚的请求说出口，只等这一句回音落下来。',
        );

        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'chapter',
            'chapter': '第03章',
            'source_paths': <Object?>['outline/总纲.md'],
          },
        );

        final markdown = ValueReaders.stringValue(
          bridge['activation_context_markdown'],
        );
        expect(markdown, contains('## Chapter Continuity Guard'));
        expect(
          markdown,
          contains('上一章章末原文锚点：# 第02章 门里的人把门栓拨开半寸'),
        );
        expect(
          markdown,
          contains('如果交付摘要还不完整，就以这段章末原文状态为准直接续写'),
        );
        expect(
          markdown,
          contains('不要把这段章末原文里已经发生的动作、对话或到达重新写一遍'),
        );
      },
    );

    test(
      'continuous autonomous seed planning does not expose present_user_options by default',
      () async {
        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'metadata': <String, Object?>{
              'runtime_baseline_id': 'continuous_autonomous',
            },
          },
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'starter_story_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
        );

        final toolIds = ValueReaders.stringList(bridge['workflow_tool_ids']);
        expect(toolIds, contains('write_project_file'));
        expect(toolIds, contains('edit_project_file'));
        expect(toolIds, isNot(contains('present_user_options')));
      },
    );

    test(
      'chaptered continuation workflow boosts recent chapter handoff assets into activation context',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '规格：章节必须承接上一章尾状态。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/chapters/章节任务清单.md',
          '第02章：探镇。第03章：落脚。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'summaries/第02章摘要.summary.md',
          '第02章摘要：陆安已经敲开王保正家的门，并开口问落户的事。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'assets/timeline/第02章_探镇.timeline.md',
          '第02章时间线：章末已到王保正门前，不能再从门外重启。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          '{"summary":"章末已完成敲门与发问。"}',
        );

        final bridge = await service.buildTaskBridge(
          project,
          const <String, Object?>{
            'task_type': 'book_deconstruction_continuation',
            'chapter': '第03章',
            'source_paths': <Object?>[
              'specs/project_spec.md',
              'outline/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
          },
        );
        final activationReport = ContextActivationReport.fromJson(
          ValueReaders.mapValue(bridge['activation_report']),
        );

        expect(activationReport.budgetChars, 6000);
        expect(
          activationReport.selectedItemIds,
          contains('file:summaries/第02章摘要.summary.md'),
        );
        expect(
          activationReport.selectedItemIds,
          contains('file:assets/timeline/第02章_探镇.timeline.md'),
        );
        expect(
          activationReport.selectedItemIds,
          contains('file:specs/project_spec.md'),
        );
      },
    );
  });
}
