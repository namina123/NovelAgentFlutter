import 'autonomy_policy.dart';
import 'checkpoint_policy.dart';
import '../deconstruction/book_deconstruction_constants.dart';
import 'mode_definition.dart';
import 'mode_stage_definition.dart';
import 'mode_stage_option.dart';
import 'project_strategy.dart';
import 'workflow_strategy.dart';

class StrategyCatalogService {
  const StrategyCatalogService();

  static const String longTaskNovelStrategyId = 'long_task_novel';
  static const String workflowResumableLongTaskId = 'resumable_long_task';

  List<ProjectStrategy> projectStrategies() {
    return const <ProjectStrategy>[
      ProjectStrategy(
        id: 'general_novel',
        title: '一般小说',
        description: '以普通协作式创作为主，可随时进入章节、设定、审稿与修订。',
      ),
      ProjectStrategy(
        id: longTaskNovelStrategyId,
        title: '长任务长篇',
        description: '以可恢复任务链、阶段检查点和长期上下文资产为核心。',
        supportedModeIds: <String>[
          'seed_autopilot_novel',
          'full_outline_consensus',
          'volume_checkpoint_handoff',
          'chapter_brief_supervised',
          'salvage_restructure_existing',
        ],
      ),
      ProjectStrategy(
        id: 'short_collection',
        title: '短文集',
        description: '以短篇选题、合集统一风格和分篇整理为主。',
      ),
      ProjectStrategy(
        id: 'book_deconstruction',
        title: '拆书',
        description: '以拆解外部作品结构、抽取资产和重建方法为主。',
        supportedModeIds: <String>[
          BookDeconstructionConstants.modeAssetExtraction,
        ],
      ),
    ];
  }

  List<WorkflowStrategy> workflowStrategies() {
    return const <WorkflowStrategy>[
      WorkflowStrategy(
        id: 'interactive_session',
        title: '交互会话',
        description: '以对话推进、即时反馈和人工选择为主。',
        supportsGuidedOpening: true,
      ),
      WorkflowStrategy(
        id: workflowResumableLongTaskId,
        title: '可恢复长任务',
        description: '以任务链、检查点和可恢复运行记录为主。',
        supportsGuidedOpening: true,
        supportsResumableTasks: true,
      ),
    ];
  }

  List<ModeDefinition> modeDefinitions() {
    const lowTouchAutonomy = AutonomyPolicy(
      id: 'low_touch_autonomy',
      title: '低频确认',
      description: '主智能体负责长期规划与推进，仅在关键节点回到人类确认。',
      allowAutonomousPlanning: true,
      allowAutonomousDrafting: true,
      allowAutonomousRevision: true,
    );
    const outlineConsensusAutonomy = AutonomyPolicy(
      id: 'outline_consensus',
      title: '前期共拟',
      description: '先与人类共同收束总纲，再转入自动推进。',
      allowAutonomousPlanning: false,
      allowAutonomousDrafting: true,
      allowAutonomousRevision: true,
    );
    const volumeCheckpointPolicy = CheckpointPolicy(
      id: 'volume_checkpoint',
      title: '分卷检查点',
      description: '以卷为主要确认边界，卷内保持较高自主度。',
      defaultChapterInterval: 4,
      requireOutlineConfirmation: true,
      requireVolumeConfirmation: true,
    );
    const chapterCheckpointPolicy = CheckpointPolicy(
      id: 'chapter_checkpoint',
      title: '按章检查点',
      description: '每章或每组章纲后停下确认。',
      defaultChapterInterval: 1,
      requireOutlineConfirmation: true,
    );
    const lowTouchCheckpointPolicy = CheckpointPolicy(
      id: 'low_touch_checkpoint',
      title: '低频检查点',
      description: '仅在世界观、总主线和关键阶段切换时要求确认。',
      defaultChapterInterval: 4,
      requireOutlineConfirmation: true,
    );
    const deconstructionAutonomy = AutonomyPolicy(
      id: 'deconstruction_assisted',
      title: '结构化提取辅助',
      description: '以人工确认提取结果为主，允许智能体辅助归纳与整理，但不自动推进长链运行。',
      allowAutonomousPlanning: false,
      allowAutonomousDrafting: false,
      allowAutonomousRevision: false,
    );
    const deconstructionCheckpointPolicy = CheckpointPolicy(
      id: 'deconstruction_apply_confirm',
      title: '应用前确认',
      description: '拆书结果先进入结构化预览，再由用户选择如何应用到项目资产。',
      defaultChapterInterval: 0,
      requireOutlineConfirmation: false,
      requireVolumeConfirmation: false,
    );
    return const <ModeDefinition>[
      ModeDefinition(
        id: BookDeconstructionConstants.modeAssetExtraction,
        projectStrategyId: BookDeconstructionConstants.projectStrategyId,
        workflowStrategyId:
            BookDeconstructionConstants.workflowInteractiveSession,
        title: '拆书资产提取',
        description: '导入外部作品并抽取前提、结构和共享资产，再生成可确认的应用计划。',
        defaultAutonomyPolicy: deconstructionAutonomy,
        defaultCheckpointPolicy: deconstructionCheckpointPolicy,
      ),
      ModeDefinition(
        id: 'seed_autopilot_novel',
        projectStrategyId: longTaskNovelStrategyId,
        workflowStrategyId: workflowResumableLongTaskId,
        title: '灵感托管式长篇',
        description: '人类先提供创作种子与边界，后续大部分规划和推进交由智能体托管。',
        defaultAutonomyPolicy: lowTouchAutonomy,
        defaultCheckpointPolicy: lowTouchCheckpointPolicy,
        stages: <ModeStageDefinition>[
          ModeStageDefinition(
            id: 'seed_scope',
            title: '灵感种子',
            description: '先确认你手里目前到底有什么材料，避免智能体假装已经拥有完整大纲。',
            fieldKey: 'seed_scope',
            helperText: '可选一个最接近的起点，也可以直接自由描述。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'seed_scope_idea',
                fieldKey: 'seed_scope',
                label: '只有一句灵感',
                value: '只有一句灵感或一个核心卖点，还没有明确大纲。',
              ),
              ModeStageOption(
                id: 'seed_scope_setting',
                fieldKey: 'seed_scope',
                label: '已有题材设定',
                value: '已有题材、世界观或能力体系，但主线和角色还未收束。',
              ),
              ModeStageOption(
                id: 'seed_scope_fragment',
                fieldKey: 'seed_scope',
                label: '已有零散片段',
                value: '已经写过若干片段、开头或场景，但整体结构未成型。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'core_promise',
            title: '核心承诺',
            description: '定义这本书最想兑现给读者的体验、冲突或爽点。',
            fieldKey: 'core_promise',
            helperText: '这会成为长期风格和主线规划的上位约束。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'core_promise_growth',
                fieldKey: 'core_promise',
                label: '升级成长',
                value: '核心承诺偏向持续升级、阶段突破和成长兑现。',
              ),
              ModeStageOption(
                id: 'core_promise_intrigue',
                fieldKey: 'core_promise',
                label: '权谋悬压',
                value: '核心承诺偏向权谋、压迫感、局势逆转和高压博弈。',
              ),
              ModeStageOption(
                id: 'core_promise_group',
                fieldKey: 'core_promise',
                label: '群像史诗',
                value: '核心承诺偏向群像推进、阵营对抗和长期史诗感。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'world_anchor',
            title: '世界锚点',
            description: '确认世界规则、时代气质和不能随便改动的底层边界。',
            fieldKey: 'world_anchor',
            helperText: '至少给出能约束后续写作的世界事实或规则。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'world_anchor_xianxia',
                fieldKey: 'world_anchor',
                label: '修炼体系',
                value: '世界拥有明确修炼或成长体系，资源、势力与境界决定长期冲突。',
              ),
              ModeStageOption(
                id: 'world_anchor_urban',
                fieldKey: 'world_anchor',
                label: '都市现实',
                value: '世界建立在现代都市或近现实逻辑上，奇异能力需要解释和隐藏成本。',
              ),
              ModeStageOption(
                id: 'world_anchor_fantasy',
                fieldKey: 'world_anchor',
                label: '奇幻秩序',
                value: '世界拥有多阵营、地理边界和稳定规则，冲突会跨区域和跨势力扩张。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'protagonist_drive',
            title: '主角驱动力',
            description: '主角最稳定的欲望、缺口或强制任务是什么。',
            fieldKey: 'protagonist_drive',
            helperText: '这会影响主线持续动力和阶段目标设计。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'protagonist_drive_survive',
                fieldKey: 'protagonist_drive',
                label: '求生破局',
                value: '主角最初以求生、自保或摆脱困境为第一驱动力。',
              ),
              ModeStageOption(
                id: 'protagonist_drive_revenge',
                fieldKey: 'protagonist_drive',
                label: '复仇翻盘',
                value: '主角最初以复仇、翻案或夺回失去之物为第一驱动力。',
              ),
              ModeStageOption(
                id: 'protagonist_drive_guard',
                fieldKey: 'protagonist_drive',
                label: '守护建立',
                value: '主角最初以守护某人某地某秩序，并逐步建立自己的体系为驱动力。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'style_target',
            title: '风格与边界',
            description: '定义叙事口吻、节奏感、禁区和你不想让智能体写成什么样。',
            fieldKey: 'style_target',
            helperText: '可写想要的风格，也可写绝不接受的味道。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'style_target_crisp',
                fieldKey: 'style_target',
                label: '干净利落',
                value: '文风追求干净、利落、少废话，冲突推进清晰，段落不过度抒情。',
              ),
              ModeStageOption(
                id: 'style_target_immersive',
                fieldKey: 'style_target',
                label: '沉浸细腻',
                value: '文风追求沉浸、细腻和氛围感，但不能失去清晰叙事推进。',
              ),
              ModeStageOption(
                id: 'style_target_commercial',
                fieldKey: 'style_target',
                label: '商业网文',
                value: '文风偏商业阅读体验，强调爽点、钩子、留悬与高可读性。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'autonomy_guardrails',
            title: '托管边界',
            description: '明确哪些地方可以完全交给智能体，哪些地方必须先回到人类确认。',
            fieldKey: 'autonomy_guardrails',
            helperText: '这是长任务真正可长期运行的关键约束。',
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'autonomy_guardrails_low_touch',
                fieldKey: 'autonomy_guardrails',
                label: '低频确认',
                value: '除世界观底线、总主线和重大转折外，其余推进默认由智能体托管。',
              ),
              ModeStageOption(
                id: 'autonomy_guardrails_volume',
                fieldKey: 'autonomy_guardrails',
                label: '按卷确认',
                value: '卷内由智能体推进，跨卷结构和结局转折必须回到人类确认。',
              ),
              ModeStageOption(
                id: 'autonomy_guardrails_outline',
                fieldKey: 'autonomy_guardrails',
                label: '先纲后文',
                value: '正文可以托管，但总纲、卷纲和关键章纲必须先确认。',
              ),
            ],
          ),
          ModeStageDefinition(
            id: 'review_ready',
            title: '开始托管',
            description: '确认以上信息可以转成长期任务链。',
            fieldKey: 'review_ready',
            helperText: '如果你已经准备好，可以直接确认开始托管。',
            allowFreeText: false,
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'review_ready_confirm',
                fieldKey: 'review_ready',
                label: '开始托管',
                value: '已确认以上信息，可以开始生成可恢复长任务链。',
              ),
            ],
          ),
        ],
      ),
      ModeDefinition(
        id: 'full_outline_consensus',
        projectStrategyId: longTaskNovelStrategyId,
        workflowStrategyId: workflowResumableLongTaskId,
        title: '全书共拟式长篇',
        description: '先一起谈清全书走向，再进入执行期。',
        defaultAutonomyPolicy: outlineConsensusAutonomy,
        defaultCheckpointPolicy: chapterCheckpointPolicy,
        stages: <ModeStageDefinition>[
          ModeStageDefinition(
            id: 'book_premise',
            title: '故事总前提',
            description: '先确认题材、核心卖点与故事总前提。',
            fieldKey: 'book_premise',
            helperText: '这里要的是全书前提，不是单个场景灵感。',
          ),
          ModeStageDefinition(
            id: 'main_arc',
            title: '主线与冲突',
            description: '明确主线目标、主要矛盾与核心对抗关系。',
            fieldKey: 'main_arc',
            helperText: '尽量说清楚主角、反派、阶段目标和冲突升级方式。',
          ),
          ModeStageDefinition(
            id: 'volume_map',
            title: '分卷结构',
            description: '确认全书大致会如何分卷，每卷承担什么阶段任务。',
            fieldKey: 'volume_map',
            helperText: '至少给出前几卷的阶段功能和转折方向。',
          ),
          ModeStageDefinition(
            id: 'ending_commitment',
            title: '结局承诺',
            description: '确定全书最终想落到怎样的结局或结局范围。',
            fieldKey: 'ending_commitment',
            helperText: '不一定要锁死细节，但必须给出结局方向和不可违背的结果。',
          ),
          ModeStageDefinition(
            id: 'style_and_boundaries',
            title: '风格与边界',
            description: '确认全书统一风格、禁区和不希望智能体偏离的地方。',
            fieldKey: 'style_and_boundaries',
          ),
          ModeStageDefinition(
            id: 'consensus_confirm',
            title: '确认开建',
            description: '确认当前全书共识已经足够进入可恢复长任务。',
            fieldKey: 'consensus_confirm',
            allowFreeText: false,
            options: <ModeStageOption>[
              ModeStageOption(
                id: 'consensus_confirm_start',
                fieldKey: 'consensus_confirm',
                label: '开始建长任务',
                value: '当前全书共识已经足够，可以开始生成总纲、卷纲和执行队列。',
              ),
            ],
          ),
        ],
      ),
      ModeDefinition(
        id: 'volume_checkpoint_handoff',
        projectStrategyId: longTaskNovelStrategyId,
        workflowStrategyId: workflowResumableLongTaskId,
        title: '分卷检查点式长篇',
        description: '先定总主线，再按卷推进，每卷结束统一确认。',
        defaultAutonomyPolicy: lowTouchAutonomy,
        defaultCheckpointPolicy: volumeCheckpointPolicy,
      ),
      ModeDefinition(
        id: 'chapter_brief_supervised',
        projectStrategyId: longTaskNovelStrategyId,
        workflowStrategyId: workflowResumableLongTaskId,
        title: '章纲监督式长篇',
        description: '章纲与阶段目标先确认，正文与修订自动推进。',
        defaultAutonomyPolicy: outlineConsensusAutonomy,
        defaultCheckpointPolicy: chapterCheckpointPolicy,
      ),
      ModeDefinition(
        id: 'salvage_restructure_existing',
        projectStrategyId: longTaskNovelStrategyId,
        workflowStrategyId: workflowResumableLongTaskId,
        title: '旧稿抢救重构式长篇',
        description: '从旧稿、碎稿和半成品出发，先重构再续写。',
        defaultAutonomyPolicy: outlineConsensusAutonomy,
        defaultCheckpointPolicy: chapterCheckpointPolicy,
      ),
    ];
  }

  ModeDefinition modeDefinitionById(String modeId) {
    final cleanModeId = modeId.trim();
    for (final definition in modeDefinitions()) {
      if (definition.id == cleanModeId) {
        return definition;
      }
    }
    return modeDefinitions().first;
  }
}
