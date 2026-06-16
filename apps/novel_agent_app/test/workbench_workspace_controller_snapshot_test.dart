import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/workbench_workspace_controller.dart';
import 'package:novel_agent_app/features/workbench/application/models/open_document_state.dart';
import 'package:novel_agent_app/features/workbench/application/models/workbench_project_runtime_state.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkbenchWorkspaceController snapshot', () {
    test(
      'restoreWorkbenchSnapshot restores selected conversation agent id',
      () async {
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: 'D:/Projects/novel_project',
            selectedConversationAgentId: 'reviewer',
            expandedDirectories: const <String>['docs'],
          ),
          workbench: WorkbenchViewData.initial(),
          projectState: WorkbenchProjectRuntimeState(
            resourceSnapshotEntries: const <JsonMap>[
              <String, Object?>{'relative_path': 'docs', 'is_dir': true},
            ],
          ),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project('D:/Projects/novel_project'),
        );

        expect(harness.workbench.agentSelector.currentAgentId, 'reviewer');
        expect(harness.projectState.expandedResourceDirectories, <String>{
          'docs',
        });
      },
    );

    test(
      'restoreWorkbenchSnapshot ignores snapshot from another project',
      () async {
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: 'D:/Projects/project_a',
            selectedConversationAgentId: 'reviewer',
          ),
          workbench: WorkbenchViewData.initial().copyWith(
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '作者智能体',
              currentAgentId: 'writer',
              currentAgentDescription: '正文创作',
              agentOptions: <SelectorOptionViewData>[],
              canSwitchAgent: false,
            ),
          ),
          projectState: const WorkbenchProjectRuntimeState(),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project('D:/Projects/project_b'),
        );

        expect(harness.workbench.agentSelector.currentAgentId, 'writer');
        expect(harness.savedSettings, isEmpty);
      },
    );

    test('persisted snapshot includes selected conversation agent id', () {
      final harness = _ControllerHarness(
        settings: _baseSettings(),
        workbench: WorkbenchViewData.initial().copyWith(
          projectPath: 'D:/Projects/novel_project',
          activeDocumentPath: 'chapters/chapter_01.md',
          agentSelector: const ConversationAgentSelectorViewData(
            currentAgentLabel: '审阅智能体',
            currentAgentId: 'reviewer',
            currentAgentDescription: '质量审阅',
            agentOptions: <SelectorOptionViewData>[],
            canSwitchAgent: false,
          ),
        ),
        projectState: WorkbenchProjectRuntimeState(
          currentProject: _project('D:/Projects/novel_project'),
          openDocuments: const <OpenDocumentState>[
            OpenDocumentState(
              id: 'doc-1',
              title: 'Chapter 1',
              relativePath: 'chapters/chapter_01.md',
              content: 'body',
            ),
            OpenDocumentState(
              id: 'doc-2',
              title: 'Chapter 2',
              relativePath: 'chapters/chapter_02.md',
              content: 'body 2',
            ),
          ],
          activeOpenDocumentId: 'doc-1',
          expandedResourceDirectories: const <String>{'chapters'},
        ),
      );

      harness.controller.onDocumentSelected('doc-2');

      expect(harness.savedSettings, isNotEmpty);
      final snapshot = _mapValue(
        harness.savedSettings.last.extraSettings['workbench_state'],
      );
      expect(snapshot['project_root_path'], 'D:/Projects/novel_project');
      expect(snapshot['active_document_path'], 'chapters/chapter_02.md');
      expect(snapshot['selected_conversation_agent_id'], 'reviewer');
      expect(
        ValueReaders.stringList(snapshot['expanded_directories']),
        <String>['chapters'],
      );
      expect(ValueReaders.mapList(snapshot['draft_recoveries']), isEmpty);
    });

    test(
      'persisted snapshot keeps dirty content documents as draft recovery',
      () {
        final harness = _ControllerHarness(
          settings: _baseSettings(),
          workbench: WorkbenchViewData.initial().copyWith(
            projectPath: 'D:/Projects/novel_project',
            activeDocumentPath: 'chapters/chapter_01.md',
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '审阅智能体',
              currentAgentId: 'reviewer',
              currentAgentDescription: '质量审阅',
              agentOptions: <SelectorOptionViewData>[],
              canSwitchAgent: false,
            ),
          ),
          projectState: WorkbenchProjectRuntimeState(
            currentProject: _project('D:/Projects/novel_project'),
            openDocuments: const <OpenDocumentState>[
              OpenDocumentState(
                id: 'doc-1',
                title: 'Chapter 1',
                relativePath: 'chapters/chapter_01.md',
                content: '旧内容',
                isDirty: true,
              ),
              OpenDocumentState(
                id: 'doc-2',
                title: 'Chapter 2',
                relativePath: 'chapters/chapter_02.md',
                content: 'body 2',
              ),
            ],
            activeOpenDocumentId: 'doc-1',
            expandedResourceDirectories: const <String>{'chapters'},
          ),
        );

        harness.controller.onDocumentBodyChanged('新的未保存正文');
        harness.controller.onDocumentSelected('doc-2');

        final snapshot = _mapValue(
          harness.savedSettings.last.extraSettings['workbench_state'],
        );
        final recoveries = ValueReaders.mapList(snapshot['draft_recoveries']);
        expect(recoveries, hasLength(1));
        expect(
          ValueReaders.stringValue(recoveries.single['relative_path']),
          'chapters/chapter_01.md',
        );
        expect(
          ValueReaders.stringValue(recoveries.single['content']),
          '新的未保存正文',
        );
      },
    );

    test('persisted snapshot drops hidden internal active document path', () {
      final harness = _ControllerHarness(
        settings: _baseSettings(),
        workbench: WorkbenchViewData.initial().copyWith(
          projectPath: 'D:/Projects/novel_project',
          activeDocumentPath: '.novel_agent/state/characters/lin/history.md',
          agentSelector: const ConversationAgentSelectorViewData(
            currentAgentLabel: '审阅智能体',
            currentAgentId: 'reviewer',
            currentAgentDescription: '质量审阅',
            agentOptions: <SelectorOptionViewData>[],
            canSwitchAgent: false,
          ),
        ),
        projectState: WorkbenchProjectRuntimeState(
          currentProject: _project('D:/Projects/novel_project'),
          openDocuments: const <OpenDocumentState>[
            OpenDocumentState(
              id: 'doc-hidden',
              title: 'history',
              relativePath: '.novel_agent/state/characters/lin/history.md',
              content: 'body',
            ),
          ],
          activeOpenDocumentId: '',
          expandedResourceDirectories: const <String>{'drafts'},
        ),
      );

      harness.controller.onDocumentSelected('doc-hidden');

      final snapshot = _mapValue(
        harness.savedSettings.last.extraSettings['workbench_state'],
      );
      expect(snapshot['active_document_path'], '');
    });

    test(
      'restoreWorkbenchSnapshot ignores hidden internal markdown path',
      () async {
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: 'D:/Projects/novel_project',
            selectedConversationAgentId: 'reviewer',
            activeDocumentPath: '.novel_agent/state/characters/lin/history.md',
            expandedDirectories: const <String>['docs'],
          ),
          workbench: WorkbenchViewData.initial(),
          projectState: WorkbenchProjectRuntimeState(
            resourceSnapshotEntries: const <JsonMap>[
              <String, Object?>{'relative_path': 'docs', 'is_dir': true},
            ],
          ),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project('D:/Projects/novel_project'),
        );

        expect(harness.workbench.activeDocumentPath, isEmpty);
      },
    );

    test(
      'restoreWorkbenchSnapshot restores dirty draft recovery without formal write',
      () async {
        final workspacePort = LocalProjectWorkspacePort();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workbench_draft_recovery_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        await _writeProjectFile(
          tempDirectory.path,
          'chapters/chapter_01.md',
          '磁盘上的正式内容',
        );
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: tempDirectory.path,
            selectedConversationAgentId: 'reviewer',
            activeDocumentPath: 'chapters/chapter_01.md',
            draftRecoveries: const <Map<String, Object?>>[
              <String, Object?>{
                'relative_path': 'chapters/chapter_01.md',
                'title': '第一章',
                'content': '恢复出来的未保存草稿',
              },
            ],
          ),
          workbench: WorkbenchViewData.initial(),
          projectState: WorkbenchProjectRuntimeState(
            currentProject: _project(tempDirectory.path),
            resourceSnapshotEntries: const <JsonMap>[
              <String, Object?>{
                'relative_path': 'chapters/chapter_01.md',
                'is_dir': false,
              },
            ],
          ),
          projectRepository: _FixedProjectRepository(
            _project(tempDirectory.path),
          ),
          workspacePort: workspacePort,
          toolHostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: workspacePort,
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
        );

        await harness.controller.restoreWorkbenchSnapshot(
          _project(tempDirectory.path),
        );

        expect(harness.workbench.activeDocumentPath, 'chapters/chapter_01.md');
        expect(harness.workbench.activeDocumentBody, '恢复出来的未保存草稿');
        expect(harness.workbench.activeDocumentDirty, isTrue);
        expect(harness.workbench.generationStatus, contains('已恢复 1 个未正式保存的草稿'));
        expect(
          await File(
            '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}chapter_01.md',
          ).readAsString(),
          '磁盘上的正式内容',
        );
      },
    );

    test(
      'loadProject keeps formal premise primary even when persisted snapshot points to legacy project brief',
      () async {
        final workspacePort = LocalProjectWorkspacePort();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workbench_support_overview_restore_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        await _writeProjectFile(
          tempDirectory.path,
          'premise/project_constitution.md',
          '# 正式前提\n\nformal premise',
        );
        await _writeProjectFile(
          tempDirectory.path,
          'premise/project_overview.md',
          '# 项目概览\n\ncanonical overview',
        );
        final harness = _ControllerHarness(
          settings: _settingsWithSnapshot(
            projectRootPath: tempDirectory.path,
            selectedConversationAgentId: 'reviewer',
            activeDocumentPath: 'premise/project_brief.md',
          ),
          workbench: WorkbenchViewData.initial(),
          projectState: const WorkbenchProjectRuntimeState(),
          projectRepository: _FixedProjectRepository(
            _project(tempDirectory.path),
          ),
          workspacePort: workspacePort,
          toolHostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: workspacePort,
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
        );

        final loaded = await harness.controller.loadProject(tempDirectory.path);

        expect(loaded, isTrue);
        expect(
          harness.workbench.activeDocumentPath,
          'premise/project_constitution.md',
        );
        expect(
          harness.workbench.activeDocumentBody,
          contains('formal premise'),
        );
      },
    );

    test(
      'refreshProjectLongTaskSummary loads station detail truth for workbench summary',
      () async {
        final project = _project('D:/Projects/novel_project');
        final run = RunInstance(
          id: 'run-1',
          project: RunProjectReference.fromProject(project),
          runtimeBaselineId: 'continuous_autonomous',
          modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
          workflowStrategyId: 'resumable_long_task',
          status: LongTaskRunStatus.paused,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 3)),
          activeTaskTitle: '检查点确认',
          stopOutcome: const LongTaskStopOutcome(
            present: true,
            category: LongTaskStopOutcomeCategories.waitingUser,
            reason: 'waiting_user_checkpoint',
            summary: '当前运行正在等待用户确认。',
          ),
        );
        final harness = _ControllerHarness(
          settings: _baseSettings(),
          workbench: WorkbenchViewData.initial(),
          projectState: WorkbenchProjectRuntimeState(currentProject: project),
          longTaskSupervisor: _buildSupervisor(<RunInstance>[run]),
          projectLongTaskDetailLoader: (_) async =>
              const ProjectLongTaskStationDetail(
                activeTask: null,
                chain: null,
                latestCheckpointReview: ProjectLongTaskStationItemSummary(
                  id: 'checkpoint-1',
                  title: '检查点确认',
                  relativePath: '.novel_agent/checkpoints/checkpoint-1.md',
                  status: TaskRuntimeConstants.statusWaitingUser,
                  subtitle: '等待确认',
                  summary: '需要先确认本章检查点再继续。',
                ),
                latestReviewReport: ProjectLongTaskStationItemSummary(
                  id: 'review-1',
                  title: '第 12 章审稿',
                  relativePath: '.novel_agent/reviews/review-1.md',
                  status: TaskRuntimeConstants.statusSucceeded,
                  subtitle: '审稿完成',
                  summary: '建议补强冲突并确认结尾停点。',
                ),
                latestRepairTask: null,
                narrativeSummary: ProjectLongTaskStationNarrativeSummary(
                  activation: null,
                  delivery: null,
                  review: null,
                  continuity: null,
                  information: null,
                  projectionItems: <ProjectLongTaskStationItemSummary>[],
                  permissionItems: <ProjectLongTaskStationItemSummary>[
                    ProjectLongTaskStationItemSummary(
                      id: 'permission-1',
                      title: 'Clarification',
                      relativePath:
                          '.novel_agent/continuity/clarifications/permission-1.md',
                      status: TaskRuntimeConstants.statusWaitingUser,
                      subtitle: 'needs_user_confirmation',
                      summary: '请先确认是否接受当前审稿建议。',
                    ),
                  ],
                  informationProjectionItems:
                      <ProjectLongTaskStationItemSummary>[],
                  informationPermissionItems:
                      <ProjectLongTaskStationItemSummary>[],
                ),
                blocker: ProjectLongTaskStationBlockerSummary(
                  code: 'waiting_user_checkpoint',
                  note: '当前运行正在等待用户确认。',
                  detail: '',
                  controlSummary: '先确认当前检查点和审稿意见，再继续推进。',
                  blockingCheckpointTitles: <String>['检查点确认'],
                  runRecordPath: 'tracking/long_task_runs/run-1.json',
                ),
              ),
        );

        await harness.controller.refreshProjectLongTaskSummary();

        expect(
          harness.projectState.currentProjectLongTaskRuns.single.id,
          'run-1',
        );
        expect(
          harness.projectState.currentProjectLongTaskRunDetails['run-1'],
          isNotNull,
        );
        expect(
          harness
              .workbench
              .projectLongTaskSummary!
              .runs
              .single
              .reviewSummaryLine,
          '最近审稿：第 12 章审稿，建议补强冲突并确认结尾停点。',
        );
        expect(
          harness
              .workbench
              .projectLongTaskSummary!
              .runs
              .single
              .pendingSummaryLine,
          '待确认事项：待确认问题，请先确认是否接受当前审稿建议。',
        );
      },
    );

    test(
      'loadProject skips reference extraction bundle subtree while building information view',
      () async {
        final workspacePort = LocalProjectWorkspacePort();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workbench_information_scan_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        await _writeProjectFile(
          tempDirectory.path,
          'knowledge/项目知识摘要.md',
          _projectionMarkdown(
            title: '知识摘要',
            sourceOfTruthPath: 'project-information://knowledge_cards',
            sourceIdentity:
                '来源-source-1 / `imports/reference/source-1.txt` / kind:`user`',
          ),
        );
        await _writeProjectFile(
          tempDirectory.path,
          '.novel_agent/information/knowledge_cards/knowledge_1.json',
          jsonEncode(<String, Object?>{
            'card_id': 'knowledge_1',
            'title': '王朝年号',
            'summary': '需要确认帝国年号是否已经固定。',
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          }),
        );
        await _writeProjectFile(
          tempDirectory.path,
          '.novel_agent/reference_extraction/bundles/bundle_1/activation_report.json',
          '{invalid-json',
        );
        final harness = _ControllerHarness(
          settings: _baseSettings(),
          workbench: WorkbenchViewData.initial(),
          projectState: const WorkbenchProjectRuntimeState(),
          projectRepository: _FixedProjectRepository(
            _project(tempDirectory.path),
          ),
          workspacePort: workspacePort,
          toolHostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: workspacePort,
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
        );

        final loaded = await harness.controller.loadProject(tempDirectory.path);

        expect(loaded, isTrue);
        expect(
          harness.workbench.informationViewData.summary,
          '已整理 1 组资料摘要，1 项待确认',
        );
        expect(
          harness.workbench.informationViewData.usageSummary,
          '本轮还没有可解释的资料使用记录。',
        );
        expect(
          harness.workbench.informationViewData.pendingEntries
              .map((entry) => entry.title)
              .toList(growable: false),
          <String>['待确认知识'],
        );
      },
    );

    test('loadProject restores persisted conversation runtime state', () async {
      final workspacePort = LocalProjectWorkspacePort();
      final tempDirectory = await Directory.systemTemp.createTemp(
        'workbench_session_restore_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      await _writeProjectFile(
        tempDirectory.path,
        'sessions/session_1.json',
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'id': 'session_1',
          'title': '历史会话',
          'mode': SessionRecordConstants.modeContinueWriting,
          'workflow_stage': 'draft',
          'public_status': '继续写作',
          'needs_goal_selection': false,
          'is_creative': true,
          'transcript_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '先看前情提要'},
            <String, Object?>{'role': 'assistant', 'content': '好的，我先整理。'},
            <String, Object?>{'role': 'user', 'content': '继续写下一段。'},
          ],
          'working_context_messages': <Object?>[
            <String, Object?>{'role': 'assistant', 'content': '好的，我先整理。'},
            <String, Object?>{'role': 'user', 'content': '继续写下一段。'},
          ],
          'compaction_segments': <Object?>[
            <String, Object?>{
              'id': 'segment_1',
              'kind': 'preflight_compaction',
              'title': '更早历史',
              'summary': '压缩片段 1（自动）：\n先看前情提要。',
              'source_message_count': 1,
              'source_message_roles': <String>['user'],
              'created_at': '2026-06-14T00:00:00.000Z',
            },
          ],
          'pinned_context_refs': <Object?>['scene.anchor'],
          'context_messages': <Object?>[
            <String, Object?>{'role': 'assistant', 'content': '好的，我先整理。'},
            <String, Object?>{'role': 'user', 'content': '继续写下一段。'},
          ],
          'compressed_context': '压缩片段 1（自动）：\n先看前情提要。',
          'compression_count': 1,
          'compression_threshold_chars': 12000,
          'transcript_context_chars': 23,
          'working_context_chars': 15,
          'compaction_archive_chars': 16,
          'total_context_chars': 31,
          'created_at': '2026-06-14T00:00:00.000Z',
          'updated_at': '2026-06-14T00:05:00.000Z',
        }),
      );
      await _writeProjectFile(
        tempDirectory.path,
        'sessions/session_index.json',
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'current_session_id': 'session_1',
          'sessions': <Object?>[
            <String, Object?>{
              'id': 'session_1',
              'title': '历史会话',
              'updated_at': '2026-06-14T00:05:00.000Z',
            },
          ],
        }),
      );
      final harness = _ControllerHarness(
        settings: _baseSettings(),
        workbench: WorkbenchViewData.initial(),
        projectState: const WorkbenchProjectRuntimeState(),
        projectRepository: _FixedProjectRepository(
          _project(tempDirectory.path),
        ),
        workspacePort: workspacePort,
        toolHostPort: ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        ),
      );

      final loaded = await harness.controller.loadProject(tempDirectory.path);

      expect(loaded, isTrue);
      expect(harness.restoredProjects, <String>[tempDirectory.path]);
    });

    test(
      'loadProject opens formal premise before random readable files',
      () async {
        final workspacePort = LocalProjectWorkspacePort();
        final tempDirectory = await Directory.systemTemp.createTemp(
          'workbench_primary_open_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });
        await _writeProjectFile(
          tempDirectory.path,
          'analysis/notes.md',
          '# 随机说明\n\n这里只是普通分析文档。',
        );
        await _writeProjectFile(
          tempDirectory.path,
          'premise/project_constitution.md',
          '# 项目创作宪法\n\n这是正式前提。',
        );
        await _writeProjectFile(
          tempDirectory.path,
          'premise/project_brief.md',
          '# 项目概览\n\n这是 support overview。',
        );
        final harness = _ControllerHarness(
          settings: _baseSettings(),
          workbench: WorkbenchViewData.initial(),
          projectState: const WorkbenchProjectRuntimeState(),
          projectRepository: _FixedProjectRepository(
            _project(tempDirectory.path),
          ),
          workspacePort: workspacePort,
          toolHostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: workspacePort,
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
        );

        final loaded = await harness.controller.loadProject(tempDirectory.path);

        expect(loaded, isTrue);
        expect(
          harness.workbench.activeDocumentPath,
          'premise/project_constitution.md',
        );
        expect(harness.workbench.activeDocumentBody, contains('这是正式前提'));
      },
    );
  });
}

class _ControllerHarness {
  _ControllerHarness({
    required AppSettings settings,
    required WorkbenchViewData workbench,
    required WorkbenchProjectRuntimeState projectState,
    LongTaskSupervisor? longTaskSupervisor,
    WorkbenchProjectLongTaskDetailLoader? projectLongTaskDetailLoader,
    ProjectRepository? projectRepository,
    ProjectWorkspacePort? workspacePort,
    ProjectToolHostPort? toolHostPort,
  }) : _settings = settings,
       _workbench = workbench,
       _projectState = projectState {
    controller = _createController(
      longTaskSupervisor: longTaskSupervisor,
      projectLongTaskDetailLoader: projectLongTaskDetailLoader,
      projectRepository: projectRepository,
      workspacePort: workspacePort,
      toolHostPort: toolHostPort,
      readSettings: () => _settings,
      saveSettingsSilently: (next) async {
        _savedSettings.add(next);
        _settings = next;
      },
      readWorkbench: () => _workbench,
      mutateWorkbench: (updater) {
        _workbench = updater(_workbench);
      },
      readProjectState: () => _projectState,
      writeProjectState: (next) {
        _projectState = next;
      },
      restoreConversationRuntimeState: (project) async {
        _restoredProjects.add(project.rootPath);
      },
    );
  }

  AppSettings _settings;
  WorkbenchViewData _workbench;
  WorkbenchProjectRuntimeState _projectState;
  final List<AppSettings> _savedSettings = <AppSettings>[];
  final List<String> _restoredProjects = <String>[];

  late final WorkbenchWorkspaceController controller;

  WorkbenchViewData get workbench => _workbench;
  WorkbenchProjectRuntimeState get projectState => _projectState;
  List<String> get restoredProjects =>
      List<String>.unmodifiable(_restoredProjects);
  List<AppSettings> get savedSettings =>
      List<AppSettings>.unmodifiable(_savedSettings);
}

WorkbenchWorkspaceController _createController({
  LongTaskSupervisor? longTaskSupervisor,
  WorkbenchProjectLongTaskDetailLoader? projectLongTaskDetailLoader,
  ProjectRepository? projectRepository,
  ProjectWorkspacePort? workspacePort,
  ProjectToolHostPort? toolHostPort,
  required AppSettings? Function() readSettings,
  required Future<void> Function(AppSettings nextSettings) saveSettingsSilently,
  required WorkbenchViewData Function() readWorkbench,
  required void Function(WorkbenchViewData Function(WorkbenchViewData current))
  mutateWorkbench,
  required WorkbenchProjectRuntimeState Function() readProjectState,
  required void Function(WorkbenchProjectRuntimeState state) writeProjectState,
  required Future<void> Function(ProjectDescriptor project)
  restoreConversationRuntimeState,
}) {
  final effectiveProjectRepository =
      projectRepository ?? _NoopProjectRepository();
  final effectiveWorkspacePort = workspacePort ?? _NoopProjectWorkspacePort();
  final effectiveToolHostPort = toolHostPort ?? _NoopProjectToolHostPort();
  return WorkbenchWorkspaceController(
    loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
      projectRepository: effectiveProjectRepository,
      projectWorkspacePort: effectiveWorkspacePort,
    ),
    readProjectFileUseCase: ReadProjectFileUseCase(effectiveWorkspacePort),
    saveDraftUseCase: SaveDraftUseCase(
      projectWorkspacePort: effectiveWorkspacePort,
    ),
    createProjectEntryUseCase: CreateProjectEntryUseCase(
      projectToolHostPort: effectiveToolHostPort,
    ),
    importProjectFilesUseCase: ImportProjectFilesUseCase(
      projectToolHostPort: effectiveToolHostPort,
    ),
    updateProjectManifestUseCase: UpdateProjectManifestUseCase(
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: effectiveWorkspacePort,
      ),
    ),
    projectToolHostPort: effectiveToolHostPort,
    writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
      projectWorkspacePort: effectiveWorkspacePort,
    ),
    narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
      workspacePort: effectiveWorkspacePort,
    ),
    longTaskSupervisor: longTaskSupervisor ?? _NoopLongTaskSupervisor(),
    reviewReportService: _NoopProjectReviewReportService(),
    projectRuntimeProfileRepository: ProjectRuntimeProfileRepository(
      workspacePort: effectiveWorkspacePort,
    ),
    readProjectState: readProjectState,
    writeProjectState: writeProjectState,
    resetConversationRuntimeState: () {},
    restoreConversationRuntimeState: restoreConversationRuntimeState,
    readWorkbench: readWorkbench,
    mutateWorkbench: mutateWorkbench,
    applyConversationState: (base) => base,
    readSettings: readSettings,
    saveSettingsSilently: saveSettingsSilently,
    refreshSettingsViewData: () {},
    refreshAgentEcosystem: () async {},
    refreshActiveDestinationAfterProjectLoad: () async {},
    modelOptionsBuilder: (_) => const <SelectorOptionViewData>[],
    readProjectAgentGroupWorkspaceViewData: () => null,
    selectProjectAgentGroup: (_) async => null,
    showSettings: () async {},
    showAgentEcosystem: () async {},
    showLongTaskStation: () async {},
    showInspirationWorkbench: () async {},
    showPromptTemplates: () async {},
    showProjectAssets: () async {},
    showCurrentAgentSkillLoadout: (_) async {},
    showCurrentAgentExpressionConstraints: (_) async {},
    announce: (_) {},
    projectLongTaskDetailLoader: projectLongTaskDetailLoader,
  );
}

LongTaskSupervisor _buildSupervisor(List<RunInstance> runs) {
  return LongTaskSupervisor(runRegistry: _MemoryLongTaskRunRegistry(runs));
}

ProjectDescriptor _project(String rootPath) {
  return ProjectDescriptor(
    id: rootPath,
    name: '测试项目',
    rootPath: rootPath,
    projectType: 'novel',
  );
}

AppSettings _baseSettings() {
  return const AppSettings(
    defaultProviderId: 'provider',
    defaultAgentId: 'default_generalist',
    defaultModelId: 'model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[],
  );
}

AppSettings _settingsWithSnapshot({
  required String projectRootPath,
  required String selectedConversationAgentId,
  String activeDocumentPath = '',
  List<String> expandedDirectories = const <String>[],
  List<Map<String, Object?>> draftRecoveries = const <Map<String, Object?>>[],
}) {
  return _baseSettings().copyWith(
    extraSettings: <String, Object?>{
      'workbench_state': <String, Object?>{
        'project_root_path': projectRootPath,
        'active_document_path': activeDocumentPath,
        'expanded_directories': expandedDirectories,
        'selected_conversation_agent_id': selectedConversationAgentId,
        'draft_recoveries': draftRecoveries,
      },
    },
  );
}

JsonMap _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return ValueReaders.deepCopyMap(value);
  }
  if (value is Map) {
    final result = <String, Object?>{};
    value.forEach((key, item) {
      result[key.toString()] = item;
    });
    return result;
  }
  return const <String, Object?>{};
}

class _NoopProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => null;
}

class _FixedProjectRepository implements ProjectRepository {
  _FixedProjectRepository(this._project);

  final ProjectDescriptor _project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    return rootPath == _project.rootPath ? _project : null;
  }
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
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopLongTaskSupervisor implements LongTaskSupervisor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryLongTaskRunRegistry implements LongTaskRunRegistry {
  _MemoryLongTaskRunRegistry(List<RunInstance> runs)
    : _runs = <String, RunInstance>{for (final run in runs) run.id: run};

  final Map<String, RunInstance> _runs;

  @override
  Future<void> delete(String runId) async {
    _runs.remove(runId);
  }

  @override
  Future<RunInstance?> findById(String runId) async => _runs[runId];

  @override
  Future<List<RunInstance>> listActive() async =>
      _runs.values.where((run) => run.isActive).toList(growable: false);

  @override
  Future<List<RunInstance>> listAll() async =>
      _runs.values.toList(growable: false);

  @override
  Future<List<RunInstance>> listByProject(String projectKey) async => _runs
      .values
      .where((run) => run.project.rootPath == projectKey)
      .toList(growable: false);

  @override
  Future<void> save(RunInstance instance) async {
    _runs[instance.id] = instance;
  }
}

class _NoopProjectReviewReportService implements ProjectReviewReportService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _writeProjectFile(
  String rootPath,
  String relativePath,
  String content,
) async {
  final normalizedRelative = relativePath.replaceAll(
    '/',
    Platform.pathSeparator,
  );
  final file = File('$rootPath${Platform.pathSeparator}$normalizedRelative');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

String _projectionMarkdown({
  required String title,
  required String sourceOfTruthPath,
  required String sourceIdentity,
}) {
  return '''
---
title: $title
source_of_truth_path: $sourceOfTruthPath
source_identity: $sourceIdentity
---

# $title

- 测试摘要
''';
}
