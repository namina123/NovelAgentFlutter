import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/expression_constraint_profile_repository.dart';
import '../storage/local_constraint_binding_repository.dart';
import '../storage/project_expression_constraint_binding_repository.dart';

class ProjectDraftExecutionConstraintRuntimeService {
  ProjectDraftExecutionConstraintRuntimeService({
    required ExpressionConstraintProfileRepository
    expressionConstraintProfileRepository,
    required ProjectExpressionConstraintBindingRepository
    projectExpressionConstraintBindingRepository,
    required ConstraintBindingRepository constraintBindingRepository,
    WritingExecutionConstraintBridgeService?
    writingExecutionConstraintBridgeService,
    ExpressionConstraintProfileNormalizerService?
    expressionConstraintProfileNormalizerService,
    ProjectExpressionConstraintBindingNormalizerService?
    projectExpressionConstraintBindingNormalizerService,
  }) : _expressionConstraintProfileRepository =
           expressionConstraintProfileRepository,
       _projectExpressionConstraintBindingRepository =
           projectExpressionConstraintBindingRepository,
       _constraintBindingRepository = constraintBindingRepository,
       _writingExecutionConstraintBridgeService =
           writingExecutionConstraintBridgeService ??
           const WritingExecutionConstraintBridgeService(),
       _expressionConstraintProfileNormalizerService =
           expressionConstraintProfileNormalizerService ??
           const ExpressionConstraintProfileNormalizerService(),
       _projectExpressionConstraintBindingNormalizerService =
           projectExpressionConstraintBindingNormalizerService ??
           const ProjectExpressionConstraintBindingNormalizerService();

  factory ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort({
    required ProjectWorkspacePort workspacePort,
    WritingExecutionConstraintBridgeService?
    writingExecutionConstraintBridgeService,
  }) {
    return ProjectDraftExecutionConstraintRuntimeService(
      expressionConstraintProfileRepository:
          ExpressionConstraintProfileRepository(workspacePort: workspacePort),
      projectExpressionConstraintBindingRepository:
          ProjectExpressionConstraintBindingRepository(
            workspacePort: workspacePort,
          ),
      constraintBindingRepository: LocalConstraintBindingRepository(
        workspacePort: workspacePort,
      ),
      writingExecutionConstraintBridgeService:
          writingExecutionConstraintBridgeService,
    );
  }

  final ExpressionConstraintProfileRepository
  _expressionConstraintProfileRepository;
  final ProjectExpressionConstraintBindingRepository
  _projectExpressionConstraintBindingRepository;
  final ConstraintBindingRepository _constraintBindingRepository;
  final WritingExecutionConstraintBridgeService
  _writingExecutionConstraintBridgeService;
  final ExpressionConstraintProfileNormalizerService
  _expressionConstraintProfileNormalizerService;
  final ProjectExpressionConstraintBindingNormalizerService
  _projectExpressionConstraintBindingNormalizerService;

  Future<JsonMap> resolve(
    ProjectDescriptor project, {
    required String appliesTo,
    String agentId = '',
    String modeId = '',
    String stageId = '',
    String intent = 'draft',
    String taskType = '',
    String phase = '',
    String expressionConstraintPolicyMode = '',
    String expressionConstraintInjectionMode = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
    List<WritingExecutionConstraintSummary>
        recentExpressionConstraintSummaries =
        const <WritingExecutionConstraintSummary>[],
  }) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      _expressionConstraintProfileRepository.loadProfiles(
        project,
        includeBuiltins: true,
      ),
      _projectExpressionConstraintBindingRepository.loadBindings(project),
      _constraintBindingRepository.listBindings(project),
    ]);
    final profiles = List<ExpressionConstraintProfile>.from(
      results[0] as List<ExpressionConstraintProfile>,
    );
    final bindings = List<ProjectExpressionConstraintBinding>.from(
      results[1] as List<ProjectExpressionConstraintBinding>,
    );
    final narrativeBindings = List<NarrativeConstraintBindingProposal>.from(
      results[2] as List<NarrativeConstraintBindingProposal>,
    );
    final bridged = _writingExecutionConstraintBridgeService.bridge(
      appliesTo: appliesTo,
      projectTypeId: project.projectType,
      agentId: agentId,
      modeId: modeId,
      stageId: stageId,
      intent: intent,
      taskType: taskType,
      phase: phase,
      expressionConstraintPolicyMode: expressionConstraintPolicyMode,
      expressionConstraintInjectionMode: expressionConstraintInjectionMode,
      legacyChapterLengthOptions: legacyChapterLengthOptions,
      legacyExpressionConstraintProfiles: profiles
          .map(_expressionConstraintProfileNormalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
      legacyProjectExpressionConstraintBindings: bindings
          .map(_projectExpressionConstraintBindingNormalizerService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
      recentExpressionConstraintSummaries: recentExpressionConstraintSummaries,
      narrativeBindings: narrativeBindings,
    );
    final chapterLengthSummary = _chapterLengthSummary(
      bridged.chapterLengthMetadata,
      report: bridged.runtimeReport,
    );
    return <String, Object?>{
      ...bridged.toJson(),
      'session_context_markdown': _sessionContextMarkdown(
        chapterLengthSummary: chapterLengthSummary,
        bridged: bridged,
        report: bridged.runtimeReport,
      ),
      'chapter_length_summary': chapterLengthSummary,
    };
  }

  String _chapterLengthSummary(JsonMap metadata, {required JsonMap report}) {
    final profile = ValueReaders.mapValue(metadata['chapter_length_profile']);
    if (profile.isEmpty) {
      return '';
    }
    final target = ValueReaders.intValue(profile['target_length']);
    final min = ValueReaders.intValue(profile['preferred_min']);
    final max = ValueReaders.intValue(profile['preferred_max']);
    final source = ValueReaders.stringValue(
      ValueReaders.mapValue(report['chapter_length'])['source'],
      'unknown',
    );
    final parts = <String>[];
    if (target > 0) {
      parts.add('目标约 $target 字');
    }
    if (min > 0) {
      parts.add('不少于 $min 字');
    }
    if (max > 0) {
      parts.add('尽量不超过 $max 字');
    }
    final summary = parts.join('；');
    if (summary.isEmpty) {
      return '';
    }
    return source == 'binding' ? '$summary（来自 constraint binding）' : summary;
  }

  String _sessionContextMarkdown({
    required String chapterLengthSummary,
    required WritingExecutionConstraintBridgeResult bridged,
    required JsonMap report,
  }) {
    final lines = <String>[];
    if (chapterLengthSummary.trim().isNotEmpty) {
      lines.add('## Execution Constraints');
      lines.add('- 字数约束：$chapterLengthSummary');
      final profile = ValueReaders.mapValue(
        ValueReaders.mapValue(
          bridged.chapterLengthMetadata['chapter_length_profile'],
        ),
      );
      final min = ValueReaders.intValue(profile['preferred_min']);
      final max = ValueReaders.intValue(profile['preferred_max']);
      final target = ValueReaders.intValue(profile['target_length']);
      final hardGateParts = <String>[];
      if (min > 0) {
        hardGateParts.add('低于 $min 字不得提交正式章节');
      }
      if (max > 0) {
        hardGateParts.add('高于 $max 字需先压缩后再提交');
      }
      if (target > 0) {
        hardGateParts.add('不要只口头声称“约 $target 字”，要让实际正文长度落在窗口内');
      }
      if (hardGateParts.isNotEmpty) {
        lines.add('- 正式交付 gate：${hardGateParts.join('；')}。');
      }
    }
    final expressionReport = ValueReaders.mapValue(
      report['expression_constraints'],
    );
    final appliedBindingIds = ValueReaders.stringList(
      expressionReport['applied_binding_ids'],
    );
    final policyMode = ValueReaders.stringValue(
      bridged.expressionConstraintPolicyMode,
      ExpressionConstraintExecutionPolicyModes.disabled,
    );
    final bindingCountFromReport = ValueReaders.intValue(
      expressionReport['binding_binding_count'],
    );
    final activeBindingCount = bindingCountFromReport > 0
        ? bindingCountFromReport
        : bridged.projectExpressionConstraintBindings.length;
    if (activeBindingCount > 0 || appliedBindingIds.isNotEmpty) {
      if (lines.isEmpty) {
        lines.add('## Execution Constraints');
      }
      final injectionMode = bridged.expressionConstraintInjectionMode.trim();
      lines.add(
        '- 表达限制：已接入 ${activeBindingCount > 0 ? activeBindingCount : appliedBindingIds.length} 条 binding 运行时桥接，当前策略 $policyMode。',
      );
      if (policyMode == ExpressionConstraintExecutionPolicyModes.disabled) {
        lines.add('- 表达限制 gate：当前策略已关闭，本轮不要求表达限制复核。');
      } else if (injectionMode.isNotEmpty && injectionMode != 'disabled') {
        if (bridged.expressionConstraintReviewRequired) {
          lines.add('- 表达限制 gate：当前按 $injectionMode 注入，并要求保留复核证据。');
        } else if (policyMode ==
            ExpressionConstraintExecutionPolicyModes.force) {
          lines.add(
            '- 表达限制 gate：当前按 $injectionMode 强执行；正文交付前必须主动避开已启用 profile 的风险信号，本轮不要求额外复核证据。',
          );
          final forceRiskSignals = _activeExpressionRiskSignals(bridged);
          if (forceRiskSignals.isNotEmpty) {
            lines.add(
              '- 激进策略自查：本轮交付正文不要出现这些风险信号：${forceRiskSignals.take(10).join('、')}；如已写出，提交前改成动作、对话、停顿或更具体的场面表达。',
            );
          }
        } else {
          lines.add('- 表达限制 gate：当前按 $injectionMode 注入，本轮不要求额外复核证据。');
        }
      }
    }
    return lines.join('\n');
  }

  List<String> _activeExpressionRiskSignals(
    WritingExecutionConstraintBridgeResult bridged,
  ) {
    final activeProfileIds = bridged.projectExpressionConstraintBindings
        .where((binding) => binding.enabled)
        .map((binding) => binding.profileId.trim())
        .where((profileId) => profileId.isNotEmpty)
        .toSet();
    if (activeProfileIds.isEmpty) {
      return const <String>[];
    }
    final result = <String>[];
    for (final profile in bridged.expressionConstraintProfiles) {
      if (!activeProfileIds.contains(profile.id.trim())) {
        continue;
      }
      for (final signal in profile.riskSignals) {
        final clean = signal.trim();
        if (clean.isNotEmpty && !result.contains(clean)) {
          result.add(clean);
        }
      }
    }
    return List<String>.unmodifiable(result);
  }
}
