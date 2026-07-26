import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_step_id.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_workflow_recovery_state.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirmation_journal_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('BookDeconstructionController confirmation recovery', () {
    test('restores a matching pending confirmation as retryable', () async {
      final controller = await _createRecoveredController(
        journal: const BookDeconstructionConfirmationJournalService().pending(
          confirmationId: 'pending-confirmation',
          extractionId: _splitExtractionId,
          targetWritingProjectTypeId: 'novel',
          targetRuntimeBaselineId: '',
          selectedItemIds: const <String>{},
          inheritAsLiveNarrative: false,
          currentStep: 'persist_selected_chapters',
        ),
      );
      addTearDown(controller.dispose);

      expect(
        controller.viewData.activeStepId,
        BookDeconstructionStepId.confirmSelection,
      );
      expect(controller.viewData.confirmedPreviewPath, isEmpty);
      expect(controller.viewData.status, contains('检测到上次确认未完成'));
      expect(controller.viewData.status, contains('persist_selected_chapters'));
      expect(controller.viewData.status, contains('重新确认'));
    });

    test(
      'restores a matching failed confirmation with its failure context',
      () async {
        final controller = await _createRecoveredController(
          journal: const BookDeconstructionConfirmationJournalService().failed(
            confirmationId: 'failed-confirmation',
            extractionId: _splitExtractionId,
            targetWritingProjectTypeId: 'novel',
            targetRuntimeBaselineId: '',
            selectedItemIds: const <String>{},
            inheritAsLiveNarrative: false,
            currentStep: 'transition_project_type',
            completedSteps: const <String>['write_preview'],
            changedPaths: const <String>[
              'analysis/book_deconstruction_preview.md',
            ],
            chapterPaths: const <String>[],
            projectTypeTransitioned: false,
            error: StateError('类型转换失败'),
          ),
        );
        addTearDown(controller.dispose);

        expect(
          controller.viewData.activeStepId,
          BookDeconstructionStepId.confirmSelection,
        );
        expect(controller.viewData.confirmedPreviewPath, isEmpty);
        expect(controller.viewData.status, contains('检测到上次确认失败'));
        expect(controller.viewData.status, contains('transition_project_type'));
        expect(controller.viewData.status, contains('类型转换失败'));
      },
    );

    test('restores a matching completed confirmation preview', () async {
      final controller = await _createRecoveredController(
        journal: const BookDeconstructionConfirmationJournalService().completed(
          confirmationId: 'completed-confirmation',
          extractionId: _splitExtractionId,
          targetWritingProjectTypeId: 'novel',
          targetRuntimeBaselineId: '',
          selectedItemIds: const <String>{},
          inheritAsLiveNarrative: false,
          completedSteps: const <String>['write_preview'],
          changedPaths: const <String>[
            'analysis/book_deconstruction_preview.md',
          ],
          chapterPaths: const <String>[],
          projectTypeTransitioned: false,
          previewPath: 'analysis/book_deconstruction_preview.md',
        ),
      );
      addTearDown(controller.dispose);

      expect(
        controller.viewData.activeStepId,
        BookDeconstructionStepId.confirmSelection,
      );
      expect(
        controller.viewData.confirmedPreviewPath,
        'analysis/book_deconstruction_preview.md',
      );
      expect(controller.viewData.status, contains('已恢复已确认的拆书结果'));
    });

    test(
      'does not restore a completed preview after confirmation inputs change',
      () async {
        final controller = await _createRecoveredController(
          recoveryState: _recoveryState(inheritAsLiveNarrative: true),
          journal: const BookDeconstructionConfirmationJournalService()
              .completed(
                confirmationId: 'completed-confirmation-with-stale-payload',
                extractionId: _splitExtractionId,
                targetWritingProjectTypeId: 'novel',
                targetRuntimeBaselineId: '',
                selectedItemIds: <String>{},
                inheritAsLiveNarrative: false,
                completedSteps: <String>['write_preview'],
                changedPaths: <String>[
                  'analysis/book_deconstruction_preview.md',
                ],
                chapterPaths: <String>[],
                projectTypeTransitioned: false,
                previewPath: 'analysis/book_deconstruction_preview.md',
              ),
        );
        addTearDown(controller.dispose);

        expect(controller.viewData.confirmedPreviewPath, isEmpty);
        expect(controller.viewData.status, isNot(contains('已恢复已确认的拆书结果')));
        expect(controller.viewData.status, contains('已恢复上次拆书结果'));
      },
    );

    test(
      'does not restore a historical completed preview with a stale long-novel baseline',
      () async {
        const project = ProjectDescriptor(
          id: 'project-confirmation-recovery-long-novel',
          name: '长篇确认恢复测试',
          rootPath:
              'D:/Projects/deconstruction_confirmation_recovery_long_novel',
          projectType: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
          additionalTraitIds: <String>['book_deconstruction'],
        );
        final controller = await _createRecoveredController(
          project: project,
          recoveryState: _recoveryState(
            targetWritingTypeId: 'long_novel',
            targetRuntimeBaselineId: 'chapter_collaboration_autorun',
            confirmedPreviewPath: 'analysis/book_deconstruction_preview.md',
          ),
          journal: const BookDeconstructionConfirmationJournalService()
              .completed(
                confirmationId: 'completed-confirmation-with-stale-baseline',
                extractionId: _splitExtractionId,
                targetWritingProjectTypeId: 'long_novel',
                targetRuntimeBaselineId: 'chapter_collaboration_autorun',
                selectedItemIds: <String>{},
                inheritAsLiveNarrative: false,
                completedSteps: <String>['write_preview'],
                changedPaths: <String>[
                  'analysis/book_deconstruction_preview.md',
                ],
                chapterPaths: <String>[],
                projectTypeTransitioned: false,
                previewPath: 'analysis/book_deconstruction_preview.md',
              ),
        );
        addTearDown(controller.dispose);

        expect(
          controller.viewData.selectedTargetRuntimeBaselineId,
          'continuous_autonomous',
        );
        expect(controller.viewData.confirmedPreviewPath, isEmpty);
        expect(controller.viewData.status, isNot(contains('已恢复已确认的拆书结果')));
        expect(controller.viewData.status, contains('已恢复上次拆书结果'));
      },
    );

    test(
      'persists the explicit staged-analysis apply selection and identity',
      () {
        const state = BookDeconstructionWorkflowRecoveryState(
          sourceAbsolutePath: '',
          sourceTitle: '可恢复原文',
          sourceContent: _sourceContent,
          splitSourceContent: _sourceContent,
          splitExtractionId: _splitExtractionId,
          splitContinuationDirectionId: 'analysisFirst',
          splitUseModel: false,
          splitModelOptionKey: '',
          analysisUseModel: true,
          analysisModelOptionKey: 'provider::model',
          analysisCompleted: true,
          analysisStatusMessage: '暂存完成',
          analysisStagingRunId: 'staged-run-recovery',
          analysisStagingPackageId: 'staged-package-recovery',
          analysisStagingPackageVersionId: 'staged-version-recovery',
          applyStagedAnalysisResults: true,
          selectedItemIds: <String>['item-1'],
          selectedFollowupOptionId: 'continuation_novel',
          selectedTargetWritingTypeId: 'novel',
          selectedTargetRuntimeBaselineId: '',
          inheritAsLiveNarrative: false,
          confirmedPreviewPath: '',
          activeStepId: BookDeconstructionStepId.confirmSelection,
        );

        final restored = BookDeconstructionWorkflowRecoveryState.tryParse(
          state.encode(),
        );

        expect(restored, isNotNull);
        expect(restored!.analysisStagingRunId, 'staged-run-recovery');
        expect(restored.analysisStagingPackageId, 'staged-package-recovery');
        expect(
          restored.analysisStagingPackageVersionId,
          'staged-version-recovery',
        );
        expect(restored.applyStagedAnalysisResults, isTrue);
      },
    );
  });
}

const _splitExtractionId = 'extract-recovery-confirmation';
const _sourceContent = '第一章 回航\n拆书恢复后应可继续确认。';

Future<BookDeconstructionController> _createRecoveredController({
  required String journal,
  BookDeconstructionWorkflowRecoveryState? recoveryState,
  ProjectDescriptor? project,
}) async {
  final workspacePort = _MemoryProjectWorkspacePort();
  const defaultProject = ProjectDescriptor(
    id: 'project-confirmation-recovery',
    name: '确认恢复测试',
    rootPath: 'D:/Projects/deconstruction_confirmation_recovery',
    projectType: 'novel',
  );
  final currentProject = project ?? defaultProject;
  await workspacePort.writeTextFile(
    currentProject.rootPath,
    BookDeconstructionWorkflowRecoveryState.relativePath,
    (recoveryState ?? _recoveryState()).encode(),
  );
  await workspacePort.writeTextFile(
    currentProject.rootPath,
    BookDeconstructionConfirmationJournalService.relativePath,
    journal,
  );
  final controller = BookDeconstructionController(
    readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
    writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
      projectWorkspacePort: workspacePort,
    ),
    narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
      workspacePort: workspacePort,
    ),
    readCurrentProject: () => currentProject,
    syncWorkbenchResources: () async {},
    onBackRequested: () {},
    readImportAssistantModelOptions: () => const [],
  );
  await controller.initialize();
  return controller;
}

BookDeconstructionWorkflowRecoveryState _recoveryState({
  bool inheritAsLiveNarrative = false,
  String targetWritingTypeId = 'novel',
  String targetRuntimeBaselineId = '',
  String confirmedPreviewPath = '',
}) {
  return BookDeconstructionWorkflowRecoveryState(
    sourceAbsolutePath: '',
    sourceTitle: '可恢复原文',
    sourceContent: _sourceContent,
    splitSourceContent: _sourceContent,
    splitExtractionId: _splitExtractionId,
    splitContinuationDirectionId: 'analysisFirst',
    splitUseModel: false,
    splitModelOptionKey: '',
    analysisUseModel: false,
    analysisModelOptionKey: '',
    analysisCompleted: false,
    analysisStatusMessage: '',
    selectedItemIds: const <String>[],
    selectedFollowupOptionId: 'continuation_novel',
    selectedTargetWritingTypeId: targetWritingTypeId,
    selectedTargetRuntimeBaselineId: targetRuntimeBaselineId,
    inheritAsLiveNarrative: inheritAsLiveNarrative,
    confirmedPreviewPath: confirmedPreviewPath,
    activeStepId: BookDeconstructionStepId.confirmSelection,
  );
}

class _MemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _files[_key(rootPath, relativePath)];
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[_key(rootPath, relativePath)] = content;
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
