# NovelAgentFlutter 面向用户的开发遗留收口任务顺序文档

最后更新：2026-06-16

主线代号：`UFDL`（User-Facing Development Leftovers）

关联主要分析文档：

- `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`

关联历史任务顺序文档：

- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`
- `docs/frontend-evolution-session-order.md`
- `docs/ui-simplification-session-order-2026-05-28.md`

关联项目约束：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`

关联代码锚点：

- `apps/novel_agent_app/android/app/build.gradle.kts`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/settings/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/agent_ecosystem/`
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`

---

## 1. 这份文档解决什么

这份文档只解决一件事：

**把仍然像开发过程遗留、会直接伤害用户体验、产品完成度和发布可信度的外露问题，收成一条可连续执行的收口主线。**

它不继续扩展大架构，也不去重做长任务/拆书/知识库主能力；它只针对已经被审计确认的用户面问题：

1. 正式入口还会暴露“未接入”“未完成”“当前构建不支持”。
2. 设置页和部分工作台区域仍像开发后台，而不是正式产品。
3. 一些半成品壳、占位块、伪状态说明仍直接暴露给用户。
4. Android release 基础配置仍停留在示例/调试态。

完成本主线后，项目至少要达到：

1. 用户不再从正式入口撞到“宿主未接线”式提示。
2. 设置页默认不再暴露开发/兼容/宿主内部语义。
3. 主题、拆书、技能装载等用户面不再出现“预留”“后续”“空分组”“伪状态”。
4. Android release 至少具备正式包名和正式签名入口，不再是示例构建伪装成发布构建。

---

## 2. 与旧文档的关系

### 2.1 这是发布收口支线，不是新架构主线

这条主线建立在既有系统已经能跑起来的前提上，不再重做：

1. 开局统一主线。
2. 长任务/普通任务调度主线。
3. 拆书与导入的主体能力。
4. SQLite/Markdown 类型矩阵主线。

它解决的是这些主线落到用户面后，仍残留的“半成品外露”问题。

### 2.2 它与 `RRP` 主线的关系

`RRP` 更关注“可发布的大盘收口”，而本主线更聚焦：

1. 正式入口暴露策略。
2. 设置页和工作台的用户口径。
3. 占位/伪状态/未接线能力的最终清扫。
4. release 基础构建信息。

可以把它视为一条更窄但更贴近用户体感的发布补收口。

### 2.3 本文档不做什么

1. 不把长任务稳定性、拆书深层能力、知识库体系重新拉进来。
2. 不新造一套 diagnostics runtime。
3. 不把 debug-only 或 internal-only 信息改成另一套对外大面板。
4. 不为了解决文案问题，把业务判断堆回 widget/controller。

---

## 3. 已有实现去重审计

### 3.1 已有能力，不重做

1. 设置页已有分 tab 的正式结构。
2. 主题切换已有正式注册表与 view data service。
3. 拆书后续路线已有 route/plan/derived project 基础。
4. 项目类型转换已有正式流程和视图入口。
5. 长任务启动已有正式工具名与上层执行链。
6. 技能装载已有 resolver、workspace snapshot、detail view data 基础。

### 3.2 已有但外露方式不正确

1. 功能入口已经存在，但在宿主未接线时仍直接向用户报内部缺线。
2. 设置页能工作，但暴露了 `开发`、`兼容桥`、内部类名、宿主路径等信息。
3. 主题页、拆书预览页、技能装载页已有页面，但仍含占位块或伪状态。
4. Android 能构建 release，但仍是默认示例包名和 debug signing。

### 3.3 真正要补的层

这一轮真正要补的是：

1. **功能可用性暴露合同**：用户能不能看到某入口、看到后是可执行还是禁用说明。
2. **设置页信息架构**：正式设置 vs 诊断/兼容/内部信息。
3. **用户口径投影层**：把内部术语、兼容字段、宿主细节挡在投影层后面。
4. **半成品壳清扫层**：空分组、占位卡、伪状态摘要、未来计划块。
5. **发布基础构建层**：applicationId、release signing、最小发布检查。

---

## 4. 本轮冻结的架构边界

1. 正式入口的“是否可见/是否可执行/如何提示”必须有统一策略，不允许继续在多个 controller 里各自写 null-check 文案。
2. 开发信息、宿主路径、兼容字段、内部类名不应出现在默认用户路径中。
3. 若某能力当前未正式完成，应优先隐藏或前置禁用，不允许把“未接入”暴露为正常点击结果。
4. 不新建巨型“诊断中心”；若需要保留诊断信息，只能通过轻量、明确的次级入口暴露。
5. 不为文案清理而重写业务核心，不把逻辑从 service 拉回 widget。
6. 不在 UI 中硬编码更多 feature truth；能落服务就落服务。
7. 单文件若继续增长，应优先拆 service / projection / policy，不接受继续把这轮收口堆进 `AppShellController`。

---

## 5. 目标终态

本主线完成后，应达到以下终态：

1. Android release 配置不再是示例值和 debug signing。
2. 长任务启动、拆书派生项目创建、项目类型转换等正式入口，在 GUI 中不会再向用户回吐“未接入执行链”。
3. 设置页主路径只保留正式用户需要的设置项。
4. 开发/诊断/兼容信息若保留，必须通过单独且克制的方式暴露。
5. 主题页不再出现“后续内置主题”“用户自定义预留”这类占位块。
6. 拆书页不再展示空分组占位文案。
7. 技能装载页不再展示伪状态式说明。
8. 对用户可见的文案扫描与 widget/viewmodel regression 能防止这些遗留问题回潮。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `8` 个 session。

顺序设计如下：

1. `UFDL-01 ~ UFDL-02`：先冻结并落地“正式入口可用性暴露合同”，避免只是删文案不修结构。
2. `UFDL-03`：单独收 Android release 基础配置，这一块独立且高优先级。
3. `UFDL-04 ~ UFDL-05`：收设置页和工作台的用户口径，把内部/兼容语义挡在投影层后。
4. `UFDL-06`：清理半成品壳，包括主题页、拆书页、技能装载页、opening 状态块。
5. `UFDL-07`：做“用户可见开发遗留扫描”的回归保护，防止类似问题再漏出。
6. `UFDL-08`：最终做发布向回归、打包烟测与收口记录。

这样安排是为了保证 mini 不会一上来就四处改文案，而是先把“什么该显示、什么不该显示、显示失败时如何优雅降级”的结构收正。

### 6.1 设计目标覆盖矩阵

1. 正式入口不再暴露“未接入”：
   - `UFDL-01`
   - `UFDL-02`
   - `UFDL-08`

2. Android release 基础发布可信度：
   - `UFDL-03`
   - `UFDL-08`

3. 设置页去开发后台化：
   - `UFDL-04`
   - `UFDL-05`
   - `UFDL-07`

4. 占位块/伪状态/空分组清理：
   - `UFDL-06`
   - `UFDL-07`

5. 回归防线与最终验收：
   - `UFDL-07`
   - `UFDL-08`

---

## 7. Session 设计

## UFDL-01 正式入口可用性暴露合同冻结

- 本轮目标：
  冻结一套正式入口可用性暴露合同，统一回答“该入口是否可见、可执行、禁用时显示什么用户口径”，避免 controller 各自写 `未接入` 文案。
- 层级归属：
  `App / application service`
- 必读文件：
  - `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`
  - `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- 必须完成：
  1. 设计一个共享的 feature availability / entry availability policy 或 projection contract。
  2. 明确入口状态至少区分：`hidden`、`disabled_with_user_reason`、`available`。
  3. 明确哪些原因属于用户可见原因，哪些只允许进日志/诊断。
  4. 补 focused tests，证明这套合同能覆盖长任务启动、拆书派生、项目类型转换三类入口。
- 本轮不要做：
  1. 不直接改所有页面文案。
  2. 不处理 Android build。
  3. 不顺手重构大控制器。
- 验收标准：
  1. 有稳定的入口可用性合同和 focused tests。
  2. 后续 session 可以只消费这套合同，而不是继续写散装判断。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-01`。只做“正式入口可用性暴露合同冻结”，落在 app/application service 层；统一定义入口的 hidden / disabled_with_user_reason / available 语义，并覆盖长任务启动、拆书派生项目创建、项目类型转换三类入口。不要改 Android build，不要大改 UI，不要开启下一任务。必须解耦合、单一职责、避免把判断塞回 controller，并补 focused tests。
```

## UFDL-02 正式入口接线收口

- 本轮目标：
  把 `UFDL-01` 的合同真正接到正式入口，清掉直接对用户展示的“未接入执行链/宿主未接线”。
- 层级归属：
  `App / workflow entry wiring`
- 必读文件：
  - `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/presentation/`
  - `apps/novel_agent_app/lib/features/workbench/presentation/`
- 必须完成：
  1. 长任务启动入口改为消费 availability contract，不再直接向用户回吐 `当前宿主尚未接入长任务启动执行器`。
  2. 拆书派生项目创建入口改为前置隐藏/禁用或正式接线，不再把 `当前宿主还未接入派生项目创建能力` 当成用户提示。
  3. 项目类型转换入口改为前置禁用/隐藏或正式接线，不再让用户点到最后才看到 `当前构建未接入项目类型转换执行链`。
  4. widget/viewmodel 测试覆盖以上三个入口。
- 本轮不要做：
  1. 不处理设置页。
  2. 不处理主题占位。
  3. 不动 Android release 配置。
- 验收标准：
  1. 用户无法再通过正式 GUI 路径撞到上述三条“未接入”文案。
  2. 对应入口的禁用态或隐藏态是统一、可解释的。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-02`。只做正式入口接线收口：让长任务启动、拆书派生项目创建、项目类型转换都消费 `UFDL-01` 的 availability contract，清掉直接暴露给用户的“未接入执行链/能力”提示。不要碰设置页、不要改 Android build、不要开启下一任务。保持改动集中在入口策略、projection 和 focused widget/viewmodel tests。
```

## UFDL-03 Android release 基础配置收口

- 本轮目标：
  把 Android release 从“示例工程构建”收成“至少具备正式发布基础”的状态。
- 层级归属：
  `Packaging / Android build`
- 必读文件：
  - `apps/novel_agent_app/android/app/build.gradle.kts`
  - 现有发布/打包相关文档
  - 可能存在的本地签名说明或忽略规则
- 必须完成：
  1. 把 `applicationId` 从 `com.example.novel_agent_app` 收成正式值。
  2. 把 release signing 从 debug signing 收成正式 signingConfig 入口。
  3. 若正式 keystore 不能入仓库，至少把配置方式、环境变量/本地属性读取方式、缺省失败口径收好。
  4. 补最小构建验证或文档化验证步骤。
- 本轮不要做：
  1. 不修改业务逻辑。
  2. 不把签名秘密写入仓库。
  3. 不顺手做 UI 收口。
- 验收标准：
  1. release 不再直接引用 debug signing。
  2. 包名不再是示例值。
  3. 配置方式清楚，且不会把私密信息提交进仓库。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-03`。只收 Android release 基础配置：正式 applicationId、正式 release signing 入口、私密信息不入仓库的配置方式，以及最小构建验证。不要改业务逻辑，不要碰设置页，不要开启下一任务。注意安全、解耦和仓库整洁。
```

## UFDL-04 设置页信息架构收口

- 本轮目标：
  把设置页从“开发后台感”收回正式产品信息架构。
- 层级归属：
  `App / settings projection`
- 必读文件：
  - `apps/novel_agent_app/lib/features/settings/presentation/models/settings_view_data.dart`
  - `apps/novel_agent_app/lib/features/settings/presentation/pages/settings_page.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/development_settings_panel.dart`
- 必须完成：
  1. 把 `开发` 标签从普通用户设置主路径移除，或转到明确的诊断次级入口。
  2. 默认用户路径不再直接展示设置根目录、搜索根目录、默认项目根等宿主路径。
  3. 清掉设置概览里直接暴露的内部类名与宿主实现名，例如 `ProjectWorkspacePort`、`ToolExecutionService / ProjectToolDispatcher`。
  4. 补 focused widget/viewmodel tests，确保主设置 tab 集合符合新策略。
- 本轮不要做：
  1. 不处理兼容桥字段本身。
  2. 不处理主题占位块。
  3. 不做新的大型 diagnostics 页面。
- 验收标准：
  1. 普通用户进入设置页时，看不到 `开发` tab 和宿主内部名词。
  2. 若保留诊断能力，其入口是克制且次级的。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-04`。只做设置页信息架构收口：把 `开发` 标签和宿主路径/内部类名从普通用户路径移出，必要时用轻量诊断次级入口承接。不要处理主题占位，不改 Android build，不开启下一任务。必须把判断放在 settings projection/service 层，而不是散落到 widget。
```

## UFDL-05 兼容/内部术语用户口径投影清理

- 本轮目标：
  清理设置页和工作台中仍然外露的兼容/内部术语，让用户只看到正式概念。
- 层级归属：
  `App / projection / copy policy`
- 必读文件：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_advanced_panel.dart`
  - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_session_panel.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- 必须完成：
  1. 把 `高级兼容桥`、`压缩阈值百分比（兼容桥）`、`兼容上下文长度` 等直接对用户的说法收成正式用户术语。
  2. 让旧字段若仍必须存在，只通过内部投影或更克制的高级/迁移口径出现。
  3. 清理 `暂未返回额外适配信息` 这类明显内部态口径，改成自然的用户说明或直接不显示。
  4. 补 focused widget tests 或 golden-like 文案断言，防止这些术语回流。
- 本轮不要做：
  1. 不改真正的兼容字段存储结构。
  2. 不扩大到所有项目文案。
  3. 不顺手做主题页。
- 验收标准：
  1. 默认设置与 opening 路径不再直接出现“兼容桥/兼容上下文长度/适配信息未返回”等内部味很重的文案。
  2. 老字段仍能被系统内部消费，不因改文案而破坏兼容。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-05`。只做兼容/内部术语用户口径投影清理：把设置页和 opening 状态区里外露的 `兼容桥`、`兼容上下文长度`、`暂未返回额外适配信息` 等内部口径收掉，但不要改底层兼容字段结构，不开启下一任务。要把改动放在 projection/copy policy/widget 轻层，不制造新业务中心，并补 focused tests。
```

## UFDL-06 半成品壳与伪状态清扫

- 本轮目标：
  一次性清掉这轮审计里最明显的占位块、空分组和伪状态说明。
- 层级归属：
  `App / presentation polish`
- 必读文件：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/theme_settings_panel.dart`
  - `apps/novel_agent_app/lib/features/settings/application/services/theme_settings_view_data_service.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`
  - `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`
- 必须完成：
  1. 主题页移除或隐藏 `后续内置主题`、`自定义主题`、`注册表扩展位`、`用户自定义预留` 这类占位块。
  2. 拆书预览页不再渲染空分组占位文案；无路线时改为更自然的用户结果导向表达，或直接不显示。
  3. 技能装载页把那段伪状态式表达限制摘要改成真正的静态说明，或改成读取真实状态；不能继续保持“像状态但不是状态”。
  4. 补 focused widget/viewmodel tests。
- 本轮不要做：
  1. 不新增自定义主题功能。
  2. 不扩写拆书新路线。
  3. 不改技能装载核心解析逻辑。
- 验收标准：
  1. 以上三个区域不再向用户显示明显的占位感或伪状态感。
  2. 对应功能现有主行为不退化。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-06`。只做半成品壳与伪状态清扫：清掉主题页占位块、拆书预览空分组占位、技能装载页伪状态说明。不要顺手加新功能，不改核心解析，不开启下一任务。保持改动集中在 view data / presentation / focused tests。
```

## UFDL-07 用户可见开发遗留回归防线

- 本轮目标：
  建一层轻量但有效的回归防线，避免“未接入/预留/兼容桥/开发/内部类名”再次漏回用户面。
- 层级归属：
  `Probe / regression / app tests`
- 必读文件：
  - `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`
  - 本主线已改的 settings/workbench/book_deconstruction/agent_ecosystem 相关文件
  - 现有 widget/viewmodel regression tests
- 必须完成：
  1. 新增或补齐一组 focused regression tests，覆盖：
     - 设置页主路径不出现 `开发`
     - 用户主路径不出现 `兼容桥`
     - 正式入口不再出现 `未接入`
     - 设置页不出现内部类名
     - 主题页/拆书页/技能装载页不出现本轮清理的占位/伪状态文案
  2. 若需要，可补一个轻量文本扫描测试，但只扫生产用户可见 view data / widget 栈，不扫整个仓库。
  3. 记录哪些词是“允许存在于内部代码但不允许出现在用户面”的黑名单。
- 本轮不要做：
  1. 不写大而全的仓库 grep 脚本当业务标准。
  2. 不把 probe 变成第二套 UI 判定中心。
  3. 不扩写新的功能。
- 验收标准：
  1. 有一套稳定回归，能直接阻止这轮同类问题回潮。
  2. 测试只约束用户面，不误伤内部实现。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-07`。只做用户可见开发遗留回归防线：补 focused regression tests，确保设置页主路径不出现 `开发`、`兼容桥`、内部类名，正式入口不再出现 `未接入`，主题/拆书/技能装载页不再出现本轮清理的占位/伪状态文案。不要写大而全的仓库脚本，不开启下一任务。
```

## UFDL-08 最终验收、打包烟测与收口记录

- 本轮目标：
  把这条主线做最终验收，并留下可交接的收口记录。
- 层级归属：
  `Documentation / release validation`
- 必读文件：
  - `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`
  - `docs/user-facing-development-leftovers-session-order-2026-06-16.md`
  - `apps/novel_agent_app/android/app/build.gradle.kts`
  - 本主线相关测试与构建脚本
- 必须完成：
  1. 运行本主线相关 focused tests。
  2. 至少做一次与本主线相关的 GUI 构建/烟测或最小打包验证。
  3. 生成最终 closeout 文档，说明：
     - 哪些问题已收掉；
     - 哪些入口已不再外露内部态；
     - Android release 基础是否已符合预期；
     - 还有哪些残留不在本主线范围内。
  4. 更新本顺序文档的完成记录。
- 本轮不要做：
  1. 不再开启新功能。
  2. 不借机扩展其他主线。
  3. 不把未完成的大问题伪装成“已解决”。
- 验收标准：
  1. 有明确 closeout 文档。
  2. 本主线的核心问题都能被测试或验证证据覆盖。
  3. 结论诚实，不夸大完成度。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 执行 `UFDL-08`。只做最终验收、打包烟测与收口记录：运行本主线相关 focused tests，做最小 GUI/打包烟测，输出 closeout 文档并回写 session 完成记录。不要扩展其他主线，不开启新功能，不把未完成问题伪装成已解决。
```

---

## 8. 总启动提示词

下面这段提示词用于直接启动目标模式，让 `gpt-5.4-mini` 按顺序连续完成全部 session：

```text
根据 `docs/user-facing-development-leftovers-session-order-2026-06-16.md` 连续执行 `UFDL` 主线，从 `UFDL-01` 开始，完成一个 session 后再进入下一个，直到 `UFDL-08` 全部完成。

执行规则：

1. 每一轮只做当前 session，完成后更新本任务顺序文档里的完成记录，再进入下一 session。
2. 必须先读：
   - `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`
   - `docs/user-facing-development-leftovers-session-order-2026-06-16.md`
   - `agent.md`
3. 严格遵守本顺序文档的层级边界、`本轮不要做` 和验收标准。
4. 不要为了快，在 UI/widget/controller 里硬塞业务判断；优先落 service / policy / projection / contract。
5. 不要复制已有实现，不要新造平行 runtime，不要把 probe/fallback/bridge 代码变成新的业务中心。
6. 不要让单一文件继续无节制膨胀；接近分层警戒线时先拆职责再继续。
7. 每个 session 都要补 focused test / contract test / widget-viewmodel regression 中最合适的那一层，而不是只改代码不验收。
8. 如果发现当前 session 依赖的文件正被其他未收口任务真实修改，并且继续改会造成冲突，先停止在当前 session，写清阻塞文件、阻塞原因和建议恢复点；不要跨过去偷做后续 session。
9. 如果 session 内遇到“入口看起来是正式功能、但宿主没接线”的情况，优先按文档要求做：隐藏、禁用或正式接线，不能把“未接入”继续留给用户。
10. 完成全部 session 后，再输出最终 closeout，不要在中途提前宣布主线完成。
```

---

## 9. 完成记录占位

### UFDL-01 完成记录

- 状态：已完成
- 完成时间：2026-06-16 21:15:06
- 主要改动：新增共享 `EntryAvailabilityDecision` / `EntryAvailabilityPolicyService`，把长任务启动、拆书派生项目创建、项目类型转换三类正式入口统一收口为 `hidden` / `disabled_with_user_reason` / `available` 决策合同，并把用户理由和诊断理由分离。
- 验证命令：`flutter test test/entry_availability_policy_service_test.dart`
- 验证结果：通过。新增 contract test 覆盖宿主未接线隐藏、用户条件不足禁用、条件齐备可用，以及入口不适用时隐藏而不是伪禁用。
- 剩余风险：现有 controller / dispatcher 仍未消费新合同，后续 session 需要继续接线收口。
- 下一步：进入 `UFDL-02`，把这套合同接到正式入口，清掉用户可见的“未接入执行链/能力”提示。

### UFDL-02 完成记录

- 状态：已完成
- 完成时间：2026-06-16 21:50:04
- 主要改动：把项目类型转换入口的可见性收口到共享 `EntryAvailabilityDecision`，由 workbench 侧在项目面板中前置隐藏宿主未接线入口；同时清掉工作台控制器里旧的“当前构建未接入项目类型转换执行链”回退文案，并把长任务启动的未接线结果统一成泛化不可用投影，拆书派生项目创建继续保持禁用态且不回吐未接入文案。
- 验证命令：`flutter test test/entry_availability_policy_service_test.dart test/book_deconstruction_controller_test.dart test/workbench_project_panel_action_policy_service_test.dart test/workbench_workspace_shell_view_data_service_test.dart`；`flutter test test/workbench_project_panel_test.dart`；`dart test test/project_tool_dispatcher_path_test.dart`
- 验证结果：通过。项目类型转换入口在宿主未接线时会前置隐藏，长任务启动返回泛化不可用结果且携带 `entry_availability` 投影，拆书派生项目创建保持禁用态，工作台项目面板 widget 与 view-model 回归均通过。
- 剩余风险：`loadProject` 失败态仍沿用现有工作台清空策略，本轮未扩展到其他设置/主题/Android 入口。
- 下一步：进入 `UFDL-03`，只收 Android release 基础配置。

### UFDL-03 完成记录

- 状态：已完成
- 完成时间：2026-06-16 21:50:04
- 主要改动：把 Android release 的 `namespace` / `applicationId` 从示例值收成 `com.novelagent.app`，把 release signing 从 debug keystore 收口到 `android/local.properties` 或环境变量驱动的正式 signingConfig，并在缺少配置时用显式错误中止 release 构建；同时补了最小的 release signing 说明文档。
- 验证命令：`flutter build apk --release --no-pub`
- 验证结果：按预期失败，且错误信息明确指向未配置的 release signing 输入，不再落到 debug signing fallback。
- 剩余风险：正式 keystore、密码与别名仍需在本地或 CI 中按文档提供，本轮不把秘密写入仓库。
- 下一步：进入 `UFDL-04`，收设置页信息架构。

### UFDL-04 完成记录

- 状态：已完成
- 完成时间：2026-06-16 22:08:41
- 主要改动：把设置页普通用户路径里的宿主根目录投影从 `context` 概览移除，收窄了 `permissions` 段的描述口径，保留的设置标签仅剩正式用户可见的 `interfaces / models / permissions / tooling / network / context / theme`；同时新增一条 app shell settings projection 回归，确认默认活跃 tab 仍是 `interfaces`，且设置页投影不再回吐 `dev`、`ProjectWorkspacePort`、`ToolExecutionService`、`ProjectToolDispatcher`、`settingsRootPath`、`settingsSearchRoots`、`defaultProjectsRootPath` 等用户可见残留。
- 验证命令：`flutter test test/settings_page_projection_regression_test.dart test/theme_settings_panel_test.dart`；`flutter test test/widget_test.dart`
- 验证结果：设置投影回归与主题页回归通过；`widget_test.dart` 里的 app shell smoke 仍有一个既有期望失败，`正文工作区` 未出现，和本轮设置页收口本身无关。
- 剩余风险：`settingsRootPath` / `settingsSearchRoots` / `defaultProjectsRootPath` 这类宿主字段仍保留在 view data 传递链上，当前仅确保普通用户路径不再直接展示；若后续需要更强隔离，可以再把它们下沉到独立诊断投影。
- 下一步：进入 `UFDL-05`，继续清理兼容/内部术语用户口径。

### UFDL-05 完成记录

- 状态：已完成
- 完成时间：2026-06-16 22:12:17
- 主要改动：把设置页和 opening 路径里偏内部口吻的术语收成更正式的用户词面：上下文设置折叠区改为 `历史上下文参数 / 历史上下文字段`，`压缩阈值百分比（兼容桥）` 改为 `压缩阈值百分比`，模型高级设置里的 `兼容上下文长度` 改为 `上下文窗口长度`，opening 空态摘要改为 `暂无更多说明`；同步把相关 app shell 投影与测试断言更新到新口径。
- 验证命令：`flutter test test/context_settings_panel_test.dart test/model_settings_panel_test.dart test/opening_session_panel_test.dart`
- 验证结果：通过。上下文设置、模型高级设置和 opening 空态的回归测试都已按新用户口径稳定通过。
- 剩余风险：底层兼容字段仍然保留在 storage / normalization 链路中，当前只收口了用户可见口径；若后续要继续收紧，还可以再单独整理底层兼容投影。
- 下一步：进入 `UFDL-06`，清理主题、拆书预览和技能装载里的半成品壳与伪状态。

### UFDL-06 完成记录

- 状态：已完成
- 完成时间：2026-06-16 22:18:40
- 主要改动：主题设置页只保留内置主题块和保存动作，移除了 `后续内置主题 / 自定义主题 / 注册表扩展位 / 用户自定义预留` 这些占位卡；主题视图数据服务改成更克制的补充描述；拆书预览页把空分组文案改成 `当前暂无可用路线。`；技能装载页把伪状态式表达限制摘要改成纯说明 `表达限制由项目级约束系统统一管理；这里仅展示当前技能装载。`
- 验证命令：`flutter test test/theme_settings_panel_test.dart test/theme_settings_view_data_service_test.dart test/book_deconstruction_preview_panel_test.dart test/project_skill_loadout_view_data_service_test.dart`
- 验证结果：通过。主题设置、主题视图数据、拆书预览空分组、技能装载摘要都已按新口径稳定通过回归。
- 剩余风险：theme view data 仍保留未来/自定义描述字段用于投影兼容，但默认 UI 已不再渲染占位壳；若后续想彻底瘦身，可再收紧 view data 结构。
- 下一步：进入 `UFDL-07`，建立用户可见开发遗留回归防线。

### UFDL-07 完成记录

- 状态：已完成
- 完成时间：2026-06-16 22:21:42
- 主要改动：新增 `user_facing_development_leftovers_regression_test.dart`，把这轮黑名单词汇集中记录并扫描到设置投影、主题/技能/开局空态、拆书预览空分组等用户可见输出；回归里明确约束 `开发 / 兼容桥 / ProjectWorkspacePort / ToolExecutionService / ProjectToolDispatcher / 后续内置主题 / 注册表扩展位 / 用户自定义预留 / 当前保留为空分组 / 暂未返回额外适配信息 / 表达规则：已应用` 等词不得再出现在正式用户面。
- 验证命令：`flutter test test/user_facing_development_leftovers_regression_test.dart`
- 验证结果：通过。黑名单回归能同时锁住 settings、theme、opening、book preview 与 skill loadout 的用户面投影。
- 剩余风险：黑名单只覆盖当前这轮审计确认的用户面残留；若后续又引入新壳或新诊断口径，仍需要在这条回归里继续补词。
- 下一步：进入 `UFDL-08`，做最终验收、打包烟测与收口记录。

### UFDL-08 完成记录

- 状态：已完成
- 完成时间：2026-06-16 22:22:41
- 主要改动：补齐最终黑名单回归与收口文档，确认 settings / theme / opening / book preview / skill loadout 这些用户面不再回吐本轮清理的开发遗留词；同时做了一次 release APK 打包烟测，验证 Android release 仍能在缺少签名秘密时明确失败而不是回退到 debug 签名。
- 验证命令：`flutter test test/user_facing_development_leftovers_regression_test.dart`；`flutter build apk --release --no-pub`
- 验证结果：黑名单回归通过；release 打包按预期失败并明确提示缺少 `android/local.properties` / 环境变量中的 signing 配置。
- 剩余风险：`flutter test test/widget_test.dart` 仍有一个既有 smoke 期望失败，`正文工作区` 当前未出现；它不属于本主线的收口范围，后续若需要可单独跟进。
- 下一步：主线收口完成，进入最终 closeout 文档整理。
