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
    String expressionConstraintInjectionMode = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
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
    }
    final expressionReport = ValueReaders.mapValue(
      report['expression_constraints'],
    );
    final appliedBindingIds = ValueReaders.stringList(
      expressionReport['applied_binding_ids'],
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
        '- 表达限制：已接入 ${activeBindingCount > 0 ? activeBindingCount : appliedBindingIds.length} 条 binding 运行时桥接。',
      );
      if (injectionMode.isNotEmpty && injectionMode != 'disabled') {
        lines.add('- 表达限制 gate：当前按 $injectionMode 注入，并要求保留复核证据。');
      }
    }
    return lines.join('\n');
  }
}
