import '../session/session_record_constants.dart';
import '../project/knowledge_base_branch_catalog_service.dart';
import 'session_guide_action.dart';
import 'session_guide_profile.dart';

class SessionGuideProfileService {
  const SessionGuideProfileService();

  SessionGuideProfile resolve({
    required String projectType,
    String projectBranchId = '',
    bool needsGoalSelection = true,
    bool isRunning = false,
  }) {
    // 中文注释: 会话引导 profile 只负责项目类型对应的入口文案和动作，不直接触发任何宿主行为。
    switch (projectType.trim()) {
      case 'book_deconstruction':
        return _bookDeconstructionProfile(isRunning: isRunning);
      case 'long_novel':
        return _longNovelProfile(isRunning: isRunning);
      case 'knowledge_base':
        return _knowledgeBaseProfile(
          projectBranchId: projectBranchId,
          isRunning: isRunning,
        );
      case 'short_collection':
        return _shortCollectionProfile(isRunning: isRunning);
      case 'novel':
      default:
        return _novelProfile(
          needsGoalSelection: needsGoalSelection,
          isRunning: isRunning,
        );
    }
  }

  SessionGuideProfile _novelProfile({
    required bool needsGoalSelection,
    required bool isRunning,
  }) {
    return SessionGuideProfile(
      profileId: 'default_novel',
      title: needsGoalSelection ? '这次想让智能体做什么？' : '开始会话',
      description: needsGoalSelection
          ? '这些是普通小说项目的默认入口。选一个目标开局，或者直接输入第一句话也可以。'
          : '先选一个写作目标，或者直接输入你的创作需求开始对话。',
      composerHint: isRunning
          ? '运行中：继续补充开局、章节、设定或修订要求，会在下一轮工具调用前送达。'
          : '输入下一次发送给主智能体的提示词；它会携带当前小说项目上下文。',
      statusHint: '',
      primaryActions: const <SessionGuideAction>[
        SessionGuideAction(
          id: 'session.goal.smart_opening',
          commandId: 'session.goal',
          title: '智能开局',
          description: '从题材、主角、冲突和第一章钩子开始收束开局方向。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeSmartOpening,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.summarize_book',
          commandId: 'session.goal',
          title: '总结全书',
          description: '整理已有正文、场景片段、摘要和设定，判断当前脉络与风险。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeSummarizeBook,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.chapter_draft',
          commandId: 'session.goal',
          title: '创作章节',
          description: '围绕当前上下文推进一章正文或一个可写场景。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeChapterDraft,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.import_article',
          commandId: 'session.goal',
          title: '导入文章',
          description: '把外部资料整理进项目上下文，再决定后续归档和使用方式。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeImportArticle,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.continue_writing',
          commandId: 'session.goal',
          title: '继续创作',
          description: '基于最近章节、场景片段或当前打开内容继续向前写。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeContinueWriting,
          },
        ),
      ],
    );
  }

  SessionGuideProfile _longNovelProfile({required bool isRunning}) {
    return SessionGuideProfile(
      profileId: 'long_novel_workflow',
      title: '长篇小说工作台',
      description: '长篇项目优先围绕任务队列、检查点和可恢复推进来组织。先选一种长任务写作模式，再决定如何生成、检查和推进任务链。',
      composerHint: isRunning
          ? '长篇运行中：补充队列调整、检查点要求或下一步约束，会在下一轮工具调用前送达。'
          : '输入长篇创作要求、长任务类型、队列调整意见，或直接描述当前想推进的阶段。',
      statusHint: '长篇队列会保存在当前项目 tasks/，运行记录保存在 tracking/，不会跨项目共享。',
      primaryActions: <SessionGuideAction>[
        SessionGuideAction(
          id: 'guide.open_long_task_modes',
          commandId: 'guide.open_long_task_modes',
          title: '长任务开局',
          description: '先细分选择长篇协作模式，再生成适合该模式的可恢复任务链。',
        ),
        SessionGuideAction(
          id: 'long_task.create_queue.seed_to_full_novel',
          commandId: 'long_task.create_queue',
          title: '直接生成队列',
          description: '跳过模式细分，按当前项目资料直接尝试生成默认长篇任务链。',
          payload: <String, Object?>{'mode': 'seed_to_full_novel'},
        ),
        SessionGuideAction(
          id: 'long_task.run_next',
          commandId: 'long_task.run_next',
          title: '运行下一步',
          description: '只推进一个安全单步，适合手动测试当前任务链是否就绪。',
        ),
        SessionGuideAction(
          id: 'long_task.run_controlled',
          commandId: 'long_task.run_controlled',
          title: '受控连续运行',
          description: '小步连续推进，遇到确认点、失败或无输出时自动停下。',
        ),
        SessionGuideAction(
          id: 'long_task.open_detail',
          commandId: 'long_task.open_detail',
          title: '查看队列详情',
          description: '检查当前项目的任务链、依赖、执行包和运行记录，再决定下一步。',
        ),
      ],
    );
  }

  SessionGuideProfile _knowledgeBaseProfile({
    required String projectBranchId,
    required bool isRunning,
  }) {
    if (const KnowledgeBaseBranchCatalogService().isRagBranch(
      projectBranchId,
    )) {
      return SessionGuideProfile(
        profileId: 'knowledge_base_rag',
        title: '语料库工作台',
        description: '语料库优先围绕语料导入、切分清洗、构建语料包和挂载验证展开，不把这里当作正式写作会话主面板。',
        composerHint: isRunning
            ? '运行中：补充切分要求、过滤约束或挂载目标，会在下一轮工具调用前送达。'
            : '先进入语料提取面板，选择语料来源、构建方式或挂载目标。',
        statusHint: '',
        primaryActions: const <SessionGuideAction>[
          SessionGuideAction(
            id: 'guide.open_project_assets_rag',
            commandId: 'guide.open_project_assets_rag',
            title: '打开语料提取',
            description: '进入语料提取与挂载面板，开始构建或检查当前资料库。',
          ),
        ],
      );
    }
    return SessionGuideProfile(
      profileId: 'knowledge_base',
      title: '知识库工作台',
      description: '知识库项目优先围绕资料导入、结构化摘要、检索验证和问答测试展开。',
      composerHint: isRunning
          ? '运行中：补充资料约束或检索目标，会在下一轮工具调用前送达。'
          : '输入要导入、整理、检索或验证的资料目标。',
      statusHint: '',
      primaryActions: <SessionGuideAction>[
        SessionGuideAction(
          id: 'session.goal.import_article.knowledge',
          commandId: 'session.goal',
          title: '导入文章',
          description: '把外部资料整理为可检索上下文。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeImportArticle,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.summarize_book.knowledge',
          commandId: 'session.goal',
          title: '总结资料',
          description: '概括当前资料并指出缺口。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeSummarizeBook,
          },
        ),
      ],
    );
  }

  SessionGuideProfile _bookDeconstructionProfile({required bool isRunning}) {
    return SessionGuideProfile(
      profileId: 'book_deconstruction',
      title: '拆书工作台',
      description: '先导入书籍原文；导入后应继续收束拆书分析资产，再进入续写或同人创作路线。',
      composerHint: isRunning
          ? '整理中：可以继续补充风格、世界规则、角色、剧情线或后续路线要求。'
          : '先导入书籍，或继续分析数据、开始创作。',
      statusHint: '导入后的原文、结构化拆书预览，以及角色/背景/风格/剧情线等分析资产都会保留在当前项目中。',
      primaryActions: const <SessionGuideAction>[
        SessionGuideAction(
          id: 'workspace.open_import_command',
          commandId: 'workspace.open_import_command',
          title: '导入书籍',
          description: '选择源文稿或文件夹导入当前拆书项目，并为后续结构化分析准备原文材料。',
        ),
        SessionGuideAction(
          id: 'session.goal.summarize_book.book_deconstruction',
          commandId: 'session.goal',
          title: '分析数据',
          description: '围绕已导入原文整理结构、角色、背景、风格、剧情线与后续承接风险。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeSummarizeBook,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.chapter_draft.book_deconstruction',
          commandId: 'session.goal',
          title: '开始创作',
          description: '基于当前拆书结果进入续写或同人创作阶段，先产出正式可写内容。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeChapterDraft,
          },
        ),
      ],
    );
  }

  SessionGuideProfile _shortCollectionProfile({required bool isRunning}) {
    return SessionGuideProfile(
      profileId: 'short_collection',
      title: '短文集工作台',
      description: '短文集项目更适合选题、单篇内容创作、风格统一和合集整理。',
      composerHint: isRunning
          ? '运行中：补充风格、篇幅或合集约束，会在下一轮工具调用前送达。'
          : '输入短篇选题、风格要求、合集整理或续写目标。',
      statusHint: '',
      primaryActions: <SessionGuideAction>[
        SessionGuideAction(
          id: 'session.goal.chapter_draft.short_collection',
          commandId: 'session.goal',
          title: '生成内容',
          description: '围绕一个短篇目标生成正文或场景。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeChapterDraft,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.continue_writing.short_collection',
          commandId: 'session.goal',
          title: '续写短篇',
          description: '基于当前打开内容继续写。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeContinueWriting,
          },
        ),
        SessionGuideAction(
          id: 'session.goal.summarize_book.short_collection',
          commandId: 'session.goal',
          title: '整理合集',
          description: '总结当前短文集结构和统一性。',
          payload: <String, Object?>{
            'mode': SessionRecordConstants.modeSummarizeBook,
          },
        ),
      ],
    );
  }
}
