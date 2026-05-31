# NovelAgentFlutter 表达限制系统会话顺序文档

最后更新：2026-05-28

---

## 0.6 Session EC-06 完成记录

- 已完成 `Session EC-06：app 最小编辑入口与总回归`
- app 本轮已新增并固定：
  - `ProjectExpressionConstraintWorkspaceService`
  - `ProjectExpressionConstraintBindingActionService`
  - `ProjectAssetsExpressionConstraintViewDataService`
  - `ExpressionConstraintBindingEditorPanel`
- 当前入口已经固定：
  - 项目资产中心现已新增 `表达限制` 页签
  - 用户现已可直接查看：
    - 内置 preset
    - 当前项目绑定状态
    - 推荐作用域
    - preset 规则与风险信号
  - 用户现已可直接编辑：
    - 项目级启用开关
    - `default_for_project`
    - `target_agent_ids`
    - `target_mode_ids`
    - `target_stage_ids`
    - `weight`
  - `de_ai` 现在只是表达限制页中的一个普通内置 preset，不再拥有特殊 UI 入口
- 当前结构取舍已经固定：
  - 最小入口挂在现有 `Project Assets` 三栏壳中，而不是再新造一页设置或独立编辑器
  - preset 本体仍保持只读；本轮只开放项目级 binding 编辑，不顺手做 profile 自定义 DSL
  - repository 访问继续收束在 app 工作区服务里，控制器只负责选择态与动作分发
- 当前总回归已经覆盖：
  - 不启用任何 binding 时，表达限制列表仍可正常浏览
  - 启用 `de_ai` 时，项目绑定会稳定落盘并回读
  - 启用其他内置 preset 时，页签与编辑器会按 profile 正常投影
  - 不同项目的 binding 已确认不会串写、串读
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `dart analyze lib/app/bootstrap/app_bootstrap.dart lib/app/state/app_shell_controller.dart lib/features/project_assets`
    - 通过
  - `apps/novel_agent_app`
    - `flutter test test/project_assets_view_data_service_test.dart test/project_expression_constraint_binding_action_service_test.dart test/project_expression_constraint_workspace_service_test.dart`
    - 通过
- 表达限制系统当前会话顺序现已全部完成：
  - `EC-01` ~ `EC-06` 均已落地
  - 后续若继续扩展，应另开新文档或新 session 线，而不是回到本顺序文档继续混改

---

## 0.5 Session EC-05 完成记录

- 已完成 `Session EC-05：review / authenticity / continuity 联动`
- core 本轮已新增并固定：
  - `ExpressionConstraintReviewProjection`
  - `ExpressionConstraintReviewProjectionService`
- 当前联动已经明确：
  - `ReviewPromptVariableService` 现已可稳定输出：
    - `review_focuses`
    - `authenticity_pass_level`
    - `mini_recheck`
    - `voice_protection`
  - `ReviewTaskFactoryService` 现已会把表达限制投影收束进 review task：
    - goal / brief / tool_hint
    - 以及 task metadata 中的结构化 review focus / mini recheck 字段
  - `LongTaskTaskTransactionService` 与 `LongTaskTaskPromptRenderer` 现已可把 review task metadata 中的：
    - 审稿重点
    - 真实性复核强度
    - `Mini Recheck`
    正式渲染进事务提示
  - `LongTaskCheckpointReviewService` 现已能从 execution context pack 中的 `creative_rule_stack` 提取表达限制投影，并正式输出：
    - `expression_constraint_review`
    - `mini_recheck_items`
    - 以及被增强后的 `confirmation_focus / drift_watch_items / next_actions`
  - `LongTaskCheckpointReviewTaskSuggestionService` 现已会把表达限制联动进后续 review 建议：
    - `de_ai / natural_expression / low_jargon_narration` 会抬高 style review 优先级
    - `strict_pov_boundary / narrative_boundary / continuity_guard` 会把 POV / 信息边界 / 状态漂移提升为 continuity pressure
  - `LongTaskPostprocessTransactionService` 与 `LongTaskPostprocessPromptRenderer` 现已会在后处理 / 修订复核轮次显式显示：
    - 表达限制复核重点
    - 真实性复核强度
    - `Mini Recheck`
- 当前策略已经固定：
  - 去 AI / 自然表达约束现在不再只是 prompt 前置要求，而是会继续影响：
    - review focus
    - checkpoint review
    - postprocess mini recheck
  - “视角泄漏 / 信息边界混用 / 说话风格漂移 / 设定状态漂移” 现在会被明确提升为：
    - continuity / structural review 风险
    - 而不是被误压成单纯文风问题
  - 真实性清理默认带有明确保真护栏：
    - 不把人物声音洗平
    - 不误删必要术语
    - 不因去模板化而改坏连续性
- 本轮刻意未做：
  - app / UI 编辑入口
  - 新增更多 builtin preset
  - 更重的报告 DSL 或独立 authenticity center
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/creative/expression_constraint_review_projection.dart lib/src/creative/expression_constraint_review_projection_service.dart lib/src/review/review_prompt_variable_service.dart lib/src/review/review_task_factory_service.dart lib/src/workflow/long_task_task_transaction_service.dart lib/src/workflow/long_task_task_prompt_renderer.dart lib/src/workflow/long_task_checkpoint_review_service.dart lib/src/workflow/long_task_checkpoint_review_markdown_renderer.dart lib/src/workflow/long_task_checkpoint_review_task_suggestion_service.dart lib/src/workflow/long_task_postprocess_transaction_service.dart lib/src/workflow/long_task_postprocess_prompt_renderer.dart test/review_report_services_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_checkpoint_review_task_suggestion_service_test.dart test/long_task_runtime_services_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/review_report_services_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_checkpoint_review_task_suggestion_service_test.dart test/long_task_runtime_services_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_long_task_checkpoint_review_service_test.dart`
    - 通过
- 后续扩展点：
  - `Session EC-06` 进入 app 最小编辑入口与总回归
  - 后续若要扩更细的 authenticity pass 等级或用户自定义 recheck 模板，优先继续挂在这条 projection 链，不要把规则散回 task factory / renderer 各处

---

## 0.4 Session EC-04 完成记录

- 已完成 `Session EC-04：运行时注入策略与 prompt 链接线`
- core 本轮已新增并固定：
  - `ExpressionConstraintInjectionMode`
  - `ExpressionConstraintInjectionPolicyService`
- 当前运行时接线已经明确：
  - `ContextAssemblerService` 现已基于 intent 解析表达限制注入模式
  - `GenerateDraftUseCase` 现已可显式接收：
    - `expression_constraint_profiles`
    - `project_expression_constraint_bindings`
  - `ChapterAtomicExecutionBuilderService` 现已把表达限制字段透传进 context pack 组装
  - `LongTaskTaskTransactionService` 现已按任务类型决定：
    - 只给短摘要
    - 还是给短摘要 + 表达限制细则
  - `LongTaskPostprocessTransactionService` 现已只默认消费表达限制短摘要，不再带长细则
- 当前策略已经固定：
  - `draft`
    - 默认 `brief_and_sections`
  - `workflow_task`
    - `chapter / revision` 默认 `brief_and_sections`
    - `planning / review / checkpoint / world_update / summary` 默认 `brief_only`
  - `review / outline / setting / summary`
    - 默认 `brief_only`
  - 普通闲聊、工具参数确认、非创作型轮次
    - 默认 `disabled`
- 当前 prompt-facing 投影已经明确：
  - creative draft/context pack 链：
    - 表达限制进入共享摘要
    - 且在需要时进入正式 context sections
  - 长任务事务 prompt：
    - 默认显示创作约束摘要
    - 对正文/修订写作任务额外显示 `表达限制细则`
  - 非创作轮次：
    - 不再默认泄漏旧的 `creative_layer=expression_constraint` 长记忆片段
- 本轮刻意未做：
  - review / authenticity / continuity 联动扩张
  - UI 编辑入口
  - 新增更多 builtin preset
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/creative lib/src/context/context_assembler_service.dart lib/src/use_cases/generate_draft_use_case.dart lib/src/workflow/chapter_atomic_execution_builder_service.dart lib/src/workflow/long_task_task_transaction_service.dart lib/src/workflow/long_task_postprocess_transaction_service.dart lib/src/workflow/long_task_task_prompt_renderer.dart test/expression_constraint_injection_policy_service_test.dart test/context_assembler_service_test.dart test/draft_generation_use_case_test.dart test/long_task_runtime_services_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/expression_constraint_injection_policy_service_test.dart test/context_assembler_service_test.dart test/draft_generation_use_case_test.dart test/long_task_runtime_services_test.dart`
    - 通过
- 后续扩展点：
  - `Session EC-05` 直接进入 review / authenticity / continuity 联动
  - 若后续要把注入策略开放给用户手动切换，优先在 app 层加显式入口，不要把 UI 直接耦回 policy service

---

## 0.3 Session EC-03 完成记录

- 已完成 `Session EC-03：adapters 持久化与内置 preset 注册`
- adapters 本轮已新增并固定：
  - `ExpressionConstraintProfileDocumentCodecService`
  - `ExpressionConstraintProfilePathService`
  - `ExpressionConstraintProfileRepository`
  - `ProjectExpressionConstraintBindingDocumentCodecService`
  - `ProjectExpressionConstraintBindingPathService`
  - `ProjectExpressionConstraintBindingRepository`
  - `BuiltinExpressionConstraintProfileRegistrationService`
- 当前落盘策略已经明确：
  - 项目自定义 expression constraint profiles 固定写入：
    - `.novel_agent/settings/expression_constraint_profiles.json`
  - 当前项目 expression constraint bindings 固定写入：
    - `.novel_agent/settings/expression_constraint_bindings.json`
  - builtin preset 不会反写回项目文档，只通过 builtin registry 参与合并视图
- 当前行为已经固定：
  - `ExpressionConstraintProfileRepository`
    - 现已支持只读项目显式 profiles
    - 也支持把 builtin presets 与项目 profiles 合并后输出
    - 当项目 profile 与 builtin preset 同 id 时，项目版本覆盖 builtin 版本
  - `ProjectExpressionConstraintBindingRepository`
    - 现已只负责当前项目的 binding 列表持久化
    - 不承担 resolver / prompt 注入 / builtin 选择逻辑
  - 当前首批 builtin preset 已注册：
    - `de_ai`
    - `strict_pov_boundary`
    - `low_jargon_narration`
- 本轮取舍已固定：
  - `profile` 目前先走隐藏设置 JSON，而不是立即演化成项目可见资产目录
  - 这样先把仓储合同、合并策略和 builtin 注册做稳；后续若要升级成可见资产或 bundle 再单开会话演化
- 本轮刻意未做：
  - runtime prompt 注入策略
  - UI 编辑入口
  - profile 资产化 / bundle 化
  - review / authenticity 联动
- 本轮验证结果：
  - `packages/novel_agent_adapters`
    - `dart analyze lib/novel_agent_adapters.dart lib/src/storage/expression_constraint_profile_document_codec_service.dart lib/src/storage/expression_constraint_profile_path_service.dart lib/src/storage/expression_constraint_profile_repository.dart lib/src/storage/project_expression_constraint_binding_document_codec_service.dart lib/src/storage/project_expression_constraint_binding_path_service.dart lib/src/storage/project_expression_constraint_binding_repository.dart lib/src/packages/builtin_expression_constraint_profile_registration_service.dart test/expression_constraint_profile_repository_test.dart test/project_expression_constraint_binding_repository_test.dart test/builtin_expression_constraint_profile_registration_service_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/expression_constraint_profile_repository_test.dart test/project_expression_constraint_binding_repository_test.dart test/builtin_expression_constraint_profile_registration_service_test.dart`
    - 通过
- 后续扩展点：
  - `Session EC-04` 直接进入：
    - `ExpressionConstraintInjectionPolicyService`
    - runtime creative-turn gating
    - prompt-facing brief / context 注入策略
  - 若后续确认需要把 profile 升级成项目可见资产或导入导出 bundle，优先另开 session，不要把 runtime 注入逻辑与资产化迁移混在一轮里

---

## 0.2 Session EC-02 完成记录

- 已完成 `Session EC-02：resolver / projection / creative stack 接线`
- core 本轮已新增并固定：
  - `ExpressionConstraintScopeNormalizerService`
  - `ExpressionConstraintProfileNormalizerService`
  - `ProjectExpressionConstraintBindingNormalizerService`
  - `ProjectExpressionConstraintBindingResolverService`
  - `ExpressionConstraintBriefRenderer`
  - `ExpressionConstraintContextSectionService`
- 当前接线已经明确：
  - `CreativeRuleStack` 现已正式收纳：
    - `expression_constraints`
    - `expression_constraint_bindings`
  - `CreativeRuleStackResolverService` 现已能解析：
    - 原始表达限制 profile 列表
    - 项目级表达限制 binding 列表
    - 并按 `agent / mode / stage` 作用域收束生效 profile
  - `CreativeRuleBriefRenderer` 现已把表达限制纳入共享摘要
  - `CreativeRuleContextSectionService` 现已把表达限制纳入正式 context sections
  - `ContextAssemblerService` 现已正式消费：
    - `expression_constraint_profiles`
    - `project_expression_constraint_bindings`
  - 长任务事务构建链也已补齐透传入口，避免后续 `EC-04` 再回头补基础字段
- 当前语义已经固定：
  - 表达限制会稳定进入 `creative rule stack`
  - 但目前仍只做 brief / context projection，不做 runtime prompt 注入策略
  - 表达限制优先级已固定在：
    - `项目创作宪法 > 模式引导 > 表达限制 > 项目风格 > 其他上下文`
  - 旧的 `creative_layer=expression_constraint` 记忆片段，在有正式表达限制投影时会被消费，不再与新链重复
- 本轮刻意未做：
  - repository / builtin preset 注册
  - 运行时创作链 gating
  - review / authenticity 联动
  - Flutter UI
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/creative lib/src/context/context_assembler_service.dart lib/src/workflow/long_task_task_transaction_service.dart lib/src/workflow/long_task_postprocess_transaction_service.dart test/expression_constraint_contracts_test.dart test/expression_constraint_services_test.dart test/creative_rule_stack_resolver_service_test.dart test/context_assembler_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/expression_constraint_contracts_test.dart test/expression_constraint_services_test.dart test/creative_rule_stack_resolver_service_test.dart test/context_assembler_service_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/long_task_runtime_services_test.dart`
    - 通过
- 后续扩展点：
  - `Session EC-03` 直接进入 adapters：
    - `ExpressionConstraintProfileRepository`
    - `ProjectExpressionConstraintBindingRepository`
    - builtin preset registry
  - 持续避免把表达限制演化成第二套独立创作规则中心；后续一律继续围绕 `CreativeRuleStack` 接线

---

## 0.1 Session EC-01 完成记录

- 已完成 `Session EC-01：core 合同与作用域`
- core 本轮已新增并固定：
  - `ExpressionConstraintKind`
  - `ExpressionConstraintScope`
  - `ExpressionConstraintProfile`
  - `ProjectExpressionConstraintBinding`
- 当前语义已经明确：
  - 表达限制正式建模为独立的创作约束合同，不进入 `skill / skill_group / loadout`
  - `de_ai` 只被视为一个普通的内置 preset id，不再作为系统主语义
  - `ProjectExpressionConstraintBinding` 保持与 `ProjectStyleBinding` 接近的字段形状：
    - `profile_id`
    - `enabled`
    - `default_for_project`
    - `target_agent_ids`
    - `target_mode_ids`
    - `target_stage_ids`
    - `weight`
  - `ExpressionConstraintScope` 已单独存在，并可表达：
    - `project_type_ids`
    - `agent_ids`
    - `mode_ids`
    - `stage_ids`
  - `ProjectExpressionConstraintBinding` 当前额外提供轻量 `scope` 视图，便于后续 resolver / projection 接线，但本轮没有提前混入解析责任
- 本轮刻意未做：
  - repository / codec / 写盘
  - creative rule stack 接线
  - prompt 注入
  - Flutter UI
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/creative/expression_constraint_kind.dart lib/src/creative/expression_constraint_scope.dart lib/src/creative/expression_constraint_profile.dart lib/src/creative/project_expression_constraint_binding.dart test/expression_constraint_contracts_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/expression_constraint_contracts_test.dart`
    - 通过
- 后续扩展点：
  - `Session EC-02` 优先建立：
    - `ProjectExpressionConstraintBindingResolverService`
    - `ExpressionConstraintBriefRenderer`
    - `ExpressionConstraintContextSectionService`
  - 后续接线时应继续复用 `CreativeRuleStack`，不要把表达限制演化成第二套并行创作规则中心

---

## 1. 背景

当前我们已经明确：

- `去 AI 风` 不是唯一需求
- 有些用户反而希望保留明显的 AI 风味
- 未来还可能出现：
  - 强限制视角纪律
  - 强限制术语密度
  - 强限制解释腔
  - 强限制破折号 / 排比 / 假深刻句
  - 特定平台风格限制
  - 项目类型专属表达限制

因此，真正要做的不是“单独做一个去 AI 风功能”，而是：

**做一个通用的、可开关的、可复用的、稳定触发的表达限制系统，`去 AI 风` 只是内置 preset 之一。**

---

## 2. 设计结论

### 2.1 不建议放进 skill / skill group

虽然它和“常驻附着”很像，但它本质上不是：

- 工具能力
- 工作方法能力
- 单次可调用 skill

它更像：

- 创作约束
- 表达约束
- 修订与验收策略

所以不建议继续污染：

- `AgentSkillLoadout`
- `skill group`
- `load_agent_skill`

### 2.2 正式建模建议

本轮推荐引入两层正式对象：

1. `ExpressionConstraintProfile`
   - 一个可复用的表达限制 preset
   - `de_ai` 只是其中一个内置 profile

2. `ProjectExpressionConstraintBinding`
   - 当前项目如何启用这些 profile
   - 支持可开关与作用域

### 2.3 正式语义

- `ExpressionConstraintProfile`
  - 表达“限制规则是什么”
  - 例如：
    - 去 AI 风
    - 严格 POV 纪律
    - 降低分析腔
    - 平台化短句节奏

- `ProjectExpressionConstraintBinding`
  - 表达“当前项目 / 当前智能体 / 当前模式 / 当前阶段启用了什么限制”

### 2.4 稳定触发的真正含义

这里的“常驻”不是指每一次 agent 所有轮次都强行拼上全文规则。

而是指：

- 当进入创作型 / 修订型 / 审稿型生成链时
- 系统会稳定解析当前启用的表达限制
- 并把**短摘要 + 必要规则投影**送入 prompt / review / post-pass

也就是说：

- 稳定触发
- 但不是无脑全时段硬拼

### 2.5 作用域要求

表达限制至少应支持：

- 全项目默认启用
- 按智能体启用
- 按模式启用
- 按阶段启用

后续若确有需要，再扩：

- 按项目类型
- 按任务类型
- 按章节控制卡临时覆盖

---

## 3. 总体约束

### 3.1 必须遵守 `agent.md`

继续遵守：

- 先 core，后 adapters，再 app，最后 UI
- composition root 只放 bootstrap
- 不造新的万能 controller / manager
- 单文件超过 `400` 行就复核
- 接近 `700` 行必须主动拆

### 3.2 继续复用现有创作约束链

优先复用：

- `CreativeRuleStack`
- `ProjectConstitution`
- `ModeGuidance`
- `StyleProfile / ProjectStyleBinding`

表达限制系统不应成为与它们平行竞争的第二套创作约束中心。

### 3.3 不要做的事

- 不把表达限制塞进 `skill loadout`
- 不让 widget 自己判断限制规则
- 不把长参考全文直接每轮拼进 prompt
- 不先做大 UI
- 不顺手扩更多“创作质量系统”主线

---

## 4. 推荐执行顺序总览

1. `Session EC-01`：core 合同与 scope
2. `Session EC-02`：resolver / projection / creative stack 接线
3. `Session EC-03`：adapters 持久化与内置 preset 注册
4. `Session EC-04`：运行时注入策略与 prompt 链接线
5. `Session EC-05`：review / authenticity / continuity 联动
6. `Session EC-06`：app 最小编辑入口与总回归

总量仍控制在单轮可实施范围内，每轮只做一类事。

---

## 5. Session EC-01：core 合同与作用域

### 本轮目标

先把“表达限制系统”立成正式领域对象，但不碰 UI，不碰具体 prompt 文案，不碰写盘。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/unified-de-ai-writing-scheme-2026-05-28.md`
- `packages/novel_agent_core/lib/src/creative/creative_rule_stack.dart`
- `packages/novel_agent_core/lib/src/assets/project_style_binding.dart`

### 必须完成

1. 建立 core 对象，例如：
   - `ExpressionConstraintProfile`
   - `ExpressionConstraintScope`
   - `ExpressionConstraintKind`
   - `ProjectExpressionConstraintBinding`
2. 明确 profile 至少支持：
   - `id`
   - `display_name`
   - `summary`
   - `rules`
   - `risk_signals`
   - `metadata`
3. 明确 binding 至少支持：
   - `profile_id`
   - `enabled`
   - `default_for_project`
   - `target_agent_ids`
   - `target_mode_ids`
   - `target_stage_ids`
   - `weight`
4. 固定语义：
   - `de_ai` 是内置 profile，不是系统主语义
   - 表达限制不等于 skill

### 本轮不要做

- 不做 repository
- 不做 resolver
- 不做 prompt 注入
- 不做 UI

### 本轮重点拆耦

- `profile contract`
- `binding contract`
- `scope contract`

### 完成判定

- core 已能独立表达“某个表达限制 preset”
- core 已能独立表达“当前项目如何启用它”
- 不依赖 Flutter / 文件系统 / adapters

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-01 执行。先阅读 agent.md、docs/unified-de-ai-writing-scheme-2026-05-28.md、packages/novel_agent_core/lib/src/creative/creative_rule_stack.dart、packages/novel_agent_core/lib/src/assets/project_style_binding.dart。只做 core 合同：建立 ExpressionConstraintProfile、ExpressionConstraintScope、ProjectExpressionConstraintBinding 等正式对象，明确这是“可开关的表达限制系统”，其中 de_ai 只是内置 preset，不要放进 skill/loadout，不要做 UI，不要做持久化。
```

---

## 6. Session EC-02：resolver / projection / creative stack 接线

### 本轮目标

让表达限制正式进入现有 `creative rule stack`，但仍不碰 adapters 和 UI。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- 本文档
- `packages/novel_agent_core/lib/src/creative/creative_rule_stack_resolver_service.dart`
- `packages/novel_agent_core/lib/src/context/context_assembler_service.dart`

### 必须完成

1. 建立 resolver / projection，例如：
   - `ProjectExpressionConstraintBindingResolverService`
   - `ExpressionConstraintBriefRenderer`
   - `ExpressionConstraintContextSectionService`
2. 明确输出两种投影：
   - 短摘要 brief
   - 结构化 context section
3. 固定接线规则：
   - 进入创作型上下文时可消费表达限制投影
   - 非创作轮次不默认重注入长文
4. 继续保证：
   - `ProjectConstitution`
   - `ModeGuidance`
   - `StyleProfile`
   不被旁路掉

### 本轮不要做

- 不做 repository
- 不做 app 页
- 不做 review 链

### 本轮重点拆耦

- `binding resolver`
- `brief renderer`
- `context section service`

### 完成判定

- 表达限制已可被 `CreativeRuleStack` 消费
- prompt 上下文可以稳定拿到“启用中的限制摘要”
- 没有造第二套创作规则中心

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-02 执行。先阅读 agent.md、本文件、packages/novel_agent_core/lib/src/creative/creative_rule_stack_resolver_service.dart、packages/novel_agent_core/lib/src/context/context_assembler_service.dart。只做 core 接线：建立 ProjectExpressionConstraintBindingResolverService、ExpressionConstraintBriefRenderer、ExpressionConstraintContextSectionService，让表达限制正式进入 creative rule stack 和上下文组装，但不要做持久化，不要做 UI。
```

---

## 7. Session EC-03：adapters 持久化与内置 preset 注册

### 本轮目标

把表达限制 profile 与项目级 binding 正式落盘，并注册第一批内置 preset。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/unified-de-ai-writing-scheme-2026-05-28.md`

### 必须完成

1. 建立 adapters 层仓储，例如：
   - `ExpressionConstraintProfileRepository`
   - `ProjectExpressionConstraintBindingRepository`
2. 建立 codec / path service
3. 固定项目级隐藏路径
4. 注册首批内置 preset，至少：
   - `de_ai`
   - `strict_pov_boundary`
   - `low_jargon_narration`

### 本轮不要做

- 不做 runtime prompt 接线
- 不做 UI
- 不把 preset 注册写回 app

### 本轮重点拆耦

- `profile repository`
- `binding repository`
- `builtin registry`

### 完成判定

- profile 与 binding 已可正式持久化
- 内置 `de_ai` 已只是内置 preset 之一
- 没有把持久化和解析塞进一个大 service

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-03 执行。先阅读 agent.md、本文件、docs/unified-de-ai-writing-scheme-2026-05-28.md。把表达限制系统正式落到 adapters：建立 ExpressionConstraintProfileRepository、ProjectExpressionConstraintBindingRepository、相关 codec/path service，并注册首批内置 preset，其中 de_ai 只是其中一个。不要做 UI，不要顺手接 prompt。
```

---

## 8. Session EC-04：运行时注入策略与 prompt 链接线

### 本轮目标

让启用中的表达限制在正确的生成链里稳定触发，但避免“所有轮次都拼长文”。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- 本文档
- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`
- `packages/novel_agent_core/lib/src/context/context_assembler_service.dart`

### 必须完成

1. 建立注入策略，例如：
   - `ExpressionConstraintInjectionPolicyService`
2. 明确哪些链路默认消费它：
   - 正文写作
   - 修订写作
   - 审稿后重写
3. 明确哪些链路不默认消费长限制文：
   - 普通闲聊
   - 工具参数确认
   - 非创作型问答
4. 固定形式：
   - 默认投短摘要
   - 需要时再投结构化 section

### 本轮不要做

- 不做 review 规则扩张
- 不做 UI
- 不新增更多 preset

### 本轮重点拆耦

- `injection policy`
- `creative-turn gating`
- `prompt-facing projection`

### 完成判定

- 表达限制能稳定触发
- 但不会演变成全时段硬拼 prompt
- 创作链与普通会话链仍边界清晰

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-04 执行。先阅读 agent.md、本文件、packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart、packages/novel_agent_core/lib/src/context/context_assembler_service.dart。把表达限制正式接到运行时创作链：建立 ExpressionConstraintInjectionPolicyService，让正文/修订生成稳定消费启用中的表达限制，但默认只注入短摘要，不要把长参考全文每轮硬拼进去，也不要做 UI。
```

---

## 9. Session EC-05：review / authenticity / continuity 联动

### 本轮目标

把表达限制中的“叙事一致性”和“后置真实性修订”接成正式联动。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- 本文档
- `builtin_packages/skills/novel-control-station/references/authenticity-and-de-ai-pass.md`
- 相关 continuity / review 服务

### 必须完成

1. 明确把下列问题提升为 review / continuity 检查项：
   - 视角泄漏
   - 信息边界混用
   - 说话风格漂移
   - 设定状态漂移
2. 让表达限制 profile 可影响：
   - authenticity pass 强度
   - review 提示重点
   - post-pass mini recheck
3. 保证：
   - 去 AI 风不会把人物声音洗平
   - 一致性问题不再被误当成单纯文风问题

### 本轮不要做

- 不开新大 UI
- 不继续扩 skill 系统
- 不开新导出主线

### 本轮重点拆耦

- `constraint-aware review hints`
- `authenticity pass bridge`
- `continuity check emphasis`

### 完成判定

- 表达限制系统已不只是 prompt 侧存在
- 审稿 / 修订 / 连续性检查已能正式感知它

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-05 执行。先阅读 agent.md、本文件、builtin_packages/skills/novel-control-station/references/authenticity-and-de-ai-pass.md，以及相关 review/continuity 服务。把表达限制正式接到 review / authenticity / continuity 链：尤其把视角泄漏、信息边界混用、说话风格漂移、设定状态漂移提升为正式检查重点，但不要做大 UI，不要顺手扩 skill 系统。
```

---

## 10. Session EC-06：app 最小编辑入口与总回归

### 本轮目标

最后再做用户入口，让这个系统“容易达到、可复用、稳定触发”。

### 预计改动量

- 约 `1100 ~ 1900` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/unified-de-ai-writing-scheme-2026-05-28.md`

### 必须完成

1. 在 app 端提供最小编辑入口：
   - 查看内置表达限制 preset
   - 项目级开关
   - 绑定到 agent / mode / stage
2. 明确 `de_ai` 只是内置 toggle 之一
3. 做总回归：
   - 不启用任何限制
   - 启用 `de_ai`
   - 启用其他内置 preset
   - 切项目不串 binding
4. 回填文档

### 本轮不要做

- 不做最终视觉大改
- 不做复杂筛选器设计器
- 不做自定义 DSL 编辑器

### 本轮重点拆耦

- `view data service`
- `binding action service`
- `probe / regression`

### 完成判定

- 用户已能稳定找到并打开这个入口
- `de_ai` 只是一个内置开关，不是唯一用途
- 文档状态与代码状态一致

### 建议提示词

```text
按 docs/expression-constraint-session-order.md 的 Session EC-06 执行。先阅读 agent.md、本文件、docs/unified-de-ai-writing-scheme-2026-05-28.md。最后只做表达限制系统的 app 最小入口与总回归：支持查看内置 preset、项目级开关、按 agent/mode/stage 绑定，并确认 de_ai 只是内置 toggle 之一。不要做大视觉重构，不要做复杂编辑器，完成后回填文档。
```

---

## 11. 当前推荐起点

最自然的起点是：

1. `Session EC-01`
2. `Session EC-02`

原因很直接：

- 现在最重要的是先把“可开关表达限制系统”从语义上立住
- 一旦直接去做 UI 或直接拼 prompt，很容易又回到临时规则堆叠
- 当前项目已经有：
  - `CreativeRuleStack`
  - `ProjectConstitution`
  - `StyleProfile / ProjectStyleBinding`

最适合先做“加一层正式表达限制系统”，而不是先去改技能系统或直接做大页面
