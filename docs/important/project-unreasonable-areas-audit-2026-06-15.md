# 项目不合理点总审计

最后更新：2026-06-15

## 1. 这份文档的目的

这份文档只做一件事：把当前项目里仍然“不合理”的地方系统性收出来，避免后续继续靠零散测试、用户撞错、临时修补来推进。

这里的“不合理”包含但不限于：

1. 逻辑不合理。
2. 链路不合理。
3. 工具暴露与工具冲突不合理。
4. GUI 入口与用户心智不合理。
5. 状态恢复、上下文、产物落盘、项目类型暴露等架构不合理。

这不是任务顺序文档，也不是直接修复文档。它的职责是先把问题版图讲清楚，并给出优先级。

---

## 2. 总体判断

当前项目已经不是“没有能力”，而是进入了一个更难的阶段：能力块很多，但一些关键语义仍没有真正统一。

最核心的问题不是某一个 bug，而是以下几类“事实源分裂”：

1. 开局语义不是单一事实源。
2. 工具暴露语义不是单一事实源。
3. 长任务调度语义不是单一事实源。
4. 章节/样章/知识/研究/路径等产物语义不是单一事实源。
5. GUI 展示语义和核心运行语义并不总是同一套。

这正是为什么项目会反复出现下面这些现象：

1. 看起来功能接上了，但换一个入口就行为不同。
2. 普通项目、长任务、拆书、知识提取彼此有共享目标，却没完全共享合同。
3. 智能体“说自己调用了”“看起来该知道上下文”“理论上应该继续跑”，但实际链路却没按预期工作。
4. 某些问题修完后，类似问题会在另一条链路里复活。

如果要把项目做成真正可发布的软件，下一阶段最该收的是这些分裂点，而不是继续单独补更多症状。

---

## 3. 审计方法

本轮审计主要依据三类证据：

1. 近期真实验收中反复暴露的用户侧问题。
2. 现有分析文档与历史主线结论。
3. 当前代码中的结构性锚点。

本轮重点复核了以下入口或区域：

1. `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
2. `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
3. `apps/novel_agent_app/lib/features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart`
4. `packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart`
5. `packages/novel_agent_core/lib/src/workflow/long_task_entry_prompt_builder_service.dart`
6. `packages/novel_agent_core/lib/src/workflow/long_task_opening_prompt_builder_service.dart`
7. `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`
8. `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
9. `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart`

另外，本轮也直接参考了已有文档脉络：

1. [high-fidelity-viewmodel-validation-analysis-2026-06-10.md](/d:/FlutterProjects/NovelAgentFlutter/docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md)
2. [opening-default-constraint-followup-2026-06-09.md](/d:/FlutterProjects/NovelAgentFlutter/docs/important/opening-default-constraint-followup-2026-06-09.md)
3. [full-module-sweep-module-audit-ledger-2026-06-09.md](/d:/FlutterProjects/NovelAgentFlutter/docs/full-module-sweep-module-audit-ledger-2026-06-09.md)

---

## 4. 最高层结论

如果只用一句话概括当前项目最不合理的地方，那就是：

**很多能力已经实现，但“谁才是这件事的唯一正式出口”还不够稳定。**

这会直接导致四种代价：

1. 用户入口看起来多，但语义不一致。
2. 智能体提示词、工具权限、运行时调度、GUI 引导彼此可能不完全同步。
3. 修一个点时容易只修到其中一条链，而不是修到“真正的中心”。
4. 验收成本极高，因为必须反复用不同入口交叉试。

---

## 5. 具体不合理点

## 5.1 P0: 开局语义仍然分裂，尚未真正形成唯一正式入口

### 现象

虽然最近已经把一部分长任务开局改成“智能体引导优先”，但开局相关语义仍然分散在多套机制里：

1. `OpeningNextActionResolver` 仍会给出 `opening.start_long_task_run` 这类结构化动作。
2. `WorkbenchConversationController` 仍直接处理 `guide.create_workflow_from_mode_guidance`、`opening.start_long_task_run` 等机械分支。
3. `LongTaskEntryPromptBuilderService` 仍保留偏直接控制式的话术与进入方式。
4. `InspirationWorkbenchController` 仍有自己的一套“收束完成后直接启动长任务”的路径。

### 为什么不合理

开局阶段理论上应该回答的是同一个问题：

“当前项目是否已经具备进入正式运行的条件，以及下一步该由谁来主导。”

但现在这个问题被拆成了：

1. opening 面板判断。
2. 模式引导判断。
3. 主会话控制器判断。
4. 灵感工作台判断。
5. 某些 prompt builder 自带的进入语义。

这意味着同一个项目，可能因为入口不同而走出不同的开局节奏，尤其容易重新出现：

1. 机械式引导。
2. 未收集完用户意图就写正文。
3. 长任务与普通项目的开局风格不一致。
4. 智能体主导与程序主导混用。

### 证据锚点

1. [opening_next_action_resolver.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/opening/opening_next_action_resolver.dart)
2. [workbench_conversation_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart)
3. [long_task_entry_prompt_builder_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/workflow/long_task_entry_prompt_builder_service.dart)
4. [long_task_opening_prompt_builder_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/workflow/long_task_opening_prompt_builder_service.dart)
5. [inspiration_workbench_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart)

### 风险级别

P0。它会持续制造“明明同样是开局，为什么这里能写、那里又变成点按钮启动”的认知错位。

---

## 5.2 P0: 工具暴露与工具约束由太多层共同决定，冲突风险仍然过高

### 现象

当前工具可见性和工具使用边界并不是由一层统一裁决，而是多个层共同影响：

1. `ToolStrategyService`
2. `ContinuousTaskToolExposureRuntimeResolverService`
3. 智能体组能力范围服务
4. delegation 能力判断
5. runtime 侧的二次过滤
6. prompt builder 对工具策略的文字引导

### 为什么不合理

这类设计短期看像“比较稳”，长期却很容易出问题，因为：

1. 一件事可能在 A 层放行、B 层提示、C 层再拦截。
2. 工具是否暴露，和工具是否“被暗示该用”，未必一致。
3. 某些工具不是立刻返回，而是耗时过程，GUI 显示语义和工具状态语义也需要同步，但目前不是一处统一裁决。
4. 这会持续制造你之前遇到的那类问题：工具看似存在，但时机不对、权限不对、提示词理解不对、后处理也不对。

这也是工具冲突类问题反复出现的土壤，比如：

1. `present_user_options` 抢走该进入正式产物的轮次。
2. `call_sub_agent` 在不该出现的组里仍被诱导使用。
3. 信息收集工具、知识库工具、长任务控制工具、普通对话工具之间职责边界不清。

### 证据锚点

1. [continuous_task_tool_exposure_runtime_resolver_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart)
2. [tool_strategy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/tools/tool_strategy_service.dart)
3. [tool_strategy_prompt_builder.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart)
4. [project_conversation_draft_runtime_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart)
5. [project_workflow_runtime_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart)

### 风险级别

P0。因为它不仅影响功能能不能用，还影响“为什么会这样用”，属于链路正确性问题。

---

## 5.3 P0: 单智能体 / 多智能体 / 审核智能体 / 子智能体的协作语义还没有完全统一

### 现象

最近已经补了“单智能体组不应鼓励 `call_sub_agent`”这一类问题，但它目前更像是在部分入口收口了，不是已经彻底全域统一。

尤其是在这些链路上，仍应保持警惕：

1. 正常会话运行时。
2. 长任务运行时。
3. 审核链。
4. reviewer dispatch。
5. 特殊工作流运行时。

### 为什么不合理

多智能体体系如果没有统一清楚“谁能调谁、何时该调、没有专职审核时谁兜底”，就会继续出现两类坏结果：

1. 明明只有一个智能体，也在试图拉起别的智能体。
2. 有审核职能却没有在合适阶段被调度。

这不是简单的功能缺失，而是协作合同没有完全闭环。

### 证据锚点

1. [agent_group_delegation_capability_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/agents/agent_group_delegation_capability_service.dart)
2. [agent_collaboration_brief_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/agents/agent_collaboration_brief_service.dart)
3. [project_conversation_draft_runtime_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart)
4. [project_workflow_runtime_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart)
5. [project_workflow_reviewer_dispatch_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/project_workflow_reviewer_dispatch_service.dart)

### 风险级别

P0。因为这会直接毁掉“多智能体分工”这条主设计线。

---

## 5.4 P0: 章节、样章、正文、规划产物、信息产物的边界仍未完全固化成单一合同

### 现象

用户已经明确撞到过多次相关问题：

1. 样章与正文混在一起。
2. 章节文件名有时变成 `chapter_x` 或只有章号，没有符合设计的标题化命名。
3. 曾经出现过“只有序号没有正文”“只有标题无内容”“正文没有稳定写入”的情况。
4. 不同功能块都在写章节相关产物，但命名和路径不一定完全由同一个总规则落出。

### 为什么不合理

对于写作软件而言，“正文是什么、样章是什么、规划产物是什么、信息产物是什么、它们该落到哪里”必须非常硬。

否则会持续出现：

1. 用户看目录时混乱。
2. 长任务恢复时不知道哪个是真正进度。
3. 智能体工具写入目标不稳定。
4. 审核、续写、拆书、知识提取彼此引用时语义错位。

### 结构性证据

当前与路径/产物相关的 path service / path policy 分布非常广，说明“路径真相”仍然偏分散，而不是集中式单一出口。仅这次检索就能看到大量相关服务：

1. `chapter_output_path_policy_service`
2. `draft_file_path_service`
3. `project_content_path_policy_service`
4. `project_narrative_artifact_path_policy_service`
5. `chapter_atomic_output_path_service`
6. `long_task_path_policy_service`
7. `long_task_planning_artifact_path_service`
8. `workflow_runtime_satisfied_output_path_service`
9. 以及一系列 storage / reference / continuity / organization / timeline 路径服务

### 证据锚点

1. [chapter_output_path_policy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/project/chapter_output_path_policy_service.dart)
2. [project_content_path_policy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart)
3. [project_narrative_artifact_path_policy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/project/project_narrative_artifact_path_policy_service.dart)
4. [chapter_atomic_output_path_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/workflow/chapter_atomic_output_path_service.dart)
5. [workflow_runtime_satisfied_output_path_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/workflow/workflow_runtime_satisfied_output_path_service.dart)

### 风险级别

P0。因为这是用户最容易直接看到的“不像一个完成品”的区域之一。

---

## 5.5 P1: 会话恢复、历史会话、显示投影、滚动定位的所有权仍然偏分散

### 现象

近期用户侧已经暴露过：

1. 重新加载项目后，历史会话看起来像没显示。
2. 重新进入会话后，滚动位置落在顶部而不是底部。
3. 是否显示历史会话、当前激活会话、开局引导态、普通会话态等投影容易互相影响。

### 为什么不合理

当前恢复链路不是没有，而是分散：

1. `AppShellController` 负责项目切换时触发恢复。
2. `WorkbenchConversationController.restoreProjectSessions(...)` 负责读回持久化会话。
3. `showSessionHistory` 是运行时状态的一部分。
4. sidebar 和 view data 又是另一层投影。

这类结构很容易导致“数据是有的，但用户看起来像没恢复”。

### 证据锚点

1. [app_shell_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_controller.dart)
2. [workbench_conversation_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart)
3. [conversation_session_state_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/conversation_session_state_service.dart)
4. [conversation_sidebar.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart)

### 风险级别

P1。它会严重影响“产品是不是可信”的体感。

---

## 5.6 P1: GUI 入口语义和真实用户心智仍有明显错位

### 现象

近期用户侧已经明确指出过多类 GUI 不合理点，包括但不限于：

1. 没有有效项目时仍生成一个没有目录的默认项目，而不是先进入创建项目界面。
2. 创建项目界面在竖屏/窄屏下布局过挤。
3. 物理返回键大多数时候直接退出，没有做合理回退或确认。
4. 主界面文案与真实功能不匹配，例如“工作”“正文”等词不自然。
5. 竖屏下某些入口重复出现。
6. 某些高级机制直接暴露在创建阶段，不符合普通用户心智。
7. 项目类型转换要求用户手输 id，这明显不是最终产品级交互。

### 为什么不合理

这些问题表面上像“UI 文案和布局小问题”，本质上是产品语义还没完全收口：

1. 什么是默认路径。
2. 什么是高级配置。
3. 什么应在主面板露出。
4. 什么应作为设置页、项目设置页或高级入口出现。

如果这个层级不收口，后面功能越多，主界面会越像调试壳，而不是产品。

### 风险级别

P1。它不一定马上破坏核心链路，但会明显拖累可发布性。

---

## 5.7 P1: 项目类型与存储载体的暴露策略还没有完全对齐设计

### 现象

项目里已经明确形成过一条设计原则：

1. 不是所有项目类型都应允许任意存储载体。
2. 有些类型可以在多种载体之间选。
3. 有些类型只能选择某一种。

但目前仍有不一致暴露，例如：

1. 知识库仍能选择 `md` 类型，而设计上应只暴露 `sqlite`。
2. 写作类项目与知识类项目在转换、可见内容、可编辑内容上仍未完全形成统一策略。
3. SQLite 项目与 md 项目各自该暴露哪些工具、哪些界面能力，也还存在进一步收口空间。

### 为什么不合理

项目类型不是一个表单字段，而是后续几乎全部链路的前置语义：

1. 工具暴露。
2. 路径规则。
3. 资源树展示。
4. 信息提取方式。
5. 转换与导入策略。

项目类型暴露不严，会让核心层不断收到“不该收到的自由度”。

### 风险级别

P1。它属于产品合同层问题，越晚收越容易牵一发动全身。

---

## 5.8 P1: 信息收集、用户确认、智能体自行补完之间仍缺少真正统一的边界

### 现象

用户已经明确指出一个关键问题：

1. 智能体会自己补主角性格、设定等，而不是先向用户确认。

但反过来，若把所有字段都硬性强制确认，也同样不合理，因为这会让流程失去灵活性。

### 为什么不合理

这说明当前系统还缺一个足够清楚的合同：

1. 哪些信息默认必须向用户收集。
2. 哪些信息可以由智能体提出选项再确认。
3. 哪些信息在用户明确授权时才允许智能体自行完善。
4. 哪些信息在普通项目、长任务、拆书、知识提取里处理方式不同。

如果这个边界不清，开局阶段就会始终摇摆在两种坏极端之间：

1. 智能体擅自补完，用户失去控制。
2. 程序硬表单化，流程失去灵活性。

### 风险级别

P1。它关系到项目“到底是智能协作，还是僵硬表单”的根本体验。

---

## 5.9 P1: 表达限制、风格限制、审核限制、去 AI 限制等“限制层”仍不够单一化

### 现象

已经暴露过多种相关症状：

1. 默认表达限制没有自动装载到项目。
2. 智能体口头上说调用了表达限制，但正文结果并不真的遵循。
3. 某些限制更像提示词补充，某些限制又像工具外部判断，边界并不稳定。
4. 用户已经明确指出：限制并不只有“去 AI”，必须是通用架构。

### 为什么不合理

限制层如果没有清楚的统一语义，就会出现：

1. 装载了，但没真正生效。
2. 生效了，但没有被记录。
3. 记录了，但正文链没有真正消费。
4. 某些限制依赖程序硬判断，某些限制依赖审核智能体，某些限制只是提示词文本。

这会让“限制”既不可靠，也不可解释。

### 风险级别

P1。它直接影响生成质量和用户信任。

---

## 5.10 P1: 长任务调度、监督者、watchdog、审核线程之间的职责仍未完全硬化

### 现象

从前几轮讨论和多次探针暴露的问题来看，项目对“连续性任务”的处理已经演化出多个重要概念：

1. supervisor / control plane
2. 调度层
3. 审核层
4. watchdog / task liveness
5. 恢复、暂停、继续、重试

但这些概念目前更像设计上已经非常接近成熟，代码上却仍存在残余分叉和历史负担。

### 为什么不合理

只要这里没有真正统一成职责清晰的模型，就会继续发生：

1. 某个任务线停了，但到底该谁负责发现和续接，不够明确。
2. 某条链上的失败是“审核失败、产物失败、工具失败、调度失败还是存活失败”，不够一眼可判。
3. 提取任务、长任务、普通目标模式虽然都属于连续过程，但调度语义仍没有完全共享。

### 风险级别

P1。因为这块决定了项目是不是能做真正无人值守的连续工作。

---

## 5.11 P2: 若干超大文件已经进入“隐藏双实现/隐藏语义漂移”的高风险区

### 现象

本轮直接量到的几个关键文件行数如下：

1. `app_shell_controller.dart`: 5076 行
2. `workbench_conversation_controller.dart`: 2303 行
3. `project_workflow_runtime_service.dart`: 5604 行

### 为什么不合理

这已经不是单纯“文件大一点”的问题，而是：

1. 很难维持单一职责。
2. 很难确保没有同义逻辑在不同分支各写一份。
3. 很难快速知道某个功能该改哪个正式出口。
4. 多会话并行开发时极易发生互相踩线。

这也是为什么很多问题到最后会变成：

1. 看起来已经修过。
2. 但另一条链其实还保留着旧语义。

### 风险级别

P2，但它会持续放大所有 P0/P1 问题的修复难度。

---

## 5.12 P2: 灵感工作台与主工作台的边界仍不够干净

### 现象

`InspirationWorkbenchController` 当前仍承担了部分长任务进入职责，并带有自己的一套状态文案和启动逻辑。

### 为什么不合理

灵感工作台如果继续拥有“独立于主会话开局语义之外的正式启动权”，那么它就不是一个辅助手段，而是第二个主入口。

这会带来两个问题：

1. 未来继续漂移。
2. 用户不清楚自己到底该在哪个面板完成哪个阶段。

### 风险级别

P2。它目前不是最急的技术风险，但会持续制造产品认知负担。

---

## 6. 问题之间的因果关系

当前这些不合理点并不是彼此孤立的，关系大致如下：

1. 开局语义分裂
   -> 导致 GUI 引导、灵感工作台、普通会话、长任务进入方式不一致。
2. 工具暴露分裂
   -> 导致信息收集、表达限制、子智能体调度、审核工具行为反复冲突。
3. 协作语义分裂
   -> 导致单智能体乱拉子智能体、多智能体审核不稳定。
4. 路径与产物语义分裂
   -> 导致样章/正文/章节命名/恢复链路问题反复出现。
5. 超大文件与控制器过重
   -> 放大前面所有问题，因为很难知道“真正应该改哪一层”。

换句话说，很多表面症状其实都在指向同一件事：

**系统里仍有若干关键语义没有完全收敛为唯一正式出口。**

---

## 7. 优先级收束建议

如果只按“先看最该处理什么”来排，建议顺序如下：

### P0 必须优先收

1. 开局语义唯一化。
2. 工具暴露与工具约束唯一化。
3. 单/多智能体协作与审核调度唯一化。
4. 正文/样章/章节/规划产物路径合同唯一化。

### P1 紧随其后

1. 会话恢复与显示投影统一。
2. 信息收集与用户确认边界统一。
3. 限制层统一。
4. 项目类型与存储载体暴露统一。
5. 长任务调度 / watchdog / supervisor / 审核职责统一。

### P2 持续收口

1. 控制器拆责与运行时拆责。
2. 灵感工作台与主工作台边界清理。
3. 文案、布局、重复入口、项目创建交互等产品层清扫。

---

## 8. 最终结论

当前项目最不合理的，不是“功能太少”，而是“若干核心语义已经做出来了，但还没完全收成单一真相”。

这也是为什么用户体感会反复出现下面这种落差：

1. 看上去模块很多。
2. 设计文档也很多。
3. 某条链甚至已经修过。
4. 但换一个入口、换一种项目、换一种任务模式，问题又会回来。

从架构角度看，下一阶段最值得做的事已经很明确：

**不是继续横向堆更多能力，而是把这些关键语义竖向收成唯一正式出口。**

只要这一步不完成，后续再加知识库、拆书、同人、长任务策略层、CLI、TUI、Docker，都会继续放大现有分裂。

相反，如果这一步收好了，后面的新增能力才会真正站在稳定地基上。
