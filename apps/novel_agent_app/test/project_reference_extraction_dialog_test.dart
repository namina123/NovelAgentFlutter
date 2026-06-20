import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/app/layout/app_layout_metrics.dart';
import 'package:novel_agent_app/app/layout/app_layout_mode.dart';
import 'package:novel_agent_app/app/layout/app_layout_scope.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/project_assets/application/controllers/project_assets_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_loader_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_reference_extraction_strategy_picker_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/project_assets_toolbar.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  testWidgets('toolbar dialog forwards selected extraction strategy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = _RecordingProjectAssetsController();
    final viewData = ProjectAssetsViewData.initial().copyWithForTest(
      referenceExtractionStrategyPicker:
          const ProjectReferenceExtractionStrategyPickerViewData(
            selectedProfileId:
                ReferenceExtractionBuiltinStrategyProfileIds.standard,
            summary: '这是手动触发的知识提取流程。当前默认使用标准提取；开始前可以切换策略。',
            sourceHint: '当前项目会在开始后要求选择源资料文件；提取结果会沉淀为正式知识资产，而不是停留在临时摘要里。',
            confirmButtonLabel: '选择资料并开始提取',
            options: <ProjectReferenceExtractionStrategyOptionViewData>[
              ProjectReferenceExtractionStrategyOptionViewData(
                profileId:
                    ReferenceExtractionBuiltinStrategyProfileIds.standard,
                displayName: '标准提取',
                summary: '默认策略',
                proposalCountLabel: '4-6 条候选',
                entryKindsLabel: '知识事实、设计元素、风格技法、引用边界',
                reviewPolicyLabel: '接纳 >= 0.78，候选 >= 0.55，要求证据',
                badgeLabel: '内置',
              ),
              ProjectReferenceExtractionStrategyOptionViewData(
                profileId:
                    ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
                displayName: '事实优先',
                summary: '优先事实',
                proposalCountLabel: '3-4 条候选',
                entryKindsLabel: '知识事实、引用边界',
                reviewPolicyLabel: '接纳 >= 0.82，候选 >= 0.62，要求证据',
                badgeLabel: '内置',
              ),
            ],
          ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1600,
              height: 120,
              child: AppLayoutScope(
                metrics: const AppLayoutMetrics(
                  size: Size(1600, 120),
                  shortestSide: 120,
                  orientation: Orientation.landscape,
                  viewInsetsBottom: 0,
                  devicePixelRatio: 1,
                  mode: AppLayoutMode.expanded,
                  isTabletLike: true,
                ),
                child: ProjectAssetsToolbar(
                  controller: controller,
                  viewData: viewData,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('知识提取'));
    await tester.pumpAndSettle();

    expect(find.text('知识提取'), findsNWidgets(2));
    expect(find.text('选择资料并开始提取'), findsOneWidget);
    await tester.tap(find.text('事实优先').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择资料并开始提取'));
    await tester.pumpAndSettle();

    expect(
      controller.lastRequestedStrategyProfileId,
      ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
    );
  });
}

class _RecordingProjectAssetsController extends ProjectAssetsController {
  _RecordingProjectAssetsController()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => null,
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

  String lastRequestedStrategyProfileId = '';

  @override
  Future<void> onProjectAssetsExtractReferenceRequested({
    String strategyProfileId = '',
  }) async {
    lastRequestedStrategyProfileId = strategyProfileId;
  }
}

class _NoopProjectAssetLibraryService extends ProjectAssetLibraryService {
  _NoopProjectAssetLibraryService()
    : super(
        workspacePort: _NoopProjectWorkspacePort(),
        projectToolHostPort: _NoopProjectToolHostPort(),
      );
}

class _NoopProjectAssetsLoaderService extends ProjectAssetsLoaderService {
  _NoopProjectAssetsLoaderService()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        timelineRepository: _NoopProjectTimelineRepository(),
        relationshipRepository: _NoopProjectRelationshipRepository(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
      );

  @override
  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    return ProjectAssetsCatalog.empty();
  }
}

ProjectReferenceExtractionExecutionService _noopReferenceExtractionService() {
  return ProjectReferenceExtractionExecutionService(
    readSettings: () => null,
    llmGatewayFactory: (_, networkSettings) => _NoopLlmGateway(),
    executeReferenceExtraction:
        ({
          required project,
          required llmGateway,
          required modelId,
          required request,
        }) async => throw UnimplementedError(),
  );
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}
}

class _NoopProjectTimelineRepository extends ProjectTimelineRepository {
  _NoopProjectTimelineRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopProjectRelationshipRepository extends ProjectRelationshipRepository {
  _NoopProjectRelationshipRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopLlmGateway implements LlmGateway {
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

extension on ProjectAssetsViewData {
  ProjectAssetsViewData copyWithForTest({
    ProjectReferenceExtractionStrategyPickerViewData?
    referenceExtractionStrategyPicker,
  }) {
    return ProjectAssetsViewData(
      title: title,
      description: description,
      status: status,
      useDedicatedRagWorkspace: useDedicatedRagWorkspace,
      activeTabId: activeTabId,
      entryAgentContextId: entryAgentContextId,
      tabs: tabs,
      entries: entries,
      inspector: inspector,
      timeline: timeline,
      graph: graph,
      styleEditor: styleEditor,
      expressionConstraintEditor: expressionConstraintEditor,
      foreshadowEditor: foreshadowEditor,
      referenceExtractionStrategyPicker:
          referenceExtractionStrategyPicker ??
          this.referenceExtractionStrategyPicker,
      ragExtraction: ragExtraction,
      isLoading: isLoading,
    );
  }
}
