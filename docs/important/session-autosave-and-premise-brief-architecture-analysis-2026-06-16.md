# 会话自动落盘与前提入口文档架构分析（2026-06-16）

## 1. 这份文档要解决什么

这份文档聚焦两个表面上分离、实际上都属于“项目正式产物边界不清”的问题：

1. 为什么普通会话有时会把模型回复直接落成 `.md`。
2. 为什么项目里会长期存在 `premise/` 与 `premise/project_brief.md` 这样看起来不像正式创作资产的东西。

这不是修复记录，也不是任务顺序文档。它的目标是把这两个问题的真实职责边界讲清楚，避免后续继续在“兼容兜底”和“正式主链”之间摇摆。

---

## 2. 结论先行

本轮的总体判断很明确：

1. **正式正文交付主链应该是工具链，尤其是 `submit_chapter_delivery`，而不是 GUI 控制器根据回复内容猜测并自动落盘。**
2. **`autoSaveDrafts` 不是正确主链，而是历史兼容兜底。**
3. **`premise/` 目录本身合理，但 `premise/project_brief.md` 当前承担的是“快速入口/人类可读镜像”职责，而不是正式故事前提，因此它占据 `premise/` 门面位置是不够合理的。**
4. **这两个问题本质上都属于：正式项目资产、运行时兜底、用户入口文档三者没有被完全分层。**

换句话说，问题不是“有 bug 才会出现这些文件”，而是架构里确实还保留了一层过渡设计，只是现在已经开始伤害语义一致性和用户体验。

---

## 3. 当前事实源

### 3.1 正式章节交付主链是什么

从当前核心提示合同与工具策略来看，正式章节正文的主链已经不是自由文本落盘，而是：

1. 写作者产出正文。
2. 通过 `submit_chapter_delivery` 提交 `chapter_path`、`chapter_content`、`submission` 等正式交付信息。
3. 由领域工具统一处理正文、交付状态、连续性 sidecar、状态变化等持久化语义。

相关锚点：

1. [tool_strategy_prompt_builder.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/tools/tool_strategy_prompt_builder.dart)
2. [project_prompt_contract.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/project/project_prompt_contract.dart)
3. [submit_chapter_delivery_handler.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/tools/domain/submit_chapter_delivery_handler.dart)
4. [project_narrative_domain_tool_executor_test.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/test/project_narrative_domain_tool_executor_test.dart)

这条设计方向本身是对的，而且已经是项目当前更先进、更可靠的一条主线。

### 3.2 普通会话为什么仍会出现自动落盘

尽管正式主链已经转向 `submit_chapter_delivery`，GUI 普通会话里仍然保留了一层“如果模型没有调用工具，但输出很像正文，就帮它保存”的兜底逻辑。

相关锚点：

1. [workbench_conversation_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart)
2. [conversation_draft_autosave_policy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/conversation_draft_autosave_policy_service.dart)
3. [save_draft_use_case.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/use_cases/save_draft_use_case.dart)
4. [app_settings.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/settings/app_settings.dart)

也就是说：

1. `submit_chapter_delivery` 是正式交付链。
2. `autoSaveDrafts` 是控制器层的兼容兜底。

当前两者并存，这就是语义混乱的来源。

### 3.3 `premise/project_brief.md` 是谁生成、谁更新的

`premise/project_brief.md` 不是智能体自由演化出来的前提文档，而是系统在项目创建或项目基础信息更新时直接写入的。

相关锚点：

1. [markdown_project_readable_projection_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/storage/markdown_project_readable_projection_service.dart)
2. [sqlite_project_readable_projection_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_adapters/lib/src/storage/sqlite_project_readable_projection_service.dart)
3. [update_project_manifest_use_case.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/use_cases/update_project_manifest_use_case.dart)

它当前承担的更准确职责是：

1. 项目创建后的最小可读入口。
2. manifest 的人类可读镜像。
3. SQLite 项目只读投影入口的说明页。

所以用户会感觉它：

1. 内容很短。
2. 不像正式故事设定。
3. 变化时机不透明。
4. 像“系统写的说明页”，而不是“项目真正的前提资产”。

这个感觉是对的，因为它本来就更接近“说明页”。

---

## 4. 为什么当初会这样设计

## 4.1 自动落盘存在的历史合理性

从演化路径看，普通会话保留自动落盘兜底大概率有三个原因：

1. 早期工具调用稳定性不足，需要一个“别让长文本白生成”的保存后备。
2. 普通项目并不总是处于正式长任务语义中，用户可能只是想“先写一段，然后顺手留下来”。
3. GUI 在没有完整任务调度、正式交付、知识/状态回填都齐全之前，需要一条最低限度“有结果就别丢”的退路。

这在早期阶段是有现实价值的。

问题不在它曾经存在，而在于项目现在已经进入下一阶段：我们已经有了更正式的章节交付主链，这个兜底继续停留在正文主路径里，就会开始产生副作用。

## 4.2 `project_brief.md` 存在的历史合理性

这个文件最初存在，也并不是完全没有理由：

1. 新建项目后，不能只有一个 manifest 或空目录，否则用户和智能体都缺少一个最低限度的可读入口。
2. Markdown 项目需要一个“看得见、能打开、能让工作台先落脚”的文本入口。
3. SQLite 项目更需要一个“你虽然底层是 SQLite，但这里还有个可读入口”的提示页。

所以 `project_brief.md` 作为“入口说明页”是合理的。

问题在于它目前被放在 `premise/` 目录下，而且名字太像“正式故事前提”，结果导致：

1. 它实际是入口说明页。
2. 用户却会把它误认成正式前提文档。

这就是角色错位。

---

## 5. 当前设计为什么已经不再合理

## 5.1 自动落盘的问题不只是误写文件

如果自动落盘继续作为普通会话的一条正文兜底，它会带来五类结构性问题：

1. **正式性交付语义分裂**  
   一部分正文由 `submit_chapter_delivery` 收口，一部分正文由 GUI 控制器直接 `SaveDraftUseCase` 落盘。

2. **连续性与状态 sidecar 可能缺失**  
   直接保存 `.md` 不天然等于完成正式章节交付，因此可能缺少连续性 handoff、submission、状态变化等正式产物。

3. **用户无法判断“这是不是正式正文”**  
   同样是出现在 `chapters/` 里的文件，有的是领域工具交付结果，有的是控制器兜底保存结果。

4. **工具调用策略被削弱**  
   模型即便没有正确调用正式交付工具，也可能“看上去像成功了”，这会掩盖真实链路问题。

5. **后续测试与验收会继续失真**  
   用户看到文件出现，就以为链路对了；但实际上只是 fallback 接住了文本。

因此，这不只是一个“体验小问题”，而是正式产物边界被稀释的问题。

## 5.2 `premise/project_brief.md` 的问题不只是内容太短

`project_brief.md` 当前最大的问题，不是它短，而是它占据了不该由它占据的位置。

`premise/` 在项目语义里本应承载：

1. 长期有效的故事总前提。
2. 项目宪章或长期边界。
3. 真正应该被智能体反复引用的高优先级创作承诺。

但 `project_brief.md` 实际承载的是：

1. 项目类型。
2. 存储策略。
3. 一点点题材/设定/备注摘要。
4. SQLite 投影入口提示。

它更像：

1. quick overview
2. manifest mirror
3. onboarding stub

而不像：

1. project constitution
2. story premise
3. authoritative narrative contract

这会导致三个问题：

1. 用户误解它的权威性。
2. 智能体和系统都可能把它当作“可读入口”，从而放大一个本不够正式的文档的重要性。
3. 真正的前提资产反而被埋在 `premise/*.md`、`project_constitution.md`、模式引导产物或其他文档里，不够清晰。

---

## 6. `premise/` 本身该不该保留

应该保留。

这点需要和 `project_brief.md` 分开判断。

从目录语义来看，`premise/` 本身是合理的，而且与我们项目的长期方向一致：

1. 它可以承载一般写作项目的故事总前提。
2. 它可以承载长任务启动前的正式前提收束。
3. 它可以承载拆书后映射回项目的核心前提。
4. 它可以承载后续更正式的 `constitution`、长期边界、开局锚点、题材承诺等文档。

相关锚点：

1. [project_workspace_catalog.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart)
2. [mode_guidance_asset_bundle_builder_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/modes/mode_guidance_asset_bundle_builder_service.dart)
3. [book_deconstruction_target_path_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_target_path_service.dart)
4. [creative_rule_stack_resolver_service.dart](/d:/FlutterProjects/NovelAgentFlutter/packages/novel_agent_core/lib/src/creative/creative_rule_stack_resolver_service.dart)

所以：

1. `premise/` 不是问题。
2. `premise/` 下面“谁是正式文档，谁是入口说明页”才是问题。

---

## 7. 更合理的目标架构

## 7.1 正文写入与交付的目标状态

应该把“文本保存”和“正式章节交付”彻底分层。

### A. 正式章节

正式章节、连续章节、长任务章节：

1. 必须以 `submit_chapter_delivery` 为唯一正式出口。
2. 文件写入只是交付的一部分，不是交付本身。
3. 章节 sidecar、连续性 handoff、状态变化等都跟随正式交付链产生。

### B. 非正式文本

样章、场景、片段、试写、临时草稿：

1. 可以使用 `write_project_file` 或等价文件工具写入。
2. 不应冒充正式章节交付。

### C. GUI 会话保护

GUI 仍然可以保留“不要丢文本”的保护能力，但应改成：

1. 会话草稿缓存。
2. 显式“保存为草稿/场景/样章”。
3. 或单独的 recovery buffer。

而不是“猜这像正文，于是直接塞进项目正式目录”。

换句话说，**保留文本保护，不保留正文主链兜底。**

## 7.2 `premise/` 的目标状态

`premise/` 里应至少区分三类文档：

### A. 正式前提资产

例如：

1. `premise/project_constitution.md`
2. `premise/..._premise_1.md`
3. 拆书生成的 `premise/book_deconstruction_premise_*.md`

这些文档应被视为：

1. 可长期引用
2. 具备故事权威性
3. 可参与规则栈与上下文激活

### B. 项目快速概览

例如当前的 `project_brief.md`，但它不应继续伪装成“正式前提”。

更合理的选择是：

1. 改名成更明确的 `project_overview.md` 或类似名称；
2. 或保留文件但降级成辅助入口，不再作为 `premise/` 的事实门面；
3. 或对用户默认隐藏，只在需要时显示。

### C. SQLite 可读投影入口

SQLite 项目可以保留只读投影，但应明确：

1. 它是 projection，不是 source of truth。
2. 它是读取入口，不是创作主载体。

---

## 8. 这两类问题背后的统一根因

这两个问题能反复冒出来，是因为当前项目里还存在下面这类混合角色文件或链路：

1. **正式产物链**
2. **兼容兜底链**
3. **用户可读入口链**

它们还没有被彻底拆开。

自动落盘的问题，是“兼容兜底链”侵入了“正式正文产物链”。

`project_brief.md` 的问题，是“用户可读入口链”占据了“正式前提资产链”的门面位置。

所以这不是两个独立小 bug，而是一类架构债的不同表现。

---

## 9. 推荐的收口方向

本轮不直接展开任务顺序，但建议后续收口严格按下面顺序推进：

### 9.1 第一优先级：收缩 GUI 自动落盘语义

目标：

1. 普通会话不再把“像正文的回复”直接当正式章节保存。
2. 若保留自动保存，也只能进入会话草稿缓存或显式草稿区。
3. 正式章节必须通过 `submit_chapter_delivery` 收口。

### 9.2 第二优先级：给 `project_brief.md` 明确降级

目标：

1. 不再把它视作正式前提。
2. 明确它只是项目概览/入口说明。
3. 必要时改名或隐藏。

### 9.3 第三优先级：把正式前提资产扶正

目标：

1. 明确 `premise/` 下哪些是权威前提文档。
2. 让项目开局、长任务、拆书后续写、规则栈解析都优先消费这些正式资产，而不是轻量 brief。

### 9.4 第四优先级：统一“正式产物 vs 兼容缓存 vs 可读投影”标识

目标：

1. 用户一眼知道哪些文件是正式创作资产。
2. 哪些是系统投影。
3. 哪些是入口说明页。
4. 哪些是临时草稿或恢复缓存。

这一步对 GUI、CLI、后续 Docker 宿主都重要。

---

## 10. 最终判断

最终判断可以压缩成一句话：

**我们现在不是缺少正文写入能力，也不是缺少前提目录，而是缺少“什么才算正式项目资产”的最终单一语义。**

在正文侧：

1. `submit_chapter_delivery` 应该成为唯一正式章节出口。
2. `autoSaveDrafts` 应退回到缓存/草稿保护层。

在前提侧：

1. `premise/` 应保留并继续强化。
2. `project_brief.md` 应从“像正式前提”的位置退下去。
3. 真正的前提资产、宪章资产、拆书前提资产应被扶正为主入口。

只要这两块收口，项目在“正式产物边界”这条线上会清晰很多，后续很多体验问题、链路误解和测试失真问题都会一起下降。

---

## 11. 落实进展（2026-06-16）

截至当前这一轮，和本文直接对应的落地状态如下：

1. **普通会话 fallback 不再直接写正式项目文件。**  
   GUI 普通会话结果会进入当前文档草稿缓冲；CLI `workflow draft` 也不再因为兼容兜底把自由文本伪装成正式落盘。

2. **隐藏草稿恢复缓冲已接上。**  
   工作台快照会保存 dirty 文档的 recovery snapshot，重新打开项目时可恢复未正式保存内容，但不会伪造 `chapters/` 正式资产。

3. **`project_brief.md` 已降级，规范入口切到 `premise/project_overview.md`。**  
   旧路径仍做兼容识别，但 canonical path 已迁到 `project_overview.md`，并在项目加载时自动完成兼容迁移。

4. **`project_overview` 已从正式前提主入口退下。**  
   它默认隐藏、不计入正式 authored foundation、不参与常规上下文预算，正式前提/正式规划会优先于它被打开和消费。

5. **“正式资产 / 支撑概览 / SQLite 投影 / 草稿缓存”已经开始统一显示。**  
   当前已接上的用户可见面包括：
   - 文档标签 tooltip
   - 文档状态栏
   - 资源树二级标签、分类图标与短徽标
   - 辅助面板中的当前文档身份与状态

6. **`autoSaveDrafts` 的用户可见语义已开始收口。**  
   持久化键仍保持 `auto_save_drafts` 兼容，但 GUI 设置页和 CLI 配置入口已经开始以“普通会话草稿保护 / draft fallback protection”这一层语义暴露，而不再把它误说成正式自动保存。

7. **旧 `project_brief` 路径对工作台恢复链的污染已开始收口。**  
   settings 中的 `workbench_state.active_document_path`、`draft_recoveries.relative_path` 会在加载/保存时归一到 canonical `premise/project_overview.md`；工作台恢复和上下文焦点路径也会按同一套规则归一，避免旧 snapshot 再把用户拉回 legacy brief 入口。

8. **正式资产身份分类已抽到 core，GUI / CLI 开始共用。**  
   目前已经有一层宿主无关的 `ProjectArtifactIdentityService` 负责判断“支撑概览 / SQLite 投影 / 正式前提 / 正式规划 / 正式正文 / 样章 / 场景片段 / 正式资产 / 分析资料”等路径身份；工作台身份标签与资源树说明已改为委托这层纯服务，CLI 的 `workflow` / `project` / `approval` / `asset` / `review` / `template` 主链输出也会在路径后补充对应身份标签，而不是继续只打印裸路径。

9. **当前结论：这份分析对应的现有宿主收口已经完成。**
   - `AppSettings` 的核心语义字段已经扶正为 `draftFallbackProtectionEnabled`，`autoSaveDrafts` 只保留为兼容别名。
   - 现有 GUI 与 CLI 主链已经共用同一套“正式资产 vs 缓冲/投影”身份合同。
   - `project_brief` 兼容入口、`draft_fallback_protection`/`auto_save_drafts` 兼容键、以及未来 Docker 宿主的复用，都属于兼容或未来扩展问题，不再构成这份分析范围内的未收口主项。
