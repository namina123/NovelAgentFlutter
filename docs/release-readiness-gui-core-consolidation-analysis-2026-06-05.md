# 发布收口 GUI 与核心层分析文档

日期：2026-06-05  
范围：当前已实现功能的实际性、稳定性、完整性、GUI 易用性、功能关联性、发布残留与核心层缺陷。CLI 已明确未完全实现，本轮只作为边界风险记录，不作为主要收口目标。

## 1. 本轮结论

当前项目已经具备“能跑通很多模块”的基础，但还没有达到“可以作为普通用户可实际发布软件”的状态。最大的差距不是单点功能缺失，而是产品层收口不足：

1. GUI 的默认路径还不够像“写小说软件”，更像“工程控制台”。用户第一次进入时，会看到打开项目、工作台、智能体生态、长任务、设置等入口，但缺少一个更自然的“新建作品 / 继续写作 / 查看运行”主路径。
2. 不少内部概念直接暴露给用户，例如工具策略、运行基准、Workflow ID、Activation / Delivery / Review / Continuity / Information、Agent ID / Mode ID / Stage ID、ProjectWorkspacePort 等。这些概念对工程排错有用，但不应作为普通用户默认体验。
3. 长任务稳定性已经有 supervisor、delivery state、recovery 等基础设施，但真实长链稳定性仍不能只靠组件测试证明。发布前必须用 GUI 路径和真实 provider 做短中长三档验收。
4. 视觉上存在发布级问题：现有 GUI 截图中中文渲染为方框，说明字体回退、截图环境或打包字体链路没有收口。主题也偏“工程样机”，缺少可发布软件的视觉层级和舒适度。
5. 信息层、开放叙事层、章节交付层的架构方向正确，但新近实现量很大，仍处于“合同与适配层刚接上”的状态，真实模型是否自然调用 information / narrative 工具还需要证明。
6. 多智能体底座已经存在，且子智能体上下文隔离、禁止递归委派、工具权限过滤等方向是对的；但目前多数探针仍是单智能体，不能证明一主多子在真实写作中能稳定分工、独立用模型、按需调用工具并把结果合并回主链。
7. “普通用户默认只选择智能体组；多技能组合、约束、提示资源、工具权限和项目规则逐步资产化”这条理念整体正确，但不能把“默认不打扰”误写成“用户无权配置”。用户进入专门的设置/生态入口后，应能通过 GUI 定义智能体组、技能组、智能体、技能、模型偏好和规则覆盖；这些配置一般不应出现在写作主面板里，内部运行时仍只消费合同对象。
8. 工作区仍有大量未提交改动和新文件。密钥扫描已通过，但发布前必须把探针、归档、真实 API 配置、参考项目与构建产物彻底分层。

本轮已执行验证：

- `flutter test` 于 `apps/novel_agent_app` 通过，结果为 278 项测试通过。
- `dart tools/repository_secret_scan.dart` 通过。
- 只读检查了 GUI 入口、项目创建、模型设置、工具策略、长任务总站、项目资产、拆书导入、主题与截图产物。
- 多智能体 focused tests 已通过：
  - `packages/novel_agent_core` 中 sub-agent、agent services、model override、model execution profile、tool exposure 等 26 项通过。
  - `apps/novel_agent_app` 中 workbench agent skill probe、会话 agent resolver、opening projection、tool entry、sidebar、project agent group view-data 等 29 项通过。

## 2. 我作为用户走一遍后的真实感受

### 2.1 第一次打开：不知道“下一步该点哪里”

导航入口是工程化分组：

- 项目：打开项目
- 工作：工作台、智能体生态
- 运行：长任务
- 系统：设置

对开发者这是清楚的，对小说作者却不够自然。一个普通用户想要的是：

1. 新建一本小说。
2. 继续写上次的小说。
3. 配置模型。
4. 查看正在跑的任务。
5. 导入旧书/拆书。

当前“新建项目”主要藏在工作台的项目启动浮层里，而左侧主导航只有“打开项目”。这会让新用户误以为软件必须先有项目才能用，或者找不到新建入口。

需要改哪里：

- GUI：`apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart`
- GUI：`apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_launcher_overlay.dart`
- ViewData：`ProjectLauncherViewDataService`

建议：

- 左侧主导航增加“新建作品”或在“打开项目”页面同时提供强主按钮。
- 首次进入默认展示“新建 / 打开 / 模型设置”的三步入口，而不是让用户先理解工作台。

### 2.2 设置模型：功能完整，但像 API 调试器

接口设置里用户需要理解：

- 接口/厂商名称
- 协议
- Base URL
- 模型 ID
- API Key

这是必要的，但缺少一条更安全、更像产品的默认路径：

1. 选择厂商。
2. 填 Key。
3. 选择模型。
4. 点“测试连接”。
5. 保存为默认。

当前没有明显的连接测试按钮；“协议”“Base URL”“模型 ID”直接摆出来，对新用户压力较大。

需要改哪里：

- GUI：`provider_detail_pane.dart`
- GUI：`model_settings_panel.dart`
- Application service：provider/model settings view-data service
- Adapters：可复用 provider ping / model list test service

建议：

- 默认模式只显示厂商、Key、模型、测试连接。
- Base URL、协议、自定义参数放进“高级设置”。
- API Key 明文开关需要二次确认或短时显示，避免误操作。

### 2.3 普通写作：入口已经接近可用，但仍缺“写作产品感”

工作台有输入区、模型选择、会话、文档预览和工具调用展示，这是正确方向。问题在于它仍像“智能体工作台”，而不是“小说创作台”。

用户最常见动作应是：

- 写下一章。
- 续写当前章。
- 修订当前章。
- 总结已写内容。
- 查看/调整设定、角色、伏笔。

当前这些能力分散在会话、项目资产、审稿、任务中心等多个模块中。用户需要先理解系统结构，才能知道该去哪儿。

需要改哪里：

- GUI：Workbench 空状态、会话输入区、文档工具条
- ViewData：conversation empty state / guide projection
- Core：普通项目与长任务共用的 writing action contract

建议：

- 普通项目打开后，首屏只给 3 个主动作：开始写第一章、续写下一章、整理设定。
- 工具调用默认折叠成“已保存正文 / 已更新设定 / 已请求确认”，而不是显示内部工具细节。

### 2.4 长任务总站：工程信息很强，用户信息太弱

长任务总站已经能展示：

- 总数、运行中、暂停、待处理
- 当前项目过滤
- 运行实例详情
- 阻塞信息、链路、最近结果
- 开放叙事摘要、信息投影、权限确认

但详情页仍暴露大量内部字段：

- Workflow ID
- Activation / Delivery / Review / Continuity / Information
- 活动任务路径
- 信息投影
- 权限确认
- 存储策略

这些对排查很好，但普通用户只想知道：

1. 现在写到哪里了？
2. 为什么停？
3. 我需要做什么？
4. 可以继续吗？
5. 最近产出了哪些章节？
6. 有哪些风险需要我确认？

需要改哪里：

- GUI：`long_task_run_detail_panel.dart`
- Application service：`long_task_station_view_data_service.dart`
- Adapters：`project_long_task_station_detail_service.dart`

建议：

- 默认视图改成“进度、当前动作、需要我处理、最近产物”四块。
- 内部合同项统一放进“诊断详情”折叠区。
- Activation / Delivery / Review / Continuity / Information 应显示为“本轮上下文 / 正文交付 / 审查结果 / 连续性记录 / 资料与设定”，并保留开发者原文在调试模式。

### 2.5 拆书导入：功能方向对，但还没有大型作品工作流

拆书页面目前可以导入源文稿、填写风格提要、世界规则、角色、组织，并生成结构化预览。这适合小样本或轻量导入。

但对 1000 章长篇，用户真正需要的是：

1. 创建拆书项目。
2. 导入目录或分批导入。
3. 选择后续用途：普通续写、长任务续写、资料沉淀、解说等。
4. 开始后台分析。
5. 看到拆解进度与可用资源。
6. 后续写作时自动激活已拆资源。

当前 GUI 还偏“一次性粘贴/导入文本文件”，没有把“大规模拆书后续工程菜单”做成发布级流程。

需要改哪里：

- GUI：`book_deconstruction_import_panel.dart`
- GUI：`book_deconstruction_preview_panel.dart`
- Application：book deconstruction view-data and persistence services
- Core：拆书结果到 information / narrative / continuity 的桥接合同

建议：

- 拆书项目创建时先选择后续用途，但允许后续修改。
- 拆书页面应显示“已分析章节数、已生成设定/角色/伏笔/资料数量、可用于哪些写作链”。
- 大文本导入应支持分卷/分章批处理，而不是只依赖一个源文稿文本框。

### 2.6 项目资产：能力有了，但概念仍偏内行

项目资产已经覆盖风格、表达限制、伏笔、时间线、关系、图谱。表达限制绑定也已经从手填 ID 改进为选择 agent / mode / stage，这是进步。

但仍有几个用户体验问题：

- “preset”这种词仍然出现。
- “Agent ID / Mode ID / Stage ID”虽然提示不再手填，但术语仍然会让普通用户紧张。
- 权重是裸数字，用户不清楚 100 是什么意思。
- 表达限制、执行约束、风格、技能、工具策略之间关系不清楚。

需要改哪里：

- GUI：`expression_constraint_binding_editor_panel.dart`
- ViewData：ProjectAssetsViewData and expression binding view-data
- Core：表达限制/执行约束公共命名与用户暴露策略

建议：

- 用户层用“写作规则 / 适用范围 / 强度”。
- 开发者层再显示 profile、binding、agent、mode、stage、weight。
- 权重改成“弱 / 标准 / 强 / 严格”，高级模式才显示数字。

## 3. 不合理开放给用户的内容

这些内容可以存在，但默认不应直接暴露给普通用户。

### 3.1 应默认隐藏到“高级/诊断”的内容

- `Workflow ID`
- `ProjectWorkspacePort`
- `Activation`
- `Delivery`
- `Review`
- `Continuity`
- `Information`
- `Agent ID`
- `Mode ID`
- `Stage ID`
- `runtime baseline`
- `storage strategy`
- `tool strategy`
- `API mode`
- `stream mode`
- `compatible context window`
- `app context window`
- 原始相对路径、任务路径、内部 JSON 字段

### 3.2 可保留但需要换成人话的内容

- 工具策略：改成“智能体权限与保存方式”。
- 运行基准：改成“长篇写作方式”。
- 存储策略：改成“保存方式”，默认 Markdown，SQLite 放高级。
- 信息投影：改成“资料摘要”或“设定摘要”。
- 权限确认：改成“需要你确认”。
- 开放叙事摘要：改成“故事连续性记录”。

### 3.3 不应在普通流程出现的内容

- 任何 probe / mock / real_probe 文案。
- 任何 `sk-`、`test_api.txt`、`local/probe_api.txt` 引导。
- 任何参考项目名称，尤其不能出现 MuMu 相关文字。
- 任何内部服务名、port 名、contract 名。

## 4. GUI 视觉与主题问题

### 4.1 中文字体渲染为方框是发布阻断

现有截图产物中出现中文方框，例如长任务运行截图、智能体生态导航截图。这说明至少在测试/截图环境中字体不可用。

这不是简单美观问题，而是发布阻断，因为：

1. 自动化截图无法真实验证中文 UI。
2. 如果某些用户机器也缺字体，会直接不可用。
3. 视觉回归测试在字体缺失时没有意义。

需要改哪里：

- Flutter app `pubspec.yaml` 字体资源配置
- Theme/TextTheme 默认字体族
- 视觉回归测试环境
- Windows/Android 打包字体策略

建议：

- 内置一套可商用中文字体或明确随包字体策略。
- 测试截图必须使用同一字体。
- CI/本机截图若出现 tofu 方框，应让测试失败或至少输出警告。

### 4.2 当前主题偏工程样机

当前内置主题只有明亮/偏暗两套。浅色主题以米色背景、青色线条、暖色强调为主，整体容易显得旧、脏、层级弱。深色主题也偏工程控制台。

需要改哪里：

- `theme_registry.dart`
- `theme_resolver.dart`
- panel/button/input/list tile token sets

建议：

- 发布默认主题应更安静、清爽、对比清晰。
- 减少大面积米色和青色边框。
- 文件树、会话、文档阅读区应形成明确主次，不要所有面板边框都同等响。
- 长文本阅读区优先保证中文阅读舒适度，而不是控制台感。

## 5. 核心层缺陷与发布风险

### 5.1 长任务稳定性：基础设施有了，但真实链路仍需证明

已有积极进展：

- `ChapterDeliveryStateMachine` 已经把缺正文、路径漂移、修复需求、人工处理等状态结构化。
- `LongTaskRecoveryService` 已经能根据 delivery/information 状态产生恢复计划。
- adapters 中已有 `LongTaskSupervisor` 与 station detail 服务。

风险仍在：

1. 真实长任务曾多次出现只读轮、正文未落盘、章节停止、字数/表达限制失效等问题。
2. 当前 GUI 测试通过不能证明真实 provider、工具调用、后台调度在 50/100/200 章链路中稳定。
3. 用户需要的是“任务停了以后能解释、能重试、能继续”，不是只在报告里能看见失败。

需要改哪里：

- Core：chapter delivery state / task stop policy / supervisor risk policy
- Adapters：project workflow runtime service、long task supervisor、tool dispatcher
- GUI：long task station default view and recovery action surface

发布前验收要求：

- 普通长任务 10 章真实 GUI 路径通过。
- 中等长任务 30-50 章至少一次 checkpoint/recovery 通过。
- 压力长任务不硬编码题材，只验证“章节交付、恢复、连续性、信息激活”。

### 5.2 普通项目与长任务仍有链路割裂风险

很多逻辑本应所有写作任务共用：

- 字数目标与偏差策略
- 表达限制
- 去 AI 表达约束
- 章节交付状态
- 资料/设定/设计元素激活
- 工具调用证据
- 审稿与修复

当前部分能力已经向共享层迁移，但 GUI 和 adapters 里仍能看到普通会话、长任务、拆书后续各自接线的痕迹。发布前要避免一种情况：长任务能用，普通项目不能用；拆书能生成资料，但续写不激活。

需要改哪里：

- Core：共享 writing execution contract
- Adapters：conversation draft runtime、workflow review runtime、context activation
- GUI：普通写作、长任务、拆书入口都消费同一批用户可理解状态

### 5.3 信息层方向正确，但真实命中率未证明

近期的信息层实现方向是对的：

- `knowledge/`、`research/`、`references/` 应作为用户可读投影，不是事实源。
- 结构化 source of truth 应位于 `.novel_agent/information/...`。
- 长期知识、设计、研究、引用边界应走 `propose_knowledge_card`、`propose_design_element`、`submit_research_note`、`propose_reference_work` 等领域工具。

仍需证明：

1. 真实模型是否会自然调用这些工具，而不是只写在正文或普通 Markdown。
2. 普通项目、长任务、拆书导入是否都会激活同一套 information 资料。
3. 投影 Markdown 是否只用于用户阅读，不会被重复注入导致上下文污染。

需要改哪里：

- Core：information tool prompt / permission / lifecycle
- Adapters：information repositories、projection writer、activation bridge
- GUI：资料/设定摘要的可视化与确认入口

发布前验收要求：

- 普通项目真实一章能至少产生一个稳定设定或设计元素。
- 长任务真实短链能复用该设定。
- 拆书导入能把可复用信息沉淀到同一套 information 合同。

### 5.4 仍有少量题材词进入生产风险策略

代码中已经没有把快穿/死亡回归作为核心模式直接铺开，这是正确方向。但 production code 中仍能看到如 `transmigration` 一类词用于 high-risk reference relationship 判断。

这不一定是错误，因为它可能只是开放 relationship 字段中的一个风险关键词；但它需要被重新审视：

- 如果是兼容旧数据或外部输入的风险词，可以保留在可配置/可扩展的风险词表。
- 如果它变成程序判断题材的入口，就违背了“不写死小说流派”的基线。

需要改哪里：

- Core：`narrative_supervisor_risk_policy_service.dart`
- Core：`information_permission_policy_service.dart`

建议：

- 将 fanfic、crossover、source_work、transmigration 等风险关系改为 registry/config 驱动。
- 核心只判断“引用风险/衍生风险/版权风险/外部作品风险”，不判断题材。

### 5.5 大文件仍是维护风险

当前 GUI controller 和 runtime service 仍然偏大：

- `AppShellController` 约 4490 行。
- `ProjectWorkflowRuntimeService` 约 2617 行。

这不是立刻阻断发布的 bug，但它会影响收口效率。越到发布前，越需要快速定位问题；大文件会让回归修复容易互相牵连。

建议：

- 发布前不做大重构，但新增修复不要继续塞进这两个文件。
- 新增 GUI 收口逻辑放到 view-data service、projection service、action outcome service。
- 新增长任务逻辑放到 core state/policy/service，再由 adapters 薄接线。

### 5.6 多智能体协作：底座是对的，但还没有证明真实分工

用户目标不是“列表里能看到多个智能体”，而是一个稳定的一主多子协作系统：

1. 主智能体负责理解用户目标、选择阶段、决定是否委派，并最终合并结果。
2. 子智能体拥有独立上下文，不继承主智能体完整会话，只通过项目资料、主智能体生成的任务摘录、约束和期望产物理解当前进程。
3. 子智能体可以拥有与主智能体相同或不同的工具策略，也可以拥有不同模型设置。例如写作模型负责正文，审核模型负责风险与修订建议。
4. 子智能体不能直接变成另一个主智能体，不能递归委派，也不能绕过主智能体向用户提问。
5. 多智能体不应绑定任何题材、流派或测试样例；“写作专家、审稿专家、连续性专家、资料检索员”等只是可配置协作角色，不是核心代码写死的小说类型。

已有积极基础：

- `SubAgentRunPackageService` 已明确 `include_full_main_conversation: false`、`include_parent_messages: false`，方向符合上下文隔离。
- `SubAgentMessageBuilderService` 的子智能体提示词已经强调不能假装拥有完整主历史，只能基于任务、摘录、结构、路径和工具读取资料。
- `SubAgentRunPackageService` 默认阻断 `call_sub_agent` 与 `present_user_options`，避免子智能体递归委派或直接问用户。
- `ToolExposurePolicyService` 对 sub-agent 隐藏 `start_long_task_run`，避免子智能体直接启动长任务。
- `BuiltinCollaboratorCatalogService` 已有可选主编室/审稿室，以及主编、作者、剧情、设定、读者、文风、资料、工作流等协作视角。
- `ToolExecutionService` 已能接管 `call_sub_agent`，并把结果作为工具事件返回给主智能体。
- GUI 已有项目智能体组选择、会话智能体选择、子智能体运行详情和隐藏原始 `call_sub_agent` timeline 的用户投影。

但这些还不能证明多智能体可发布。当前主要断点是：

1. **子智能体独立模型设置未被证明真实生效。** `ModelExecutionProfileService` 支持按 agent 文档应用模型覆盖，但 `SubAgentExecutionService.execute()` 当前接收的是父链传入的单个 `modelId`，未看到它在子回合里重新按 child agent 解析 provider/model/temperature/top_p/advanced overrides。结果可能是所有子智能体实际使用同一个模型。
2. **GUI 会话请求解析可能丢失完整 agent 运行资料。** `ConversationRequestAgentResolverService` 目前把选中的 member 投影成 id/name/role/description/thinking_supported 摘要；这能证明“选中了谁”，但不足以证明 provider/model/高级参数/工具策略随选中 agent 进入执行链。
3. **子智能体工具策略目前更像默认策略过滤。** `SubAgentExecutionService` 使用 `ToolStrategyService.defaultSettings()`，再用 blocked tools 和 exposure policy 过滤。它还不是“按子智能体/项目/阶段解析出的工具策略合同”。如果以后某个审核智能体只能读不能写，某个作者智能体可写正文，这里需要明确合同，而不是散落在 prompt 或默认策略里。
4. **协作组选择与生成链仍可能错位。** `GenerateDraftUseCase` 当前用 `optionalGroups.first` 生成 collaboration brief，这不一定等于 GUI 当前选择的项目组。对普通用户而言，界面上选了某个专家组，就必须是本轮实际协作组。
5. **普通正式章节路径主动屏蔽 `call_sub_agent` 是合理但需要说明边界。** `ProjectConversationDraftRuntimeService` 对正式章节/修订屏蔽 `call_sub_agent`，这是为了防止“只委派不交付”再次破坏章节落盘；但它也意味着普通章节交付路径不能顺便证明多智能体。应另设“协作预审/协作修订/多专家会商”这类不会抢正文交付权的入口，或由主智能体先委派、后强制完成正式交付。
6. **缺少真实多专家端到端验收。** 现有测试能证明 agent 选择、skill scope、sub-agent tool context、GUI 投影等局部合同，但还没有证明主智能体会在合适时机调用多个子智能体，子智能体不会拿到完整主会话，结果会被主智能体合并，最终仍形成章节交付。
7. **子智能体失败后的主链恢复策略还不够产品化。** 子智能体超时、空返回、工具错误、只读轮等情况，应作为主链的可恢复协作事件，而不是直接把整个章节或长任务拖死。

需要改哪里：

- Core：新增或补齐 child run runtime contract，至少包含 child agent profile、effective model profile、tool policy、context policy、result contract、failure policy。
- Core：`SubAgentExecutionService` 不应只接收父链 `modelId`；应能根据 child agent 和项目绑定解析有效模型，或接收已解析好的 child execution profile。
- Core：`SubAgentRunPackageService` 保持只组包，不引入 provider/UI/adapters 依赖；模型解析应在运行配置层或执行层完成。
- Core：工具策略需要从 default settings 演进为“主智能体策略 / 子智能体策略 / 项目阶段策略”的可组合视图。
- Adapters：项目当前选择的 agent group 应作为生成运行时的显式输入，而不是让 use case 自己拿 optional group 第一个。
- GUI/ViewData：opening projection 或 resolver 需要保留完整 agent profile 的稳定引用，或保留足够的 runtime profile 解析材料，不能只传显示摘要。
- GUI：多智能体能力默认应以“协作组/审稿室/资料检索”这类用户可理解概念呈现，内部 agent_id、tool id、sub_session_id 放到诊断详情。
- Tests/Probe：增加 mock LLM 多智能体脚本，模拟主智能体调用资料检索、连续性审查、文风审稿至少两个子智能体，并验证最终主智能体仍完成正式章节交付。

发布前验收要求：

- mock 层证明主智能体能在一轮请求内调用不同子智能体，且每个子智能体消息不包含完整主会话。
- mock 层证明 child-specific model/tool policy 生效，例如 reviewer 与 writer 使用不同模型参数或不同工具权限。
- GUI 层证明用户选择某个多智能体组后，本轮生成实际使用该组，而不是 fallback 到第一个可选组。
- 真实 provider 短探针证明：普通项目或协作审稿场景中，至少一次子智能体调用成功返回，主智能体能合并结果，最终产物可从 GUI 打开。
- 长任务短探针证明：多智能体协作失败不会让 supervisor 失去恢复能力。

### 5.7 多项目参考后的多智能体设计更新

本轮重新查阅了既有吸收文档与 `references/` 下的代表项目。这里继续遵守边界：只吸收产品事实、架构思想、能力拆分和验证经验，不复制代码，不把参考项目的许可证风险、页面形态或题材词带进核心。

已复用的旧分析基准：

- `docs/absorption/10-projects/book-os/README.md`
- `docs/absorption/10-projects/ai-novel/README.md`
- `docs/absorption/10-projects/writingway/README.md`
- `docs/absorption/10-projects/aixiezuo/README.md`
- `docs/absorption/10-projects/novel-writer/README.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/agent-group-opening-redesign-session-order.md`

#### 5.7.1 book-os：子智能体不是名字，而是上下文操作系统的一部分

可吸收点：

- 它把 `command / instruction / agent` 分层，说明用户入口、工作流规则、专家角色不应混在一个巨型 prompt 或 controller 里。
- 它的 `context-researcher`、`continuity-checker`、`prose-reviewer`、`writing-workflow` 等子角色都有明确职责边界：有的只检索，有的只检查，有的只管版本/备份。
- 它强调条件加载、lite 文档和“已在上下文中则跳过”，这对多智能体尤其重要，因为每个子智能体都不该重复拿一整包上下文。
- 它允许自定义 subagent，这说明我们的内置专家组也应只是默认资产，不能成为唯一协作结构。

对 NovelAgent 的更新结论：

- 多智能体运行合同应分成 `入口意图 -> 协作计划 -> 子任务包 -> 子回合执行 -> 结果合并 -> 交付/恢复`。
- 子智能体的上下文包应支持 `required / relevant / lite / source_paths / already_in_context` 这类标记，避免每个子智能体都读完整项目。
- 内置子智能体应成为可替换的 `agent profile + skill loadout + tool policy + model policy` 组合，而不是写死在某个 use case。
- `context_researcher` 类角色应优先作为“资料选择器”，帮助主智能体构造干净上下文，而不是让主智能体盲读文件。

#### 5.7.2 novel-writer：写作动作应是执行包，不是一句提示词

可吸收点：

- 它把 `/constitution / specify / clarify / plan / tasks / write / analyze` 做成分层方法论。
- 它的 write 命令会在执行前查询 constitution、spec、plan、tasks、tracking、knowledge、前文、风格和反 AI 规范。
- 它的专家目录更像“策略包”，不一定非要变成实时多会话专家，但适合成为可加载的协作能力。

对 NovelAgent 的更新结论：

- 多智能体不应从“模型自己想不想 call_sub_agent”开始，而应先由主链构造本轮 `WritingExecutionPackage`：目标、阶段、交付类型、上下文来源、约束、可委派专家、失败策略。
- 主智能体决定委派时，传给子智能体的是执行包的切片，而不是主会话全文。
- 子智能体结果必须回到执行包的 `collaboration_results`，再由主智能体决定是否进入正式章节交付、修订建议或恢复计划。
- constitution、表达限制、字数策略、continuity、information、前文窗口都应属于执行包输入，不应分别由普通项目/长任务/拆书各自拼接。

#### 5.7.3 Ai-Novel：任务运行、Prompt block、模型预设和多层记忆要接入协作链

可吸收点：

- 它把任务运行当成正式子系统：任务实体、事件流、heartbeat、watchdog、reconcile、重试和任务中心。
- 它把 prompt 做成 preset + block + budget + trigger，而不是一段拼接字符串。
- 它把记忆分成 worldbook、story memory、structured memory、graph context、fractal memory、RAG 等层级。
- 它支持任务级模型预设，说明不同任务/专家使用不同模型是自然需求。

对 NovelAgent 的更新结论：

- 子智能体执行必须进入同一套 task event / run record / recovery 视图；不能只是主回合里一个黑盒工具结果。
- 协作专家的提示词应逐步资源化为 `prompt blocks`，并带任务触发、预算优先级和用户/项目覆盖能力。
- child-specific model policy 是 P1 里很靠前的任务：writer/reviewer/researcher/continuity 不应只能共享父模型。
- 记忆层要按资料类型和优先级进入子任务包：审稿专家更需要前文/风格/表达限制，连续性专家更需要 entity/relation/timeline，资料专家更需要 source/research/knowledge。
- 子智能体产出不应只返回文本；它可以返回结构化建议、风险、引用路径、资产派生建议，但正式写入仍应走主链或受控工具。

#### 5.7.4 Writingway：多智能体也需要用户可控的上下文选择

可吸收点：

- 它的 Workshop 是带项目上下文的协作室，不是裸聊天。
- 它的 ContextPanel/Compendium 允许用户选择哪些项目内容进入当前会话。
- 它把项目树做成创作结构树，而不是物理文件树。
- 它把 summary 做成层级资产，既给用户看，也服务上下文压缩。

对 NovelAgent 的更新结论：

- GUI 多智能体入口不能只显示“用了哪些专家”，还应让用户看懂“本轮协作参考了哪些资料”。
- 多智能体运行前后应提供轻量上下文摘要：已注入前文、已使用设定、已参考角色/伏笔/资料，而不是展示内部 JSON。
- 子智能体结果详情页应按“专家意见 / 证据路径 / 影响范围 / 主链采纳情况”组织，而不是原始 tool timeline。
- 物理文件树和创作结构树应继续分离；子智能体的 `source_paths` 应优先引用创作结构节点背后的稳定路径。

#### 5.7.5 AIxiezuo：正文、状态、设定、模板、记忆、版本必须分开

可吸收点：

- 它虽早期，但明确把正文文件、章节状态、世界设定、模板、会话记忆、多版本草稿分开。
- 它意识到前文正文参与生成很重要，状态摘要不能替代真实前文。
- 它把状态更新和正文生成拆成两条链，正文完成后再派生状态。

对 NovelAgent 的更新结论：

- 多智能体子任务不能把“章节正文交付”和“状态/资产更新”混成一个职责。作者子智能体可以产出正文片段，审稿/连续性子智能体产出建议或状态 delta，最终正式交付由主链统一收口。
- 子智能体上下文包必须能同时包含“前文窗口”和“结构化状态”，二者不是互相替代关系。
- 多版本/备份与协作链绑定：多专家修订前应有检查点，重要覆盖前必须能解释回滚点。

#### 5.7.6 MuMuAINovel：产品闭环是“分析 -> 建议 -> 执行 -> 回看”

可吸收点：

- 它把伏笔、角色/组织、章节关系、写作风格、拆书导入等对象做成独立管理中心。
- 它强调分析结果能继续驱动重写和后续创作。
- 它的拆书不是静态报告，而是能进入后续写作工程的资源基座。

对 NovelAgent 的更新结论：

- 多智能体协作的结果应该能进入“可回看、可采纳、可转任务”的结构，而不是一次性聊天文本。
- 审稿专家、连续性专家、资料专家输出的建议应能变成修订任务、资产更新建议或用户确认项。
- 拆书/导入后的智能体组不应先让用户理解所有专家，而应由后续路线和分析规格决定默认协作组；高级用户再调整。

#### 5.7.7 cc-switch：模型槽位、主/子 Agent、工具权限和回退策略要产品化

可吸收点：

- 它把主 Agent、子 Agent、类别执行器、模型配置、推荐模型、回退模型、工具权限 profile 放到配置层，而不是散落在调用点。
- 它有主编排器、任务管理者、只读顾问、资料检索、快速执行器等角色语义，说明“谁能委派、谁只能读、谁负责执行”应是策略配置。
- 它对 provider/proxy/tool-use 的健壮性修复提醒我们：多模型、多工具、多回合下，消息分类、tool_result 清理、回退与重试会直接影响成本和稳定性。

对 NovelAgent 的更新结论：

- 子智能体模型策略不只是 `modelId`，应支持 `primary model / fallback model / timeout / context budget / output budget / tool profile`。
- 工具权限应从“默认工具开关 + blocked list”升级为命名 profile，例如 `read_only_review`、`chapter_writer`、`research_only`、`asset_update_suggest`、`workflow_keeper`。
- 主/子 Agent 的权限边界必须进入合同：谁能委派、谁能写正文、谁能提交正式章节、谁能请求用户确认、谁只能返回建议。
- 失败恢复要考虑成本：子智能体空返回或工具格式错误应优先局部重试/降级，而不是重跑整章或整条长任务。

### 5.8 参考项目综合后的目标形态

综合这些项目，NovelAgent 的多智能体最终不应是“多个聊天机器人一起说话”，而应是：

1. **用户默认选组，显式配置组。** 默认路径只选择协作组；单智能体是单成员组；高级 GUI 可编辑组成员、主智能体、技能绑定和模型偏好；组内谁能做什么最终由合同解析。
2. **主链持有目标与交付权。** 主智能体可以委派，但正式章节交付、用户确认、长任务恢复、项目状态更新都由主链或受控工具收口。
3. **子链只拿必要上下文。** 子智能体通过任务包、摘录、source_paths、lite 资产、工具读取项目资料来工作，不继承完整主会话。
4. **专家是可配置资产。** agent profile、skill binding、skill loadout、prompt blocks、tool profile、model policy、applicability scope 都应可组合、可覆盖、可项目快照、可导入导出。
5. **协作结果结构化。** 子智能体输出至少应包含 summary、evidence、risk、suggestion、adoption_hint；需要写入资产时产出 delta/plan，而不是暗中修改。
6. **模型路由按任务。** 写作、审稿、连续性、资料检索、工作流守护可以用不同模型、不同预算、不同回退策略。
7. **上下文按层级和预算。** global/project/manuscript/task、full/lite、recent/full/summary、information/continuity/expression constraints 都要经同一上下文预算层。
8. **运行可观测可恢复。** 子任务事件进入任务记录；失败有局部重试、降级、跳过、人工确认和恢复计划。
9. **GUI 展示协作而非调试。** 默认展示“协作组、参考资料、专家结论、采纳情况、下一步动作”，内部 id、tool call、raw JSON 放诊断详情。
10. **不写死题材或流派。** 多世界、回档、穿书、同人、现实资料、神话符号等都应通过 information/continuity/constraint/toolcall 配置表达，不进入核心硬分支。

需要警惕的是：参考项目的一些能力看起来像功能清单，但我们不能因此把题材、流派、世界转换、死亡回归、快穿等写死进核心。我们的核心应该吸收“后台任务表、章节上下文服务、记忆/伏笔/角色/组织分层、拆书导入流程、Prompt block、工具权限 profile、任务级模型路由”这些通用结构；具体小说手法应交给用户提示、项目资料、智能体工具和可配置规则处理。

### 5.9 反向审稿：多智能体、技能与约束设计的缺口修正

从我们的项目理念出发，“普通用户默认只选择协作组，系统内部组合多技能、多约束、多工具权限、多模型策略”这条主线是值得保留的。它能避免把作者变成系统工程师，也能让单智能体自然退化为单成员协作组。但这不能被误读成“用户无权配置内部组合”。用户应该能在专门的设置/生态 GUI 入口中定义智能体组、技能组、智能体、技能绑定和规则覆盖，只是这些能力不应压到第一次写作的默认路径或写作主面板上。

这条路如果缺少边界，会很快滑向两种相反的复杂：一种是把技能包、tool profile、prompt block、execution constraint 全塞给普通用户，软件变成工程控制台；另一种是系统黑箱替用户决定所有智能体和技能，用户无法塑造自己的写作团队。两种都不适合真正的创作软件。

因此需要把当前理念补成一套明确协议。

#### 5.9.1 应保留的基线

1. **用户默认选组，而不是默认选内部零件。** 普通用户默认面对“协作组/审稿室/资料助手/写作规则”，不在首屏直接面对 skill loadout、tool profile、prompt block、execution constraint。
2. **单智能体是单成员组。** 这样普通项目、长任务、拆书续写、多智能体协作能共用同一入口和运行合同，不需要两套项目心智。
3. **技能、约束、提示块、工具权限、模型策略都是可组合资产。** 它们服务协作组和运行包；默认由模板解析，高级 GUI 允许用户显式编辑。
4. **主链持有目标、状态和正式交付权。** 子智能体可以建议、审稿、检索、生成片段或提交 delta，但正式章节、长期规则和项目状态更新必须由主链或受控工具收口。
5. **普通项目、长任务、拆书不是三套孤岛。** 字数策略、表达限制、information、continuity、开放叙事状态、资料激活、多智能体协作都应优先做成公共写作能力，再由不同项目类型给出默认路线。
6. **不按题材写核心分支。** 快穿、死亡回归、多世界、穿书、同人、角色突变、环境迁移都只是测试和使用场景；核心只提供叙事状态、资料、约束、提案、上下文预算和工具合同。

#### 5.9.2 暴露协议

需要把“谁能看见什么”写成产品协议，否则内部资产化会继续泄漏到 GUI。

| 层级 | 可见内容 | 不应默认可见 | 典型操作 |
| --- | --- | --- | --- |
| 普通用户 | 协作组、写作规则、目标字数、参考资料、专家结论、采纳情况、需要确认 | agent id、tool profile id、prompt block id、execution constraint、raw JSON、workflow id | 选择协作组、调整规则强度、确认高风险修改、查看结果 |
| 高级用户 | 自定义表达限制、项目规则、智能体组成员、智能体技能绑定、协作包、默认组、模型偏好、项目级覆盖 | 内部事件格式、底层 port、provider 私有字段 | 新增/编辑/删除非内置规则，复制内置规则，配置智能体与协作组 |
| 开发/诊断用户 | 原始事件、prompt block 来源、tool profile、合同对象、预算命中、失败记录 | 不适用 | 排错、回归测试、定位链路断点 |
| 内部运行时 | `ExecutionPackage`、`ChildRunPackage`、`CollaborationResultPackage`、context/constraint/tool/model 子合同 | UI 文案和用户心智术语 | 解析、执行、审计、恢复 |

这个协议带来的修正是：普通用户可以“新增写作规则/表达限制”，但不应被迫理解“执行约束层”；高级用户可以管理可见规则、智能体、技能绑定和协作包，但内部兜底策略仍由系统维护；诊断信息存在，但必须折叠在开发视图或日志中。

#### 5.9.2.1 GUI 配置权的修正设计

这里此前最不合理的地方，是把“普通用户默认不看内部零件”和“用户不能显式配置零件”混在了一起。真正合理的设计应分成三层：

1. **快速使用层。** 创建项目或开始写作时，用户只选“单人写作 / 主编室 / 审稿室 / 资料助手 / 自定义协作组”等可理解入口。系统展示能力摘要，例如“会先做连续性检查，再生成正文，再给出审稿建议”。主面板只保留当前协作组摘要和进入设置的入口，不在写作流程中展开技能树。
2. **生态设置层。** 用户从设置或智能体生态入口进入“智能体组 / 技能组 / 智能体 / 技能 / 权限 / 规则”管理页。当前 GUI 已有类似能力，但还不够好用，后续重点不是把它搬进主面板，而是把这个入口做清楚、可搜索、可复制、可回滚。
3. **组编辑层。** 用户进入“编辑协作组”后，可以增删组内智能体，设置谁是主智能体、谁是审稿/资料/连续性/文风/作者视角，设置是否默认参与、触发阶段、最大轮次、失败时是否跳过。
4. **智能体编辑层。** 用户进入某个智能体后，可以配置技能组、技能绑定、模型偏好、上下文范围、规则覆盖和可见描述。技能绑定应以“能力卡/方法卡”的方式展示，例如“连续性检查”“资料检索”“文风审稿”“章节起草”，而不是默认展示原始 SKILL.md 文件。

这套设计里，用户确实有权定义“每个智能体用哪些技能、某个组有哪些智能体”。但必须附加几条边界：

- 技能只代表方法和上下文加载能力，不授予写入、联网、正式交付、用户确认等权限。
- 技能组是技能绑定的可复用组合，适合挂到智能体或智能体组上；它不等同于智能体组，也不等同于权限组。
- 工具权限单独由 tool profile 或权限开关控制，可以用“只读 / 可写草稿 / 可提交章节 / 可建议更新资料 / 可联网检索”等人话展示。
- 内置智能体和内置技能可以被复制后修改，不建议直接原地改坏；项目应保存快照，避免应用级资产升级影响旧项目复现。
- 普通用户可以停留在快速使用层；高级用户主动进入编辑层；诊断用户再看原始 id、prompt block、合同对象。
- 智能体组模板应能校验配置错误，例如没有主智能体、多个主智能体、审稿智能体拥有正式交付权、技能要求的能力与工具权限不匹配。

#### 5.9.2.2 推荐的数据形态

GUI 不应该直接编辑运行时大 JSON，而应编辑几类稳定资产：

- `AgentProfile`：名称、角色、说明、默认模型策略、默认上下文策略、默认技能绑定。
- `SkillBinding`：技能 id、版本、启用状态、适用阶段、触发条件、强度/预算、项目覆盖参数。
- `SkillGroupProfile`：技能绑定组合、适用智能体角色、默认触发阶段、预算策略、能力需求摘要。
- `AgentGroupProfile`：组名称、主智能体、成员列表、成员角色、默认参与阶段、协作顺序或并发策略、失败策略。
- `PermissionProfile`：工具能力边界，例如 read-only、draft-writer、chapter-deliverer、research-only、asset-proposal。
- `RuleBinding`：表达限制、字数策略、项目规则、资料引用策略等用户可理解规则。

运行时再把这些资产解析成 `ExecutionPackage / ChildRunPackage / CollaborationResultPackage`，GUI 不直接拼 prompt，不直接拼工具策略，也不直接理解 provider 私有字段。

#### 5.9.2.3 内置/非内置资产与 AI 生成草案

资产来源不应拆得过细。对产品和权限策略而言，只需要区分两类：

1. **内置资产。** 应用自带并由项目维护的基础智能体、技能组、技能和协作组。
2. **非内置资产。** 用户产生、导入或基于内置资产复制改造的资产。

这样划分足够表达权限和生命周期差异，也不会把用户带进一串不必要的来源分类里。具体来路最多作为备注或审计信息保存，不应成为用户理解系统的一层主结构。

这里必须特别谨慎：AI 生成技能属于非内置资产，不能直接变成已信任资产。它应先进入草稿/提案状态，经过结构校验、能力需求检查、权限风险说明、版本与来源记录后，再由用户确认启用。否则“让 AI 生成一个技能”会绕过整个权限系统，成为新的隐式高风险入口。

建议的资产生命周期是：

```text
新增/生成 -> 草稿 -> 校验 -> 风险说明 -> 用户确认 -> 安装到应用级或复制到项目级 -> 运行时解析 -> 使用记录 -> 更新/回滚/删除
```

关键规则：

- 非内置技能默认不获得联网、写入、正式交付、外部命令等高风险权限。
- 技能包必须声明能力需求、适用范围、版本、来源和摘要；不能只是一段长 prompt。
- 技能生成智能体只能提交 `SkillPackageProposal`，不能直接修改正式技能库。
- 项目使用某个技能后，应保存项目快照或版本锁定；应用级技能升级不应悄悄改变旧项目行为。
- 删除应用级技能时，已经复制进项目的快照仍保留；用户另有“清理所有项目引用”的高级工具，但必须可预览影响范围。
- 主面板只展示“当前启用了哪些能力摘要”和“为什么本轮使用了它们”，不展示完整技能文件。

#### 5.9.3 权责边界

需要把几个容易混淆的概念拆开：

- **Agent group**：用户可选择和可编辑的协作路线，描述“这轮谁一起工作、谁主导、默认怎么协作”。
- **Agent profile**：某个智能体的角色、职责、能力声明和默认行为，不等于工具权限。
- **Skill group**：技能绑定的组合模板，用于复用某类方法包，例如“长篇连续性技能组”“资料检索技能组”“文风审稿技能组”；它不是协作组，也不是权限 profile。
- **Skill loadout / Skill binding**：可复用的方法、知识加载规则、工作流技能和提示资源引用；用户可以在 GUI 中为智能体绑定或解绑，但它不授予写入权。
- **Constraint**：用户或项目提出的规则要求；表达限制是其中最典型、必须保留 CRUD 的用户可见子集。
- **Execution constraint**：内部执行和审计层，用来把字数、表达限制、交付完整性、恢复策略等转成可检查事实；它不能吞掉用户可见规则的产品语义。
- **Tool profile**：工具权限合同，声明读、写、确认、委派、正式交付、外部搜索、资产更新等边界。
- **Prompt block**：可渲染的提示资源，负责让规则、技能、阶段和工具说明进入模型上下文；它不是权限系统。
- **Model policy**：模型路由、fallback、timeout、context budget、output budget、成本策略。
- **Supervisor / control plane**：运行调度、心跳、暂停、恢复、重试和降级层；它不应该负责判断小说题材，也不应该替代内容质量审稿。

#### 5.9.4 当前文档需要修正的潜在冲突

1. **“多技能组合”不能变成普通 GUI 的原始技能列表，但高级 GUI 必须可配置。** 默认应展示协作组能力摘要，例如“负责资料核对、连续性审查、文风建议”；进入编辑协作组后，用户应能为每个智能体绑定/解绑技能。
2. **表达限制不能被执行约束层吞没。** 表达限制最初就是用户可新增、可编辑、可删除的规则资产；执行约束只负责注入、检查、修复和取证。
3. **子智能体不能默认拥有正式章节交付权。** 作者子智能体可以产出正文片段，但除非主链明确授予受控交付工具，否则正式章节只能由主链收口。
4. **执行包不能变成新的全能巨物。** `ExecutionPackage` 应是快照和索引，内部拆成 context、constraint、tool、model、delivery、collaboration、recovery 子合同；算法仍放在专门 service/policy。
5. **prompt block 资源化不应成为当前发布阻塞。** 如果 GUI 不暴露 prompt block 编辑器，发布前只需要能追踪来源和稳定渲染；完整编辑器、导入导出和市场化应放到后续。
6. **智能体提出的项目规则变化只能是 proposal。** 约束、角色 profile、叙事状态、资料归档、模型/工具策略变化都不能由模型静默改写；高风险变化要用户确认。
7. **协作包需要生命周期。** 每个可配置资产应记录 version、source、scope、project snapshot/copy 行为、删除联动策略和迁移规则，否则应用级删除会影响项目复现。
8. **不要把剧情转折判断写成程序枚举。** 程序可以存储和验证“叙事状态发生变化、影响范围、证据、时间点、空间/关系/身份/记忆等维度”，但不能穷举所有流派的转折表达方式。
9. **不要把智能体组做成只读模板。** 内置组是启动模板，不是用户唯一选择；用户应能复制、改名、增删成员、调整技能绑定和模型偏好。
10. **不要把技能编辑和权限编辑混在一个开关里。** 打开“资料检索技能”不等于允许联网；打开“章节起草技能”不等于允许提交正式章节。
11. **不要把 AI 生成技能当成已安装技能。** 生成只是草稿来源，必须经过 proposal、校验、确认、版本锁定和风险说明。
12. **不要把生态设置搬进写作主面板。** 主面板展示当前协作摘要和结果，复杂资产管理应留在专门设置入口。

#### 5.9.5 成本、稳定性与退化

多智能体如果没有预算约束，会比单智能体更不稳定，也更容易烧成本。发布前至少需要以下运行边界：

- 每轮协作有 concurrency budget、token budget、retry budget、child max rounds、timeout。
- 子智能体失败先局部重试或降级，不能默认重跑整章、整条长任务。
- 资料、审稿、连续性等非交付子任务失败时，主链可以带着“协作降级”继续；正式交付风险过高时再请求用户确认。
- 预算耗尽、模型不可用、工具不可用时，协作组应能退化为单主智能体路径，并留下可读原因。
- 长任务 supervisor 只负责调度恢复，不要背负具体题材规则；内容质量判断仍由 review/continuity/information/constraint 链承担。

#### 5.9.6 冲突仲裁

多智能体不是“大家说完就拼起来”。当作者、审稿、连续性、资料专家意见冲突时，需要统一仲裁协议：

1. 子结果带 `risk / evidence / suggestion / adoption_hint / confidence`。
2. 主链生成 `collaboration_conflict` 记录，标明冲突对象、影响章节、风险等级和可选处理。
3. 低风险冲突由主链按项目策略自动采纳或忽略。
4. 中风险冲突可进入修订建议或下一轮任务。
5. 高风险冲突，例如改变长期设定、覆盖用户规则、重写已发布章节、引入外部版权风险，必须请求用户确认。

#### 5.9.7 近期落地取舍

当前阶段的目标是把软件收口到可实际发布，而不是一次性做完完整协作生态。因此优先级应这样校准：

- 发布前必须证明：GUI 选择的协作组真实进入运行链；子智能体隔离、权限、模型策略、结果合并、失败恢复可观测；普通默认路径不看内部术语。
- 发布前必须保留方向：所有新增规则、技能、协作组、工具权限、提示资源都向合同化、可版本化、可项目快照靠拢。
- 发布前不必完成：完整 prompt block 编辑器、协作包市场、所有资产导入导出、所有专家角色 GUI 细节页。但如果 GUI 已暴露“自定义协作组”，就至少要能安全配置组成员、主智能体、技能绑定和明显权限边界。
- 接下来一段时间的主任务应优先压在两条线上：真实长链稳定性，以及 information/资料/巧思/拆书资产能被保存、激活、引用和回看。生态配置要服务这两条线，不能反过来抢走收口节奏。
- 任何新修复都不得把探针样例、题材机制、特殊剧情名写进核心分支；只能沉淀通用合同、策略和验证工具。

## 6. 测试残留与发布资产收口

当前 `.gitignore` 已经忽略：

- `artifacts/`
- `**/artifacts/`
- `test_api.txt`
- `local/*`
- `.env*`
- `references/MuMuAINovel-main/`

密钥扫描通过，这是好消息。

仍需收口：

1. `apps/novel_agent_app/tool/` 下存在多个真实探针脚本，如 `real_general_novel_probe.dart`、`real_long_task_probe.dart`、`real_multiscope_pressure_probe.dart` 等。它们可以作为开发验证工具保留，但必须明确不参与用户发布包。
2. `artifacts/` 中有大量历史截图和真实探针产物。它们应继续忽略，不进入发布包。
3. probe 配置读取仍兼容旧 `test_api.txt`。发布版文档和 GUI 不能提它；开发文档可以保留迁移说明。
4. 参考项目目录已忽略，发布前仍应确认不会被打包或出现在 About/帮助文案中。

需要改哪里：

- 打包脚本/发布脚本
- GUI 关于页/帮助入口
- 开发文档与用户文档分层
- probe 工具目录 README

## 7. 发布前必须补的验收矩阵

### 7.1 GUI 用户路径验收

必须覆盖：

1. 首次启动。
2. 配置模型并测试连接。
3. 创建普通小说项目。
4. 写出第一章正文。
5. 生成下一章或续写一段。
6. 查看/编辑项目资料。
7. 创建长任务项目。
8. 启动短长任务并在总站看到进度。
9. 暂停、继续、失败后恢复。
10. 拆书导入一个小样本并生成可读资料。
11. 选择一个多智能体协作组，并能看懂当前主智能体、协作视角和子智能体结果。

验收标准：

- 用户不需要知道内部 contract/tool/schema 名称。
- 每一步都有明确下一动作。
- 失败时能知道原因和可点击处理方式。
- 产物能从 GUI 打开，不需要去文件夹里猜。
- 多智能体细节默认显示为“协作结果/审稿意见/资料摘要”，原始工具调用和 sub_session_id 放进诊断详情。

### 7.2 核心稳定性验收

必须覆盖：

1. 普通项目真实生成 3-5 章。
2. 长任务真实生成 10 章。
3. 长任务中途暂停/恢复。
4. 人为制造空正文/标题-only/路径漂移，能进入恢复链。
5. information 工具真实至少命中一次。
6. 表达限制和字数策略在普通项目与长任务都生效。
7. 拆书导入资源能被后续写作激活。
8. 子智能体失败、空返回、工具错误不会直接破坏主链章节交付或长任务恢复。

### 7.3 视觉发布验收

必须覆盖：

1. Windows 桌面 1366x768、1920x1080。
2. Android 常见窄屏。
3. 中文字体无方框。
4. 长文本不溢出按钮/卡片。
5. 默认浅色主题可读、不过脏。
6. 深色主题对比足够。

### 7.4 多智能体协作验收

必须覆盖：

1. mock LLM 主智能体调用至少两个不同子智能体，例如资料检索和文风审稿。
2. 子智能体消息中不包含完整主会话，只包含 task、context_excerpt、constraints、source_paths、项目结构或工具读取结果。
3. 子智能体工具权限按角色生效：只读审稿不能写正文，作者视角可产出正文片段但不能递归委派。
4. child-specific model/tool policy 生效，至少能观测到 writer/reviewer 的有效模型参数或工具范围不同。
5. 主智能体必须合并子结果，并最终产出用户可理解回复或正式章节交付。
6. GUI 当前选择的智能体组必须进入本轮运行，而不是 use case 自行选择第一个 optional group。
7. 子智能体失败时，主链应返回可恢复状态：可以降级继续、重试子任务、或明确提示用户处理；不能静默停止。
8. 长任务场景验证一次多智能体失败不会绕过 supervisor / recovery。
9. 子智能体提示词来源能追踪到 prompt block / skill / agent profile，而不是只看一段拼接后的长 system prompt。
10. 子智能体工具权限使用命名 profile 验证，例如 `read_only_review`、`chapter_writer`、`research_only`，而不是只测 blocked list。
11. 子任务执行进入任务事件记录，GUI 能展示“已委派、已返回、已采纳/未采纳、失败原因”。
12. 协作结果至少包含 summary、evidence、risk、suggestion、adoption_hint，不能只返回一段不可结构化复用的文本。
13. 模型回退策略至少在 mock 层可验证：主模型失败后能按子智能体策略降级，而不是重跑整条主任务。
14. 普通 GUI 验证暴露协议：默认不出现 prompt block id、tool profile id、execution constraint、raw JSON、sub_session_id。
15. 子智能体正式交付权有守卫：未授权 child 不能直接提交章节；授权时必须能追踪 delegated authority。
16. 协作冲突能被记录和仲裁：至少 mock 一次审稿意见与连续性意见冲突，主链能采纳、忽略、转修订或请求确认。
17. 多智能体预算和退化可验证：child timeout、retry budget 耗尽、模型不可用时能退化为单主链或可恢复状态。
18. 智能体提出规则/资料/profile 更新时只能生成 proposal，高风险 proposal 必须经过用户确认后才落盘。
19. 可配置资产至少带 source/version/scope/project snapshot 元数据；删除应用级资产时不破坏已创建项目的复现。
20. 单智能体项目验证走同一协作合同的单成员组路径，而不是另起一套不可复用流程。
21. GUI 能创建或复制一个自定义智能体组，增删成员，设置主智能体，并在一次 mock 运行中证明该组配置进入运行链。
22. GUI 能为某个智能体绑定/解绑至少一个技能，并验证技能来源、版本、启用状态和适用阶段进入 child run package。
23. 技能绑定与工具权限分离可验证：启用“资料检索技能”但未授予联网/外部搜索权限时，只能读取本地资料或给出权限提示。
24. 配置校验可验证：无主智能体、多个主智能体、子智能体拥有不合规正式交付权、技能能力需求与权限不匹配时，GUI 给出可理解错误。

## 8. 建议收口优先级

### P0：发布阻断

1. 修复中文字体方框与视觉回归截图可靠性。
2. 把普通用户默认 GUI 中的内部术语降噪。
3. 提供模型连接测试与清晰的首次配置路径。
4. 用 GUI 路径证明普通项目能生成正文。
5. 用 GUI 路径证明短长任务能启动、可见进度、可恢复。
6. 如果 GUI 暴露多智能体协作组，必须证明当前选择的协作组能真实进入运行链，且普通用户看不到内部 prompt/tool/contract 术语；否则发布版应把多智能体标为实验能力或默认隐藏。
7. 如果 GUI 暴露“自定义协作组/自定义智能体”，必须提供最小安全编辑器：组成员、主智能体、技能绑定摘要、权限边界和配置校验缺一不可；否则只能提供只读模板选择。
8. 确认发布包不包含探针产物、真实 key、参考 GPL 项目。

### P1：发布前必须强烈建议完成

1. 长任务详情页改成用户可理解的运行中心，诊断信息折叠。
2. 项目创建入口增加“新建作品”主路径。
3. 表达限制/项目资产术语改成人话。
4. information 层做一次真实命中验收。
5. 拆书导入补齐“后续用途与分析进度”的 GUI 表达。
6. 建立用户暴露协议投影：普通用户、高级用户、开发诊断、内部运行时各自看到不同层级的信息。
7. 补齐 child-specific model/tool policy，让不同子智能体可以稳定使用不同模型与工具权限。
8. 增加多智能体 mock probe 与 GUI 短探针，证明主智能体委派、子智能体隔离、结果合并、失败恢复。
9. 建立多智能体 `ExecutionPackage / ChildRunPackage / CollaborationResultPackage` 三段合同，避免靠零散参数和大 prompt 传递语义。
10. 给子智能体正式交付权、项目规则更新权、用户确认权加守卫；默认只能返回建议或 proposal。
11. 增加协作冲突仲裁、预算控制和退化策略，让多智能体失败不会扩大成长任务失败。
12. 建立命名 tool permission profile，让子智能体的读、写、交付、确认、委派权限可配置可测试。
13. 协作专家提示词至少要能追踪来源、稳定渲染和恢复默认；完整 prompt block 编辑器不作为当前发布阻塞。
14. 建立最小智能体/协作组 GUI 编辑器：复制内置组、增删成员、设置主智能体、绑定/解绑技能、查看能力摘要、保存项目快照。
15. 建立技能绑定解析器：从 app catalog、project snapshot、session override 合并为有效 skill loadout，并输出配置诊断。
16. 建立技能能力需求与工具权限的兼容检查，避免用户以为启用了技能就自动获得写入或联网权限。

### P2：可作为发布后优化，但设计方向要锁定

1. 重构超大控制器与 runtime service。
2. 引入更成熟的主题系统和字体包。
3. 完整用户帮助文档。
4. 更细的 GUI 引导与空状态。
5. CLI 完整收口。
6. 将更多协作角色、提示词和工具权限下沉为可配置资产，而不是继续膨胀内置代码。
7. 为多智能体建立可导入导出的协作组包，包括 agent profile、skill loadout、prompt block、model policy、tool profile 与 applicability scope。
8. 为资料检索、连续性审查、文风审稿、资产派生建议建立更细的 GUI 协作结果视图。
9. 建立完整 prompt block / skill loadout 高级编辑器，并提供版本、来源、项目快照、迁移和删除联动策略。
10. 建立协作包导入导出与分享机制，但必须保持普通用户默认只选协作组。
11. 建立技能市场或外部技能安装能力时，必须先完成安全来源、能力需求、版本锁定和项目快照策略。

## 9. 最终判断

当前功能不是“不能用”，而是“还没有产品化”。底层已经积累了不少正确能力，尤其是章节交付状态机、长任务恢复、信息资料层、开放叙事工具合同，这些方向值得保留。

真正要收口的是：

1. 把用户默认路径做短。
2. 把内部诊断收起来。
3. 把真实稳定性跑出来。
4. 把视觉和字体做成发布质量。
5. 把探针、参考项目、密钥配置与发布包彻底隔离。
6. 把多智能体从“已有对象和局部测试”推进到“用户选择协作组后，主智能体能真实委派、子智能体隔离执行、结果回到主链、失败可恢复”的产品能力。
7. 把智能体组、技能、约束、工具权限和模型策略的关系收进暴露协议：普通默认路径看协作和规则；显式配置路径允许管理智能体、组成员和技能绑定；内部运行时只消费合同。

做到这些以后，项目才会从“功能很多的开发工作台”变成“作者愿意每天打开使用的软件”。
