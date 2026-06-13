import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceExtractionRuntimeService', () {
    late Directory tempDirectory;
    late Directory projectDirectory;
    late File sourceFile;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectAgentGroupBindingRepository groupBindingRepository;
    late ProjectReferenceExtractionRuntimeService runtimeService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'project_reference_extraction_runtime_test_',
      );
      projectDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}project',
      )..createSync(recursive: true);
      sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample_reference.txt',
      );
      await sourceFile.writeAsString('''
CHAPTER ONE
Harry lived at number four, Privet Drive, with the Dursleys.

CHAPTER TWO
Letters arrived from Hogwarts and Vernon tried to block them.
''');
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_reference_runtime',
        name: '参考资产提取测试项目',
        rootPath: projectDirectory.path,
      );
      groupBindingRepository = ProjectAgentGroupBindingRepository(
        workspacePort: workspacePort,
      );
      await groupBindingRepository.saveSelections(
        project,
        const <ProjectAgentGroupSelection>[
          ProjectAgentGroupSelection(
            groupId: 'reference_extraction_group',
            displayName: '参考资产提取组',
            selectedByDefault: true,
            taskFamilyIds: <String>[AgentTaskFamilies.referenceExtraction],
          ),
        ],
      );
      runtimeService = ProjectReferenceExtractionRuntimeService(
        workspacePort: workspacePort,
        loadAvailableAgents: (_) async => <JsonMap>[
          <String, Object?>{
            'id': 'reference_extractor',
            'name': '参考资产提取师',
            'role': '负责参考资产提取。',
          },
        ],
        loadAvailableGroups: (_) async => <JsonMap>[
          <String, Object?>{
            'id': 'reference_extraction_group',
            'name': '参考资产提取组',
            'description': '面向参考资产提取的智能体组。',
            'agents': <Object?>['reference_extractor'],
            'metadata': <String, Object?>{
              'task_family_ids': <String>[
                AgentTaskFamilies.referenceExtraction,
              ],
            },
            'allowed_project_type_ids': <String>['novel'],
          },
        ],
        groupBindingRepository: groupBindingRepository,
        proposalGeneratorFactory:
            ({required LlmGateway llmGateway, required String modelId}) =>
                const _FakeProposalGenerator(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'runs extraction through formal runtime, exports bundle and projects information into project',
      () async {
        final result = await runtimeService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            displayName: '样本文稿提取',
            strategyProfileId: 'reference_extraction.custom_dense',
            additionalStrategyProfiles:
                const <ReferenceExtractionStrategyProfile>[
                  ReferenceExtractionStrategyProfile(
                    profileId: 'reference_extraction.custom_dense',
                    proposalPolicy: ReferenceExtractionProposalPolicy(
                      minProposalCount: 6,
                      maxProposalCount: 9,
                    ),
                    ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
                      defaultAvailableContextChars: 10000,
                      planningMode:
                          ReferenceSourceBatchPlanningModes.chapterFirst,
                      maxSectionsPerBatch: 1,
                    ),
                    executionDiscipline: ReferenceExtractionExecutionDiscipline(
                      concurrencyMode:
                          ReferenceExtractionConcurrencyModes.reservedParallel,
                      maxConcurrentBatches: 4,
                      allowParallelHeavyTextConsumption: true,
                    ),
                  ),
                ],
          ),
        );

        expect(result.groupResolutionKind, 'task_family_override');
        expect(result.selectedGroupId, 'reference_extraction_group');
        expect(result.strategyProfileId, 'reference_extraction.custom_dense');
        expect(result.acceptedProposalCount, greaterThanOrEqualTo(2));
        expect(result.finalizedEntryCount, greaterThanOrEqualTo(2));
        expect(
          result.executionConcurrencyMode,
          ReferenceExtractionConcurrencyModes.single,
        );
        expect(result.executionMaxConcurrentBatches, 1);
        expect(result.allowParallelHeavyTextConsumption, isFalse);
        expect(
          result.batchPlanningMode,
          ReferenceSourceBatchPlanningModes.chapterFirst,
        );
        expect(
          result.batchGoalKind,
          ReferenceBatchGoalKinds.semanticExtraction,
        );
        expect(result.availableContextChars, 10000);
        expect(result.batchTargetSourceChars, greaterThan(0));
        expect(
          result.batchMaxSourceChars,
          greaterThanOrEqualTo(result.batchTargetSourceChars),
        );
        expect(result.completedBatchCount, result.batchCount);
        expect(result.failedBatchCount, 0);
        expect(result.pendingBatchCount, 0);
        expect(result.coveredCoverageDimensionIds, isNotEmpty);
        expect(
          result.coverageRequiresFollowup,
          result.followupSegmentIds.isNotEmpty ||
              result.uncoveredCoverageDimensionIds.isNotEmpty,
        );
        expect(
          result.runStatus,
          ReferenceExtractionRunStatuses.completedPublishable,
        );
        expect(
          result.outputCompletionStatus,
          OutputCompletionStatuses.completed,
        );
        expect(result.needsContinuation, isFalse);
        expect(File(result.stagingRunPath).existsSync(), isTrue);
        expect(
          File(
            '${result.bundleOutputDirectory}${Platform.pathSeparator}manifest.json',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${result.bundleOutputDirectory}${Platform.pathSeparator}projections${Platform.pathSeparator}summary.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          result.referenceWorkIds,
          contains('ref_reference_boundary_rule'),
        );
        expect(
          result.generatedProjectionPaths,
          contains('references/引用作品边界.md'),
        );
        final knowledgeProjectionFile = File(
          '${project.rootPath}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        );
        expect(knowledgeProjectionFile.existsSync(), isTrue);
        final legacyReferenceIndexFile = File(
          '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}reference_works${Platform.pathSeparator}index.json',
        );
        expect(legacyReferenceIndexFile.existsSync(), isFalse);
        final sqliteProjectDb = File(
          '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}sqlite${Platform.pathSeparator}novel_agent.db',
        );
        expect(sqliteProjectDb.existsSync(), isTrue);
        final substrate = SqliteReferenceEvidenceSubstrate(
          substrateRootPath:
              '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}reference_extraction${Platform.pathSeparator}substrate',
        );
        final batchState = await substrate.readBatchExecutionState(
          packageId: result.packageId,
          packageVersionId: result.packageVersionId,
        );
        expect(batchState, isNotNull);
        expect(batchState!.batchPlan.planningMode, result.batchPlanningMode);
        expect(
          batchState.batchProgress.completedBatchCount,
          result.completedBatchCount,
        );
        expect(batchState.batchProgress.totalBatches, result.batchCount);
        expect(
          batchState.coverageState?.coveredDimensionIds,
          result.coveredCoverageDimensionIds,
        );
        final continuityLedger = await substrate.readContinuityLedger(
          packageId: result.packageId,
          packageVersionId: result.packageVersionId,
        );
        expect(continuityLedger, isNotNull);
        expect(continuityLedger!.conflictClusters, isEmpty);
        expect(
          ValueReaders.stringValue(continuityLedger.metadata['source']),
          'project_reference_extraction_runtime',
        );
        expect(result.conflictClusterCount, 0);
        expect(result.reviewAlertCount, 0);
        expect(result.requiresManualContinuityReview, isFalse);
        expect(
          result.projectMountStatus,
          ProjectReferenceMountStatuses.applied,
        );
        expect(result.projectMountWarningCodes, isEmpty);
      },
    );

    test(
      'records waiting_user when mounted projection needs explicit confirmation',
      () async {
        final harness = _ContinuousTaskHarness(tempDirectory.path);
        final gatedService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  const _FakeProposalGenerator(),
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: harness.bridge,
              ),
        );

        final result = await gatedService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            exportBundle: false,
            explicitProjectionConfirmationGranted: false,
          ),
        );

        expect(result.projectMountStatus, ProjectReferenceMountStatuses.denied);
        expect(
          result.projectMountWarningCodes,
          contains('explicit_confirmation_required'),
        );
        final waitingRun = await harness.supervisor.loadRun(result.runId);
        expect(waitingRun, isNotNull);
        expect(waitingRun!.status, LongTaskRunStatus.waitingGate);
        expect(
          waitingRun.stopOutcome.category,
          LongTaskStopOutcomeCategories.waitingUser,
        );
        expect(
          waitingRun.stopOutcome.reason,
          'reference_mount_confirmation_required',
        );
        expect(
          ValueReaders.stringValue(
            waitingRun.metadata['supervisor_signal_category'],
          ),
          'mount_waiting_user',
        );
      },
    );

    test(
      'records paused mount-incomplete outcome when projection chain does not apply',
      () async {
        final harness = _ContinuousTaskHarness(tempDirectory.path);
        final mountPausedService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  const _FakeProposalGenerator(),
          mountService: _FakeMissingPackageMountService(),
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: harness.bridge,
              ),
        );

        final result = await mountPausedService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            exportBundle: false,
          ),
        );

        expect(
          result.projectMountStatus,
          ProjectReferenceMountStatuses.missingPackage,
        );
        expect(
          result.projectMountWarningCodes,
          contains('package_snapshot_missing'),
        );
        final pausedRun = await harness.supervisor.loadRun(result.runId);
        expect(pausedRun, isNotNull);
        expect(pausedRun!.status, LongTaskRunStatus.paused);
        expect(
          pausedRun.stopOutcome.category,
          LongTaskStopOutcomeCategories.constraintGatePause,
        );
        expect(pausedRun.stopOutcome.reason, 'reference_mount_incomplete');
        expect(
          ValueReaders.stringValue(
            pausedRun.metadata['supervisor_signal_category'],
          ),
          'mount_incomplete',
        );
      },
    );

    test(
      'records manual attention when continuity conflict needs canon review',
      () async {
        final harness = _ContinuousTaskHarness(tempDirectory.path);
        final conflictService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  const _FakeProposalGenerator(),
          referenceContinuityBridgeService:
              _FakeConflictContinuityBridgeService(),
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: harness.bridge,
              ),
        );

        final result = await conflictService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            exportBundle: false,
            attachToProject: false,
            projectMountedEntries: false,
          ),
        );

        expect(result.requiresManualContinuityReview, isTrue);
        expect(result.unresolvedConflictCount, 1);
        final manualRun = await harness.supervisor.loadRun(result.runId);
        expect(manualRun, isNotNull);
        expect(manualRun!.status, LongTaskRunStatus.failedManualAttention);
        expect(
          manualRun.stopOutcome.category,
          LongTaskStopOutcomeCategories.manualAttention,
        );
        expect(
          manualRun.stopOutcome.reason,
          'reference_continuity_conflict_requires_review',
        );
        expect(
          ValueReaders.stringValue(
            manualRun.metadata['supervisor_signal_category'],
          ),
          'continuity_conflict',
        );
      },
    );

    test(
      'falls back to builtin collaborator pool when project has no explicit extraction agents',
      () async {
        final fallbackService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => const <JsonMap>[],
          loadAvailableGroups: (_) async => const <JsonMap>[],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  const _FakeProposalGenerator(),
        );

        final result = await fallbackService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            exportBundle: false,
            projectMountedEntries: false,
            attachToProject: false,
          ),
        );

        expect(result.selectedGroupId.trim(), isNotEmpty);
        expect(
          result.strategyProfileId,
          ReferenceExtractionBuiltinStrategyProfileIds.standard,
        );
        expect(result.runStatus, isNotEmpty);
        expect(result.proposalCount, greaterThan(0));
      },
    );

    test(
      'reuses staged identifiers and resumes explicit runId after interrupted execution',
      () async {
        final longChapterA = List<String>.filled(320, 'A').join(' ');
        final longChapterB = List<String>.filled(320, 'B').join(' ');
        await sourceFile.writeAsString('''
CHAPTER ONE
$longChapterA

CHAPTER TWO
$longChapterB
''');
        final generator = _FailOnceResumeProposalGenerator();
        final harness = _ContinuousTaskHarness(tempDirectory.path);
        final resumeService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  generator,
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: harness.bridge,
              ),
        );

        final request = ProjectReferenceExtractionRequest(
          sourceFilePath: sourceFile.path,
          runId: 'resume_runtime_run',
          exportBundle: false,
          attachToProject: false,
          projectMountedEntries: false,
          strategyProfileId: 'reference_extraction.resume_dense',
          additionalStrategyProfiles:
              const <ReferenceExtractionStrategyProfile>[
                ReferenceExtractionStrategyProfile(
                  profileId: 'reference_extraction.resume_dense',
                  ingestionBudgetPolicy: ReferenceIngestionBudgetPolicy(
                    defaultAvailableContextChars: 10000,
                    sourceWindowRatio: 0.32,
                    minSourceChars: 500,
                    maxSourceChars: 900,
                    maxSectionsPerBatch: 1,
                    oversizeSectionMinChars: 400,
                  ),
                ),
              ],
        );

        await expectLater(
          resumeService.execute(
            project: project,
            llmGateway: _FakeLlmGateway(),
            modelId: 'fake-model',
            request: request,
          ),
          throwsStateError,
        );
        final recoveringRun = await harness.supervisor.loadRun(
          'resume_runtime_run',
        );
        expect(recoveringRun, isNotNull);
        expect(recoveringRun!.status, LongTaskRunStatus.recovering);
        expect(
          ValueReaders.stringValue(
            recoveringRun.metadata['continuous_task_family_id'],
          ),
          ContinuousTaskFamilies.referenceExtraction,
        );
        expect(
          recoveringRun.recoveryState.stopOutcome.category,
          LongTaskStopOutcomeCategories.technicalFailure,
        );
        expect(
          ValueReaders.stringValue(
            recoveringRun
                .recoveryState
                .stopOutcome
                .metadata['source_file_path'],
          ),
          sourceFile.path,
        );

        final stagingFile = File(
          '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}reference_extraction${Platform.pathSeparator}staging${Platform.pathSeparator}resume_runtime_run.json',
        );
        expect(stagingFile.existsSync(), isTrue);
        final partial = jsonDecode(await stagingFile.readAsString()) as Map;
        final partialPackageId = partial['package_id'] as String;

        final result = await resumeService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: request,
        );

        expect(result.runId, 'resume_runtime_run');
        expect(result.packageId, partialPackageId);
        expect(result.batchCount, 2);
        expect(result.batchCoverageRatio, 1);
        expect(result.completedBatchCount, 2);
        expect(result.failedBatchCount, 0);
        expect(result.pendingBatchCount, 0);
        expect(
          result.executionConcurrencyMode,
          ReferenceExtractionConcurrencyModes.single,
        );
        expect(
          generator.seenBatchIds.where((entry) => entry == 'batch_001'),
          hasLength(1),
        );
        final completedRun = await harness.supervisor.loadRun(
          'resume_runtime_run',
        );
        final shouldPause =
            result.needsContinuation || result.coverageRequiresFollowup;
        expect(completedRun, isNotNull);
        expect(
          completedRun!.status,
          shouldPause ? LongTaskRunStatus.paused : LongTaskRunStatus.stopped,
        );
        expect(
          completedRun.stopOutcome.category,
          shouldPause
              ? LongTaskStopOutcomeCategories.constraintGatePause
              : LongTaskStopOutcomeCategories.completedNaturally,
        );
      },
    );

    test(
      'persists semantic continuation status and re-enters same runId through runtime',
      () async {
        final generator = _SemanticContinuationRuntimeProposalGenerator();
        final harness = _ContinuousTaskHarness(tempDirectory.path);
        final continuationService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  generator,
          continuousTaskSyncService:
              ReferenceExtractionContinuousTaskSyncService(
                supervisorBridgeService: harness.bridge,
              ),
        );

        final request = ProjectReferenceExtractionRequest(
          sourceFilePath: sourceFile.path,
          runId: 'runtime_semantic_continue',
          exportBundle: false,
          attachToProject: false,
          projectMountedEntries: false,
        );

        final firstResult = await continuationService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: request,
        );

        expect(
          firstResult.runStatus,
          ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
        );
        expect(firstResult.needsContinuation, isTrue);
        expect(firstResult.continuationRoundCount, 0);
        final pausedRun = await harness.supervisor.loadRun(
          'runtime_semantic_continue',
        );
        expect(pausedRun, isNotNull);
        expect(pausedRun!.status, LongTaskRunStatus.paused);
        expect(
          pausedRun.stopOutcome.category,
          LongTaskStopOutcomeCategories.constraintGatePause,
        );
        expect(
          pausedRun.stopOutcome.reason,
          'reference_coverage_followup_required',
        );
        expect(
          ValueReaders.stringValue(
            pausedRun.metadata['supervisor_signal_category'],
          ),
          'coverage_followup',
        );

        final secondResult = await continuationService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: request,
        );

        expect(generator.callCount, 2);
        expect(
          secondResult.runStatus,
          ReferenceExtractionRunStatuses.completedPublishable,
        );
        expect(secondResult.continuationRoundCount, 1);
        expect(secondResult.needsContinuation, isFalse);
        expect(secondResult.publishedSnapshotAvailable, isTrue);
        final stagingDocument =
            jsonDecode(await File(secondResult.stagingRunPath).readAsString())
                as Map<String, Object?>;
        expect(
          ValueReaders.stringValue(stagingDocument['run_status']),
          ReferenceExtractionRunStatuses.completedPublishable,
        );
        expect(
          ValueReaders.objectList(stagingDocument['continuation_contexts']),
          hasLength(1),
        );
        final completedRun = await harness.supervisor.loadRun(
          'runtime_semantic_continue',
        );
        expect(completedRun, isNotNull);
        expect(completedRun!.status, LongTaskRunStatus.stopped);
      },
    );

    test(
      'keeps incomplete result in staging and skips export plus project projection',
      () async {
        final incompleteService = ProjectReferenceExtractionRuntimeService(
          workspacePort: workspacePort,
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extractor',
              'name': '参考资产提取师',
              'role': '负责参考资产提取。',
            },
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reference_extraction_group',
              'name': '参考资产提取组',
              'description': '面向参考资产提取的智能体组。',
              'agents': <Object?>['reference_extractor'],
              'metadata': <String, Object?>{
                'task_family_ids': <String>[
                  AgentTaskFamilies.referenceExtraction,
                ],
              },
              'allowed_project_type_ids': <String>['novel'],
            },
          ],
          groupBindingRepository: groupBindingRepository,
          proposalGeneratorFactory:
              ({required LlmGateway llmGateway, required String modelId}) =>
                  const _IncompleteProposalGenerator(),
        );

        final result = await incompleteService.execute(
          project: project,
          llmGateway: _FakeLlmGateway(),
          modelId: 'fake-model',
          request: ProjectReferenceExtractionRequest(
            sourceFilePath: sourceFile.path,
            bundleOutputDirectory:
                '${tempDirectory.path}${Platform.pathSeparator}incomplete_bundle',
          ),
        );

        expect(
          result.deliveryStatus,
          ReferenceExtractionDeliveryStatuses.stagingOnly,
        );
        expect(
          result.runStatus,
          ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
        );
        expect(
          result.outputCompletionStatus,
          OutputCompletionStatuses.continuationRecommended,
        );
        expect(result.coverageRequiresFollowup, isTrue);
        expect(result.uncoveredCoverageDimensionIds, isNotEmpty);
        expect(result.needsContinuation, isTrue);
        expect(result.publishedSnapshotAvailable, isFalse);
        expect(
          result.projectMountStatus,
          ProjectReferenceMountStatuses.snapshotUnavailable,
        );
        expect(
          result.projectMountWarningCodes,
          contains('published_snapshot_unavailable'),
        );
        expect(result.finalizedEntryCount, 0);
        expect(result.bundleOutputDirectory, isEmpty);
        expect(result.knowledgeCardIds, isEmpty);
        expect(result.referenceWorkIds, isEmpty);
        expect(
          File(
            '${tempDirectory.path}${Platform.pathSeparator}incomplete_bundle${Platform.pathSeparator}manifest.json',
          ).existsSync(),
          isFalse,
        );
        final sqliteProjectDb = File(
          '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}sqlite${Platform.pathSeparator}novel_agent.db',
        );
        expect(sqliteProjectDb.existsSync(), isFalse);
        final knowledgeProjectionFile = File(
          '${project.rootPath}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        );
        expect(knowledgeProjectionFile.existsSync(), isFalse);
        expect(File(result.stagingRunPath).existsSync(), isTrue);
        final stagingDocument =
            jsonDecode(await File(result.stagingRunPath).readAsString())
                as Map<String, Object?>;
        expect(
          ValueReaders.stringValue(stagingDocument['output_completion_status']),
          OutputCompletionStatuses.continuationRecommended,
        );
        expect(
          ValueReaders.mapValue(stagingDocument['finalized_snapshot']).isEmpty,
          isTrue,
        );
      },
    );
  });
}

class _ContinuousTaskHarness {
  factory _ContinuousTaskHarness(String settingsRootPath) {
    final registry = LocalLongTaskRunRegistry(
      settingsRootPath: settingsRootPath,
    );
    final watchdog = LongTaskWatchdog(
      runRegistry: registry,
      heartbeatScheduler: LongTaskHeartbeatScheduler(
        runRegistry: registry,
        runtimeBaselineCatalogService: const RuntimeBaselineCatalogService(),
      ),
    );
    final supervisor = LongTaskSupervisor(
      runRegistry: registry,
      watchdogDispatchPort: watchdog,
    );
    return _ContinuousTaskHarness._(
      registry: registry,
      supervisor: supervisor,
      bridge: ContinuousTaskSupervisorBridgeService(supervisor: supervisor),
    );
  }

  const _ContinuousTaskHarness._({
    required this.registry,
    required this.supervisor,
    required this.bridge,
  });

  final LocalLongTaskRunRegistry registry;
  final LongTaskSupervisor supervisor;
  final ContinuousTaskSupervisorBridgeService bridge;
}

class _FakeProposalGenerator implements ReferenceExtractionProposalGenerator {
  const _FakeProposalGenerator();

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    final seedEntries = request.seedSnapshot.entries;
    final primarySeed = seedEntries.first;
    final secondarySeed = seedEntries.length > 1
        ? seedEntries[1]
        : seedEntries.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_fact_1',
          entryId: 'privet_drive_fact',
          entryNamespace: 'semantic_extraction',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '女贞路四号基础事实',
          summary: '德思礼一家与哈利长期共同生活在女贞路四号。',
          payload: const <String, Object?>{
            'seed_entry_ids': <String>['chapter_01', 'chapter_02'],
          },
          sourceRefs: primarySeed.sourceRefs,
          evidenceRefs: primarySeed.evidenceRefs,
          tags: const <String>['哈利', '女贞路'],
          coverageDimensionIds: const <String>[
            'character_fact',
            'setting_or_object',
            'plot_or_mechanism',
          ],
          confidence: 0.84,
        ),
        ReferenceExtractionProposal(
          proposalId: 'proposal_boundary_1',
          entryId: 'reference_boundary_rule',
          entryNamespace: 'semantic_extraction',
          entryKind: ReferenceEntryKinds.referenceWorkBoundary,
          title: '参考提取结果使用边界',
          summary: '提取结果可用于内部创作分析，不应替代原文直接引用。',
          payload: const <String, Object?>{
            'relationship_to_project': 'reference_work_package',
            'declared_usage_intent': '内部分析与风格参考',
            'risk_notes': <Object?>['原文直接引用仍需额外确认'],
          },
          sourceRefs: secondarySeed.sourceRefs,
          evidenceRefs: secondarySeed.evidenceRefs,
          tags: const <String>['引用边界'],
          coverageDimensionIds: const <String>['timeline_or_boundary'],
          confidence: 0.88,
        ),
      ],
    );
  }
}

class _FailOnceResumeProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  final List<String> seenBatchIds = <String>[];
  bool _thrown = false;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    seenBatchIds.add(request.batch.batchId);
    if (!_thrown && request.batch.batchId == 'batch_002') {
      _thrown = true;
      throw StateError('simulated runtime resume failure');
    }
    final seedEntries = request.seedSnapshot.entries;
    final primarySeed = seedEntries.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_${request.batch.batchId}',
          entryId: 'entry_${request.batch.batchId}',
          entryNamespace: 'resume_runtime',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '续跑 ${request.batch.batchId}',
          summary: '验证 project runtime 使用同一 runId 续跑。',
          sourceRefs: primarySeed.sourceRefs,
          evidenceRefs: primarySeed.evidenceRefs,
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.86,
        ),
      ],
    );
  }
}

class _IncompleteProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  const _IncompleteProposalGenerator();

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    final primarySeed = request.seedSnapshot.entries.first;
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'proposal_incomplete',
          entryId: 'entry_incomplete',
          entryNamespace: 'semantic_extraction',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '局部角色事实',
          summary: '当前批次只抽出一个局部角色事实。',
          sourceRefs: primarySeed.sourceRefs,
          evidenceRefs: primarySeed.evidenceRefs,
          coverageDimensionIds: const <String>['character_fact'],
          confidence: 0.91,
        ),
      ],
      omissionReport: const OmissionReport(
        reportId: 'omission_incomplete',
        contractId: 'reference_extraction.standard',
        omittedDimensionIds: <String>['plot_or_mechanism', 'setting_or_object'],
        reasonCode: OmissionReasonCodes.outputBudgetExhausted,
        summary: '当前批次没有展开关键机制和地点。',
        recommendedNextFocus: '补提地点与机制。',
      ),
      continuationRequest: const ContinuationRequest(
        requestId: 'continue_incomplete',
        contractId: 'reference_extraction.standard',
        continuationReason: '当前批次仍有关键维度缺口',
        missingDimensionIds: <String>['plot_or_mechanism', 'setting_or_object'],
        recommendedNextFocus: '优先补提关键机制与地点。',
        suggestedSlotCount: 2,
      ),
    );
  }
}

class _FakeMissingPackageMountService
    extends ProjectReferenceExtractionMountService {
  _FakeMissingPackageMountService()
    : super(workspacePort: LocalProjectWorkspacePort());

  @override
  Future<ProjectReferenceMountOutcome> attachAndProjectIfRequested({
    required ProjectDescriptor project,
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceExtractionRequest request,
    required String packageId,
    required String packageVersionId,
    required String displayName,
    required String attachedAt,
  }) async {
    return const ProjectReferenceMountOutcome(
      status: ProjectReferenceMountStatuses.missingPackage,
      warningCodes: <String>['package_snapshot_missing'],
      projectionResult: ReferenceProjectionResult(
        status: ReferenceProjectionStatuses.missingPackage,
        packageId: 'pkg_missing_projection',
        packageVersionId: 'v1',
        warnings: <String>['package_snapshot_missing'],
      ),
    );
  }
}

class _FakeConflictContinuityBridgeService
    extends ProjectReferenceContinuityBridgeService {
  @override
  Future<ReferenceEvidenceContinuityLedger> ensureLedger({
    required ReferenceEvidenceSubstrate substrate,
    required String packageId,
    required String packageVersionId,
    String updatedAt = '',
    JsonMap metadata = const <String, Object?>{},
  }) async {
    final ledger = ReferenceEvidenceContinuityLedger(
      packageId: packageId,
      packageVersionId: packageVersionId,
      conflictClusters: <NarrativeConflictCluster>[
        NarrativeConflictCluster.fromJson(<String, Object?>{
          'cluster_id': 'cluster_runtime_conflict_1',
          'subject_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.asset,
            'ref_id': 'harry',
          },
          'attribute_key': 'wand_owner',
          'classification':
              NarrativeConflictClassifications.unexplainedConflict,
          'cluster_status': NarrativeConflictClusterStatuses.needsDecision,
          'summary': '魔杖归属仍存在冲突。',
          'fact_evidences': <Object?>[
            <String, Object?>{
              'fact_evidence_id': 'fact_runtime_conflict_1',
              'subject_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'harry',
              },
              'attribute_key': 'wand_owner',
              'value_payload': <String, Object?>{'value': 'Harry'},
              'value_summary': 'Harry 持有冬青木魔杖',
              'claim_snapshot': <String, Object?>{
                'claim_id': 'claim_runtime_conflict_1',
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
                'source_id': packageId,
              },
            },
          ],
        }),
      ],
      canonDecisions: <ProjectCanonDecision>[
        ProjectCanonDecision.fromJson(<String, Object?>{
          'decision_id': 'decision_runtime_conflict_1',
          'cluster_id': 'cluster_runtime_conflict_1',
          'decision_kind': ProjectCanonDecisionKinds.deferUnresolved,
          'decided_at': '2026-06-09T09:00:00Z',
          'review_required': true,
        }),
      ],
      reviewAlerts: <ContinuityReviewAlert>[
        ContinuityReviewAlert.fromJson(<String, Object?>{
          'alert_id': 'alert_runtime_conflict_1',
          'cluster_id': 'cluster_runtime_conflict_1',
          'alert_kind': ContinuityReviewAlertKinds.unresolvedConflict,
          'severity': ContinuityReviewAlertSeverities.high,
          'summary': '当前参考包仍需项目级 canon 决议。',
          'requires_manual_review': true,
          'source': <String, Object?>{
            'source_type': 'reference_package',
            'source_id': packageId,
          },
        }),
      ],
      updatedAt: updatedAt.isEmpty ? '2026-06-09T09:05:00Z' : updatedAt,
      metadata: <String, Object?>{
        'source': 'fake_conflict_continuity_bridge',
        ...metadata,
      },
    );
    await substrate.upsertContinuityLedger(ledger);
    return ledger;
  }
}

class _SemanticContinuationRuntimeProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  int callCount = 0;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    callCount += 1;
    final primarySeed = request.seedSnapshot.entries.first;
    if (request.continuationContext == null) {
      return ReferenceExtractionProposalGenerationResult(
        proposals: <ReferenceExtractionProposal>[
          ReferenceExtractionProposal(
            proposalId: 'runtime_initial_character',
            entryId: 'runtime_initial_character',
            entryNamespace: 'semantic_runtime',
            entryKind: ReferenceEntryKinds.knowledgeFact,
            title: '首轮角色事实',
            summary: '先覆盖角色事实。',
            sourceRefs: primarySeed.sourceRefs,
            evidenceRefs: primarySeed.evidenceRefs,
            coverageDimensionIds: const <String>['character_fact'],
            confidence: 0.91,
          ),
        ],
        omissionReport: const OmissionReport(
          reportId: 'runtime_omission_1',
          contractId: 'reference_extraction.standard',
          omittedDimensionIds: <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          reasonCode: OmissionReasonCodes.outputBudgetExhausted,
          summary: '首轮只覆盖角色事实。',
          recommendedNextFocus: '补提地点与机制。',
          metadata: <String, Object?>{'batch_id': 'batch_001'},
        ),
        continuationRequest: const ContinuationRequest(
          requestId: 'runtime_continue_1',
          contractId: 'reference_extraction.standard',
          continuationReason: '仍缺地点与机制',
          missingDimensionIds: <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          recommendedNextFocus: '优先补提地点与机制。',
          suggestedSlotCount: 2,
          metadata: <String, Object?>{'batch_id': 'batch_001'},
        ),
      );
    }
    return ReferenceExtractionProposalGenerationResult(
      proposals: <ReferenceExtractionProposal>[
        ReferenceExtractionProposal(
          proposalId: 'runtime_continued_dimensions',
          entryId: 'runtime_continued_dimensions',
          entryNamespace: 'semantic_runtime',
          entryKind: ReferenceEntryKinds.knowledgeFact,
          title: '续提补齐地点与机制',
          summary: '第二轮补齐地点与机制维度。',
          sourceRefs: primarySeed.sourceRefs,
          evidenceRefs: primarySeed.evidenceRefs,
          coverageDimensionIds: const <String>[
            'setting_or_object',
            'plot_or_mechanism',
          ],
          confidence: 0.93,
        ),
      ],
    );
  }
}

class _FakeLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) {
    throw UnimplementedError();
  }
}
