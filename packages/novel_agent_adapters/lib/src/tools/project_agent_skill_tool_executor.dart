import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/local_skill_group_catalog.dart';
import '../packages/local_package_resource_reader.dart';
import '../packages/local_skill_package_catalog.dart';
import '../storage/project_relative_path_resolver.dart';
import 'project_agent_skill_runtime_loadout_service.dart';
import 'project_tool_result_factory.dart';

class ProjectAgentSkillToolExecutor {
  ProjectAgentSkillToolExecutor({
    LocalSkillPackageCatalog? skillPackageCatalog,
    LocalSkillGroupCatalog? skillGroupCatalog,
    ProjectToolResultFactory? resultFactory,
    AgentSkillSummaryService? skillSummaryService,
    AgentProfileCatalogService? agentProfileCatalogService,
    SkillInstructionDigestService? skillInstructionDigestService,
    LocalPackageResourceReader? packageResourceReader,
    ProjectRelativePathResolver? projectRelativePathResolver,
    ProjectAgentSkillRuntimeLoadoutService? runtimeLoadoutService,
  }) : _skillPackageCatalog = skillPackageCatalog ?? LocalSkillPackageCatalog(),
       _skillGroupCatalog = skillGroupCatalog ?? LocalSkillGroupCatalog(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _skillSummaryService = skillSummaryService ?? AgentSkillSummaryService(),
       _agentProfileCatalogService =
           agentProfileCatalogService ?? AgentProfileCatalogService(),
       _skillInstructionDigestService =
           skillInstructionDigestService ??
           const SkillInstructionDigestService(),
       _packageResourceReader =
           packageResourceReader ?? const LocalPackageResourceReader(),
       _projectRelativePathResolver =
           projectRelativePathResolver ?? ProjectRelativePathResolver(),
       _runtimeLoadoutService = runtimeLoadoutService;

  final LocalSkillPackageCatalog _skillPackageCatalog;
  final LocalSkillGroupCatalog _skillGroupCatalog;
  final ProjectToolResultFactory _resultFactory;
  final AgentSkillSummaryService _skillSummaryService;
  final AgentProfileCatalogService _agentProfileCatalogService;
  final SkillInstructionDigestService _skillInstructionDigestService;
  final LocalPackageResourceReader _packageResourceReader;
  final ProjectRelativePathResolver _projectRelativePathResolver;
  final ProjectAgentSkillRuntimeLoadoutService? _runtimeLoadoutService;
  // 中文注释: 技能 id 在包（kebab）与文档/模型入参（snake）之间历史上不一致，匹配前统一归一。
  final SkillIdNormalizer _skillIdNormalizer = const SkillIdNormalizer();

  Future<JsonMap> loadAgentSkill(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 技能读取执行器只处理技能包发现、作用域过滤和结果拼装，不触碰主循环或 UI 状态。
    final agent = _resolvedAgent(arguments);
    final allSkills = await _skillPackageCatalog.loadSkillPackages(project);
    final projectSkillGroups = await _skillGroupCatalog.loadSkillGroups(
      project,
    );
    final resolvedLoadout = await _resolveRuntimeLoadout(
      project: project,
      agent: agent,
      availableSkillGroups: projectSkillGroups,
      availableSkillIds: allSkills
          .map(
            (item) => ValueReaders.stringValue(
              ValueReaders.mapValue(item)['id'],
            ).trim(),
          )
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
    );
    final availableSkills = _skillSummaryService.buildAvailableSkillSummaries(
      agent: agent,
      allSkills: allSkills,
      availableSkillGroups: projectSkillGroups,
      resolvedLoadout: resolvedLoadout,
    );
    final runtimeLoadoutData = _runtimeLoadoutData(resolvedLoadout);
    var skillId = ValueReaders.stringValue(arguments['skill_id']).trim();
    final query = ValueReaders.stringValue(arguments['query']).trim();
    if (skillId.isEmpty && query.isNotEmpty) {
      skillId = _skillSummaryService.selectSkillIdForQuery(
        query,
        availableSkills,
      );
    }
    final agentId = ValueReaders.stringValue(agent['id'], 'default_generalist');
    if (skillId.isEmpty) {
      return _resultFactory.notExecuted(
        '请先从 available_skills 选择与当前任务最相关的 skill_id，再调用 load_agent_skill 读取完整说明。',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
          ...runtimeLoadoutData,
        },
      );
    }
    // 中文注释: skillId 可能来自模型入参或路由策略，可能是 snake_case；与包的 kebab id 比较前统一归一。
    final normalizedSkillId = _skillIdNormalizer.normalize(skillId);
    final allowedIds = availableSkills
        .map(
          (skill) => _skillIdNormalizer.normalize(
            ValueReaders.stringValue(skill['id']),
          ),
        )
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!allowedIds.contains(normalizedSkillId)) {
      return _resultFactory.notExecuted(
        '当前智能体不可读取该技能：$skillId',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
          ...runtimeLoadoutData,
        },
      );
    }
    JsonMap? skillPackage;
    for (final rawSkill in allSkills) {
      final skill = ValueReaders.mapValue(rawSkill);
      if (_skillIdNormalizer.normalize(ValueReaders.stringValue(skill['id'])) ==
          normalizedSkillId) {
        skillPackage = skill;
        break;
      }
    }
    if (skillPackage == null || skillPackage.isEmpty) {
      return _resultFactory.notExecuted(
        '技能包尚未安装或尚未同步到当前目录：$skillId',
        data: <String, Object?>{
          'agent_id': agentId,
          'available_skills': availableSkills,
          ...runtimeLoadoutData,
        },
      );
    }
    final instructionMarkdown = ValueReaders.stringValue(
      skillPackage['instruction_markdown'],
    ).trim();
    final referencePath = _packageResourceReader.normalizeResourcePath(
      ValueReaders.stringValue(arguments['reference_path']),
    );
    if (referencePath.isNotEmpty) {
      return _loadReference(
        agentId: agentId,
        availableSkills: availableSkills,
        skillId: skillId,
        skillPackage: skillPackage,
        referencePath: referencePath,
        runtimeLoadoutData: runtimeLoadoutData,
      );
    }
    final detailLevel = ValueReaders.stringValue(
      arguments['detail_level'],
      'summary',
    ).trim().toLowerCase();
    final useFullText = detailLevel == 'full';
    final projectedEntryPath = _projectedSkillEntryPath(
      project: project,
      skillPackage: skillPackage,
    );
    final instructionText = useFullText
        ? (instructionMarkdown.isNotEmpty
              ? instructionMarkdown
              : _fallbackInstructionText(skillPackage))
        : _skillInstructionDigestService.buildDigest(skillPackage);
    return _resultFactory.success(
      '已读取技能说明：${ValueReaders.stringValue(skillPackage['name'], skillId)}',
      data: <String, Object?>{
        'agent_id': agentId,
        'skill_id': skillId,
        'name': ValueReaders.stringValue(skillPackage['name'], skillId),
        'description': ValueReaders.stringValue(skillPackage['description']),
        'instructions': instructionText,
        'detail_level': useFullText ? 'full' : 'summary',
        'instruction_character_count': instructionMarkdown.length,
        'full_instruction_available': instructionMarkdown.isNotEmpty,
        'content': instructionText,
        if (useFullText) 'instruction_markdown': instructionMarkdown,
        'activation_hints': ValueReaders.stringList(
          skillPackage['activation_hints'],
        ),
        'inputs': ValueReaders.stringList(skillPackage['inputs']),
        'outputs': ValueReaders.stringList(skillPackage['outputs']),
        'required_capabilities': ValueReaders.stringList(
          skillPackage['required_capabilities'],
        ),
        'optional_capabilities': ValueReaders.stringList(
          skillPackage['optional_capabilities'],
        ),
        'preferred_output': ValueReaders.stringValue(
          skillPackage['preferred_output'],
        ),
        'safe_without_tools': ValueReaders.boolValue(
          skillPackage['safe_without_tools'],
          true,
        ),
        'resource_hints': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillPackage['resource_hints']),
        ),
        'tool_schema': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillPackage['tool_schema']),
        ),
        'source': ValueReaders.stringValue(skillPackage['source']),
        'source_scope': ValueReaders.stringValue(skillPackage['source_scope']),
        if (projectedEntryPath.isNotEmpty)
          'entry_file_path': projectedEntryPath,
        ...runtimeLoadoutData,
      },
    );
  }

  Future<JsonMap> _loadReference({
    required String agentId,
    required List<JsonMap> availableSkills,
    required String skillId,
    required JsonMap skillPackage,
    required String referencePath,
    required JsonMap runtimeLoadoutData,
  }) async {
    // 中文注释: reference 读取只开放技能元数据中显式声明的 reference 列表，避免模型越界扫包目录。
    final allowedReferences = ValueReaders.stringList(
      ValueReaders.mapValue(skillPackage['resource_hints'])['references'],
    ).map(_packageResourceReader.normalizeResourcePath).toSet();
    if (!allowedReferences.contains(referencePath)) {
      return _resultFactory.notExecuted(
        '当前技能没有开放这个 reference_path：$referencePath',
        data: <String, Object?>{
          'agent_id': agentId,
          'skill_id': skillId,
          'available_reference_paths': allowedReferences.toList(
            growable: false,
          ),
          'available_skills': availableSkills,
          ...runtimeLoadoutData,
        },
      );
    }
    final entryFilePath = ValueReaders.stringValue(
      skillPackage['entry_file_path'],
    ).trim();
    final referenceContent = await _packageResourceReader.readTextResource(
      entryFilePath,
      referencePath,
    );
    if (referenceContent == null || referenceContent.trim().isEmpty) {
      return _resultFactory.notExecuted(
        '该 reference 文件为空或不存在：$referencePath',
        data: <String, Object?>{
          'agent_id': agentId,
          'skill_id': skillId,
          'reference_path': referencePath,
          ...runtimeLoadoutData,
        },
      );
    }
    return _resultFactory.success(
      '已读取技能参考：${ValueReaders.stringValue(skillPackage['name'], skillId)} / $referencePath',
      data: <String, Object?>{
        'agent_id': agentId,
        'skill_id': skillId,
        'name': ValueReaders.stringValue(skillPackage['name'], skillId),
        'detail_level': 'reference',
        'reference_path': referencePath,
        'reference_content': referenceContent,
        'content': referenceContent,
        'reference_character_count': referenceContent.length,
        'available_reference_paths': allowedReferences.toList(growable: false),
        'resource_hints': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillPackage['resource_hints']),
        ),
        ...runtimeLoadoutData,
      },
    );
  }

  Future<ResolvedAgentSkillLoadout> _resolveRuntimeLoadout({
    required ProjectDescriptor project,
    required JsonMap agent,
    required List<Object?> availableSkillGroups,
    required List<String> availableSkillIds,
  }) async {
    // 中文注释: 没有项目级 runtime loadout 服务时，保持兼容回退到 agent 默认声明，不在执行器里自己拼规则。
    final service = _runtimeLoadoutService;
    if (service == null) {
      return AgentSkillLoadoutResolverService().resolveAgentDocument(
        agent,
        availableSkillGroups: availableSkillGroups,
        availableSkillIds: availableSkillIds,
      );
    }
    return service.resolveForAgent(
      project: project,
      agent: agent,
      availableSkillGroups: availableSkillGroups,
      availableSkillIds: availableSkillIds,
    );
  }

  JsonMap _runtimeLoadoutData(ResolvedAgentSkillLoadout loadout) {
    // 中文注释: 这里把运行时装载结果投影成轻量调试数据，供 probe/UI 后续复用，而不是暴露内部对象结构。
    return <String, Object?>{
      'resolved_skill_ids': loadout.finalSkillIds,
      'resolved_loadout_source': loadout.source.id,
      'resolved_loadout_has_explicit_selection': loadout.hasExplicitLoadout,
      'resolved_loadout_issues': loadout.issues
          .map(
            (issue) => <String, Object?>{
              'code': issue.code.name,
              'subject_id': issue.subjectId,
              'detail_ids': issue.detailIds,
              if (issue.message.trim().isNotEmpty) 'message': issue.message,
              if (issue.metadata.isNotEmpty)
                'metadata': ValueReaders.deepCopyMap(issue.metadata),
            },
          )
          .cast<Object?>()
          .toList(growable: false),
    };
  }

  JsonMap _resolvedAgent(JsonMap arguments) {
    final rawAgent = ValueReaders.mapValue(arguments['_agent']);
    if (rawAgent.isNotEmpty) {
      return rawAgent;
    }
    return _agentProfileCatalogService.fallbackDefaultAgent();
  }

  String _fallbackInstructionText(JsonMap skillPackage) {
    // 中文注释: 缺正文时仍给模型一个可执行的技能摘要，避免包格式小问题直接让流程中断。
    final lines = <String>[
      '技能名称：${ValueReaders.stringValue(skillPackage['name'], ValueReaders.stringValue(skillPackage['id']))}',
      '技能说明：${ValueReaders.stringValue(skillPackage['description'])}',
    ];
    final hints = ValueReaders.stringList(skillPackage['activation_hints']);
    if (hints.isNotEmpty) {
      lines.add('适用时机：${hints.join('；')}');
    }
    final preferredOutput = ValueReaders.stringValue(
      skillPackage['preferred_output'],
    ).trim();
    if (preferredOutput.isNotEmpty) {
      lines.add('优先输出：$preferredOutput');
    }
    return lines.join('\n');
  }

  String _projectedSkillEntryPath({
    required ProjectDescriptor project,
    required JsonMap skillPackage,
  }) {
    final entryFilePath = ValueReaders.stringValue(
      skillPackage['entry_file_path'],
    ).trim();
    if (entryFilePath.isEmpty) {
      return '';
    }
    final builtinPath = _builtinSkillEntryPath(skillPackage);
    if (builtinPath.isNotEmpty) {
      return builtinPath;
    }
    final projectPath = _projectSkillEntryPath(project, entryFilePath);
    if (projectPath.isNotEmpty) {
      return projectPath;
    }
    final skillId = ValueReaders.stringValue(skillPackage['id']).trim();
    if (skillId.isEmpty) {
      return 'package://skill/SKILL.md';
    }
    return 'package://skills/$skillId/SKILL.md';
  }

  String _builtinSkillEntryPath(JsonMap skillPackage) {
    final entryFilePath = ValueReaders.stringValue(
      skillPackage['entry_file_path'],
    ).trim();
    final packageRootPath = ValueReaders.stringValue(
      skillPackage['package_root_path'],
    ).trim();
    final normalizedRoot = packageRootPath.replaceAll('\\', '/').toLowerCase();
    if (!normalizedRoot.endsWith('/builtin_packages/skills')) {
      return '';
    }
    final relativePath = _safeRelativePath(
      rootPath: packageRootPath,
      absolutePath: entryFilePath,
    );
    if (relativePath.isEmpty) {
      return '';
    }
    return 'builtin://skills/$relativePath';
  }

  String _projectSkillEntryPath(
    ProjectDescriptor project,
    String entryFilePath,
  ) {
    return _safeRelativePath(
      rootPath: project.rootPath,
      absolutePath: entryFilePath,
    );
  }

  String _safeRelativePath({
    required String rootPath,
    required String absolutePath,
  }) {
    final cleanRootPath = rootPath.trim();
    final cleanAbsolutePath = absolutePath.trim();
    if (cleanRootPath.isEmpty || cleanAbsolutePath.isEmpty) {
      return '';
    }
    try {
      return _projectRelativePathResolver.relative(
        rootPath: cleanRootPath,
        absolutePath: cleanAbsolutePath,
      );
    } on ArgumentError {
      return '';
    }
  }
}
