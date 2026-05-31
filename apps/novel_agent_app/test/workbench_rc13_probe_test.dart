import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_group_selector_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_resource_visibility_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RC-13 probe rebuilds the final verification loop', () async {
    final recorder = _ProbeRecorder();
    final repoRoot = _resolveRepoRoot();

    await recorder.capture('default_resource_tree_hides_internal_and_advanced', () {
      final visiblePaths = ProjectWorkspaceCatalog
          .defaultResourceTreeDirectoryDescriptors
          .map((descriptor) => descriptor.path)
          .toList(growable: false);
      _ensure(!visiblePaths.contains('agents/'), '默认资源树不应暴露 agents/。');
      _ensure(!visiblePaths.contains('prompts/'), '默认资源树不应暴露 prompts/。');
      _ensure(!visiblePaths.contains('tracking/'), '默认资源树不应暴露 tracking/。');
      _ensure(visiblePaths.contains('premise/'), '默认资源树应保留 premise/。');
      _ensure(visiblePaths.contains('chapters/'), '默认资源树应保留 chapters/。');
      return <String, Object?>{'visible_paths': visiblePaths};
    });

    await recorder.capture('legacy_paths_stay_readable_but_hidden_by_default', () {
      const visibility = WorkspaceResourceVisibilityService();
      const samples = <String>[
        'drafts/ch01.md',
        'specs/project_brief.md',
        'characters/hero.md',
        'inspiration/seed.md',
      ];
      for (final path in samples) {
        _ensure(
          visibility.isLegacyCompatibilityPath(path),
          '旧目录路径应继续被识别: $path',
        );
        _ensure(
          visibility.shouldHideFromDefaultTree(path),
          '旧目录路径应默认从资源树隐藏: $path',
        );
      }
      return <String, Object?>{'legacy_paths': samples};
    });

    await recorder.capture('group_projection_never_leaks_internal_agent_id_copy', () {
      const selectorService = ConversationGroupSelectorViewDataService();
      final viewData = selectorService.build(
        openingProjection: OpeningSessionProjection(
          projectTypeId: 'novel',
          currentGroupId: 'starter_novel_generalist',
          currentGroupDisplayName: '默认小说开局',
          groupSummaries: const <OpeningAgentGroupSummary>[
            OpeningAgentGroupSummary(
              groupId: 'starter_novel_generalist',
              displayName: '默认小说开局',
              description: '适合普通小说项目。',
              isSupported: true,
              isDegraded: false,
              isCurrent: true,
              isStarterGroup: true,
            ),
          ],
          orchestration: OpeningOrchestrationResult(
            state: const OpeningSessionState(
              projectTypeId: 'novel',
              status: OpeningSessionState.statusReadyForInteractiveSession,
              intent: OpeningIntentSnapshot(
                resolvedAgentGroupId: 'starter_novel_generalist',
                availableAgentGroupIds: <String>['starter_novel_generalist'],
              ),
              stageRecords: <OpeningStageRecord>[],
              createdAt: '2026-05-29T00:00:00.000Z',
              updatedAt: '2026-05-29T00:00:00.000Z',
            ),
            readiness: const OpeningReadinessAssessment(
              canStartLongTask: false,
              canStartInteractiveSession: true,
              missingRequirements: <OpeningMissingRequirement>[],
            ),
            suggestedActions: const <OpeningSuggestedAction>[],
          ),
          currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
            agentId: 'default_generalist',
            displayName: '',
            role: '',
            thinkingSupported: true,
          ),
        ),
        fallbackPrimaryAgentLabel: 'default_generalist',
      );
      _ensure(viewData.primaryAgentLabel == '综合创作智能体', '主智能体文案不应回退成内部 id。');
      return <String, Object?>{
        'group_label': viewData.currentGroupLabel,
        'primary_agent_label': viewData.primaryAgentLabel,
      };
    });

    await recorder.capture('advanced_and_internal_paths_stay_classified', () {
      _ensure(
        ProjectWorkspaceCatalog.isAdvancedWorkspacePath(
          'tracking/current_run.md',
        ),
        'tracking/ 应继续归类为高级目录。',
      );
      _ensure(
        ProjectWorkspaceCatalog.isInternalWorkspacePath(
          '.novel_agent/runtime/session_state.json',
        ),
        '内部状态路径应继续归类为内部目录。',
      );
      _ensure(
        !ProjectWorkspaceCatalog.isDefaultResourceTreePath(
          'runs/20260529/run_01.json',
        ),
        '运行记录不应重新进入默认资源树。',
      );
      return <String, Object?>{
        'advanced_path': 'tracking/current_run.md',
        'internal_path': '.novel_agent/runtime/session_state.json',
      };
    });

    final reportPath = await _writeReport(repoRoot, recorder);
    if (recorder.failedCount > 0) {
      fail('RC-13 probe failed. report: $reportPath');
    }
  });
}

Future<String> _writeReport(String repoRoot, _ProbeRecorder recorder) async {
  final reportPath =
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}workbench_rc13_probe_report.json';
  final file = File(reportPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'created_at': DateTime.now().toIso8601String(),
      'passed': recorder.passedCount,
      'failed': recorder.failedCount,
      'steps': recorder.steps,
    }),
  );
  return reportPath;
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-recovery-session-order-2026-05-29.md',
    );
    if (docsFile.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

class _ProbeRecorder {
  final List<JsonMap> steps = <JsonMap>[];

  int get passedCount =>
      steps.where((step) => ValueReaders.boolValue(step['ok'])).length;

  int get failedCount =>
      steps.where((step) => !ValueReaders.boolValue(step['ok'])).length;

  Future<void> capture(
    String name,
    Map<String, Object?> Function() action,
  ) async {
    final startedAt = DateTime.now();
    try {
      final detail = action();
      steps.add(<String, Object?>{
        'name': name,
        'ok': true,
        'detail': detail,
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    } catch (error, stackTrace) {
      steps.add(<String, Object?>{
        'name': name,
        'ok': false,
        'detail': '$error',
        'stack_trace': '$stackTrace',
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
