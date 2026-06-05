import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_session_projection_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('seed-driven 长任务项目会自动识别唯一可用开局组并提示先选模式', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[
        _starterLongNovelSeedGroup(),
        _starterLongNovelFullOutlineGroup(),
      ],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-1',
        name: '长篇项目',
        rootPath: 'D:/Projects/long_project',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
        runtimeMode: 'long_task_project',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, 'starter_long_novel_seed_generalist');
    expect(projection.currentGroupDisplayName, '默认长任务灵感开局');
    expect(projection.currentPrimaryAgentSummary?.displayName, '综合创作智能体');
    expect(projection.currentPrimaryAgentSummary?.thinkingSupported, isTrue);
    expect(projection.supportedGroups, hasLength(1));
    expect(projection.unsupportedGroups, hasLength(1));
    expect(
      projection.unsupportedGroups.single.groupId,
      'starter_long_novel_full_outline_generalist',
    );
    expect(
      projection.orchestration.suggestedActions.single.commandId,
      'opening.choose_long_task_mode',
    );
  });

  test('ready 的 seed-driven 长任务模式会把 opening 收束到启动动作', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[_starterLongNovelSeedGroup()],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final transitionService = ModeGuidanceTransitionService();
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-2',
        name: '长篇项目',
        rootPath: 'D:/Projects/ready_long_project',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
        runtimeMode: 'long_task_project',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: _readyModeGuidanceState(
        transitionService,
        'seed_autopilot_novel',
      ),
    );

    expect(projection.orchestration.readiness.canStartLongTask, isTrue);
    expect(
      projection.orchestration.suggestedActions.single.commandId,
      'opening.start_long_task_run',
    );
  });

  test('full-outline 长任务项目会自动识别 full-outline 开局组', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[
        _starterLongNovelSeedGroup(),
        _starterLongNovelFullOutlineGroup(),
      ],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-4',
        name: '全纲长篇项目',
        rootPath: 'D:/Projects/full_outline_project',
        projectType: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
        runtimeMode: 'long_task_project',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(
      projection.currentGroupId,
      'starter_long_novel_full_outline_generalist',
    );
    expect(projection.currentGroupDisplayName, '默认长任务全纲开局');
    expect(projection.supportedGroups, hasLength(1));
    expect(
      projection.supportedGroups.single.groupId,
      'starter_long_novel_full_outline_generalist',
    );
    expect(
      projection.unsupportedGroups.single.groupId,
      'starter_long_novel_seed_generalist',
    );
  });

  test('普通小说项目在已有会话目标后会变成可直接开始会话', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[_starterNovelGroup()],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-3',
        name: '普通项目',
        rootPath: 'D:/Projects/novel_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
      sessionGoalModeId: SessionRecordConstants.modeSmartOpening,
    );

    expect(
      projection.orchestration.readiness.canStartInteractiveSession,
      isTrue,
    );
    expect(
      projection.orchestration.suggestedActions.single.commandId,
      'opening.start_interactive_session',
    );
  });

  test('默认小说开局组会保留 default_generalist 作为组成员与主智能体', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[_starterNovelGroup()],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-default-group',
        name: '默认组项目',
        rootPath: 'D:/Projects/default_group_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, 'starter_novel_generalist');
    expect(
      projection.currentPrimaryAgentSummary?.agentId,
      'default_generalist',
    );
    expect(projection.supportedGroups, hasLength(1));
    expect(
      projection.supportedGroups.single.members.map((member) => member.agentId),
      <String>['default_generalist'],
    );
    expect(
      projection.supportedGroups.single.members.single.displayName,
      '综合创作智能体',
    );
  });

  test('项目没有默认智能体文件时仍会用内置默认组进入普通开局', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => const <JsonMap>[],
      loadAgentGroups: (_) async => <JsonMap>[_starterNovelGroup()],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-fallback-default-agent',
        name: '默认智能体兜底项目',
        rootPath: 'D:/Projects/fallback_default_agent_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, 'starter_novel_generalist');
    expect(
      projection.currentPrimaryAgentSummary?.agentId,
      'default_generalist',
    );
    expect(projection.supportedGroups, hasLength(1));
    expect(
      projection.orchestration.readiness.missingRequirements.map(
        (item) => item.id,
      ),
      isNot(contains('agent_group')),
    );
  });

  test('拆书项目会识别拆书 starter group 并进入普通会话 ready', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => <JsonMap>[
        _starterBookDeconstructionGroup(),
      ],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-5',
        name: '拆书项目',
        rootPath: 'D:/Projects/deconstruction_project',
        projectType: 'book_deconstruction',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'book_deconstruction',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
      freeTextIntent: '先帮我整理这本书的结构与资产。',
    );

    expect(projection.currentGroupId, 'starter_book_deconstruction_generalist');
    expect(projection.currentGroupDisplayName, '默认拆书整理');
    expect(
      projection.orchestration.readiness.canStartInteractiveSession,
      isTrue,
    );
    expect(
      projection.orchestration.suggestedActions.single.commandId,
      'opening.start_interactive_session',
    );
  });

  test('当前组会正式产出可用成员列表，且主成员排在可解析结果中', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[
        _generalistAgent(),
        _reviewerAgent(),
      ],
      loadAgentGroups: (_) async => <JsonMap>[_multiAgentNovelGroup()],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[
            ProjectAgentGroupSelection(
              groupId: 'starter_novel_multi_agent',
              selectedByDefault: true,
            ),
          ],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-6',
        name: '多智能体项目',
        rootPath: 'D:/Projects/multi_agent_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, 'starter_novel_multi_agent');
    expect(
      projection.currentPrimaryAgentSummary?.agentId,
      'default_generalist',
    );
    expect(projection.availableAgentSummaries, hasLength(2));
    expect(
      projection.availableAgentSummaries.map((member) => member.agentId),
      <String>['default_generalist', 'review_specialist'],
    );
    expect(projection.availableAgentSummaries.first.isPrimary, isTrue);
    expect(projection.availableAgentSummaries.last.description, '负责补充审阅和校对建议');
  });

  test('没有解析出当前组时，会回退为空成员列表和空主成员摘要', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[_generalistAgent()],
      loadAgentGroups: (_) async => const <JsonMap>[],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-7',
        name: '空组项目',
        rootPath: 'D:/Projects/empty_group_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, isEmpty);
    expect(projection.currentPrimaryAgentSummary, isNull);
    expect(projection.availableAgentSummaries, isEmpty);
  });

  test('当前组切换后，可用成员列表会跟随切到新组成员', () async {
    final service = ProjectOpeningSessionProjectionService(
      loadAgentPackages: (_) async => <JsonMap>[
        _generalistAgent(),
        _reviewerAgent(),
        _plannerAgent(),
      ],
      loadAgentGroups: (_) async => <JsonMap>[
        _multiAgentNovelGroup(),
        _plannerNovelGroup(),
      ],
      loadProjectAgentGroupSelections: (_) async =>
          const <ProjectAgentGroupSelection>[
            ProjectAgentGroupSelection(
              groupId: 'starter_novel_planner_only',
              selectedByDefault: true,
            ),
          ],
    );
    final projection = await service.build(
      project: const ProjectDescriptor(
        id: 'project-8',
        name: '切组项目',
        rootPath: 'D:/Projects/switch_group_project',
        projectType: 'novel',
      ),
      runtimeProfile: const ProjectRuntimeProfile(
        projectType: 'novel',
        runtimeBaselineId: '',
        runtimeMode: '',
        initialRunOptions: <String, Object?>{},
      ),
      modeGuidanceState: null,
    );

    expect(projection.currentGroupId, 'starter_novel_planner_only');
    expect(projection.availableAgentSummaries, hasLength(1));
    expect(
      projection.availableAgentSummaries.single.agentId,
      'planner_specialist',
    );
    expect(
      projection.currentPrimaryAgentSummary?.agentId,
      'planner_specialist',
    );
  });
}

JsonMap _generalistAgent() {
  return <String, Object?>{
    'id': 'default_generalist',
    'name': '综合创作智能体',
    'role': '主智能体',
    'description': '默认主智能体',
  };
}

JsonMap _starterLongNovelSeedGroup() {
  return <String, Object?>{
    'id': 'starter_long_novel_seed_generalist',
    'name': '默认长任务灵感开局组',
    'description': '默认长任务灵感开局',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['default_generalist'],
    'primary_agent_id': 'default_generalist',
    'required_agent_ids': <String>['default_generalist'],
    'display_label': '默认长任务灵感开局',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['long_novel'],
      'required_trait_ids': <String>['long_task', 'seed_driven'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _starterLongNovelFullOutlineGroup() {
  return <String, Object?>{
    'id': 'starter_long_novel_full_outline_generalist',
    'name': '默认长任务全纲开局组',
    'description': '默认长任务全纲开局',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['default_generalist'],
    'primary_agent_id': 'default_generalist',
    'required_agent_ids': <String>['default_generalist'],
    'display_label': '默认长任务全纲开局',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['long_novel'],
      'required_trait_ids': <String>['long_task', 'full_outline'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _starterNovelGroup() {
  return <String, Object?>{
    'id': 'starter_novel_generalist',
    'name': '默认小说开局组',
    'description': '默认小说开局',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['default_generalist'],
    'primary_agent_id': 'default_generalist',
    'required_agent_ids': <String>['default_generalist'],
    'display_label': '默认小说开局',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['novel'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _multiAgentNovelGroup() {
  return <String, Object?>{
    'id': 'starter_novel_multi_agent',
    'name': '默认小说协作组',
    'description': '默认小说协作组',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['default_generalist', 'review_specialist'],
    'primary_agent_id': 'default_generalist',
    'required_agent_ids': <String>['default_generalist'],
    'optional_agent_ids': <String>['review_specialist'],
    'display_label': '默认小说协作组',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['novel'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _plannerNovelGroup() {
  return <String, Object?>{
    'id': 'starter_novel_planner_only',
    'name': '默认小说策划组',
    'description': '默认小说策划组',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['planner_specialist'],
    'primary_agent_id': 'planner_specialist',
    'required_agent_ids': <String>['planner_specialist'],
    'display_label': '默认小说策划组',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['novel'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _starterBookDeconstructionGroup() {
  return <String, Object?>{
    'id': 'starter_book_deconstruction_generalist',
    'name': '默认拆书整理组',
    'description': '默认拆书整理',
    'enabled': true,
    'orchestration': 'supervised',
    'agents': <String>['default_generalist'],
    'primary_agent_id': 'default_generalist',
    'required_agent_ids': <String>['default_generalist'],
    'display_label': '默认拆书整理',
    'applicability_scope': <String, Object?>{
      'allowed_project_type_ids': <String>['book_deconstruction'],
    },
    'metadata': <String, Object?>{'starter_group': true},
  };
}

JsonMap _reviewerAgent() {
  return <String, Object?>{
    'id': 'review_specialist',
    'name': '审阅智能体',
    'role': '审阅协作',
    'description': '负责补充审阅和校对建议',
    'thinking_supported': false,
  };
}

JsonMap _plannerAgent() {
  return <String, Object?>{
    'id': 'planner_specialist',
    'name': '策划智能体',
    'role': '结构策划',
    'description': '负责整理结构和推进计划',
    'thinking_supported': true,
  };
}

ModeGuidanceState _readyModeGuidanceState(
  ModeGuidanceTransitionService transitionService,
  String modeId,
) {
  var state = transitionService.initialize(modeId);
  while (!state.isReady) {
    final question = transitionService.buildQuestion(state);
    state = transitionService.answer(
      state,
      stageId: question.stageId,
      fieldKey: question.fieldKey,
      value: '测试 ${question.stageId}',
      label: '测试 ${question.stageId}',
      source: 'test',
    );
  }
  return state;
}
