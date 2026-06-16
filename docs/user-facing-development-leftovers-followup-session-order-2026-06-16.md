# NovelAgentFlutter 面向用户开发遗留补收口任务顺序文档

最后更新：2026-06-16

主线代号：`UFDL-FU`（User-Facing Development Leftovers Follow-up）

关联主要分析文档：

- `docs/important/user-facing-development-leftovers-followup-audit-2026-06-16.md`
- `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`

关联历史任务顺序文档：

- `docs/user-facing-development-leftovers-session-order-2026-06-16.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`

关联项目约束：

- `agent.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`

关联代码锚点：

- `apps/novel_agent_app/lib/features/settings/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

---

## 1. 这份文档解决什么

这份文档只解决一层很薄但值得收掉的东西：

**用户面已经没有大块开发遗留了，但仍残留少量工程味、内部味、过渡味的话术。**

它不再处理：

1. 长任务稳定性。
2. 拆书主链能力。
3. Android 正式签名实配。
4. 新功能开发。

它只收下面几类小尾巴：

1. 设置页剩余的工程词面，比如 `预留输出 token`、`优先 exact count`。
2. 权限页/工具策略页直接使用“宿主”这种偏实现术语。
3. 工作台对用户说“后续会接独立用例”这类施工中话术。
4. 拆书页残留的 `information GUI`、`资料桥`、`工程菜单` 这类内部称呼。

---

## 2. 与上一轮主线的关系

### 2.1 这是 `UFDL` 的补收口，不是新主线

`docs/user-facing-development-leftovers-session-order-2026-06-16.md` 已经收掉了：

1. 正式入口 `未接入执行链`。
2. 设置页 `开发` tab 与宿主根路径暴露。
3. 主题页占位块。
4. 拆书空分组占位。
5. 技能装载伪状态摘要。
6. Android release debug signing fallback。

这份 follow-up 文档不重复那些任务，只做更细的产品语言 polish。

### 2.2 本文档不做什么

1. 不做大规模重构。
2. 不把注释里的“后续/宿主/兼容”当问题处理。
3. 不因为文案 polish 去改 core 业务合同。
4. 不开启新的 diagnostics 页面或设置分区。

---

## 3. 已有实现去重审计

### 3.1 已经收好的，不重做

1. `开发` 标签已从普通设置主路径移除。
2. `兼容桥`、`兼容上下文长度` 这类大块用户面术语已经收过一轮。
3. 主题页大占位块已移除。
4. 拆书空分组占位和技能装载伪状态已处理。
5. Android release 包名与 signing 入口已经收好。

### 3.2 这轮真正要补的

1. 更自然的字段名与说明文案。
2. 更少的内部模块称呼。
3. 更少的“将来会做什么”的提示。
4. 一轮更细的黑名单回归。

---

## 4. 本轮冻结的架构边界

1. 只改用户面投影、view data、widget 文案、轻量 policy。
2. 不改底层兼容字段存储结构。
3. 不改 long task / book deconstruction / workflow 核心合同。
4. 不为了 polish 把业务判断搬回 widget/controller。
5. 不扩大到 CLI。

---

## 5. 目标终态

完成后，用户面应进一步达到：

1. 设置页不再像工程配置面板。
2. 权限与工具策略页用用户能自然理解的语言，而不是实现语言。
3. 工作台和拆书路径不再向用户泄漏“未来再接”“information GUI”这类内部表述。
4. 回归测试能锁住这批新清理的词。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `4` 个 session。

顺序如下：

1. `UFDL-FU-01`：先收设置页剩余工程味词面。
2. `UFDL-FU-02`：再收权限页/工具策略页/工作台的内部实现口吻。
3. `UFDL-FU-03`：收拆书页和相关 view data 的内部称呼与过渡话术。
4. `UFDL-FU-04`：补回归、做最小验收和 closeout。

这样做的好处是 mini 不会一股脑全局替换字符串，而是按页面域一块一块收。

---

## 7. Session 设计

## UFDL-FU-01 设置页工程词面 polish

- 本轮目标：
  把设置页剩余的工程味字段名、hint 和说明文案收成更自然的产品语言。
- 层级归属：
  `App / settings presentation`
- 必读文件：
  - `docs/important/user-facing-development-leftovers-followup-audit-2026-06-16.md`
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_advanced_panel.dart`
  - 相关 settings tests
- 必须完成：
  1. 处理 `预留输出 token`、`预留输出字符`、`优先 exact count` 这类词面。
  2. 检查并处理直接裸露原始枚举值的 hintText，优先改成用户语言或更自然的输入引导。
  3. 保持底层字段 key 不变，只改用户面投影。
  4. 更新 focused widget tests。
- 本轮不要做：
  1. 不改 settings contract/storage 字段。
  2. 不动权限页。
  3. 不扩大到 workbench。
- 验收标准：
  1. 设置页不再出现明显工程词面。
  2. 相关 tests 全通过。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md` 执行 `UFDL-FU-01`。只做设置页工程词面 polish：处理 `预留输出 token`、`预留输出字符`、`优先 exact count` 和相关 hintText，让它们变成更自然的用户语言。不要改底层字段 key，不要碰权限页和 workbench，不要开启下一任务。补 focused widget tests。
```

## UFDL-FU-02 权限/工具策略/工作台内部话术 polish

- 本轮目标：
  把权限页、工具策略页和工作台里仍然明显偏实现层的话术收掉。
- 层级归属：
  `App / projection / copy policy`
- 必读文件：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/tool_strategy_settings_panel.dart`
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- 必须完成：
  1. 收掉权限页/工具策略页里的“宿主”话术，改成用户能直觉理解的语言。
  2. 处理 `允许宿主进程调用` 这类标签。
  3. 处理工作台里“提示词优化链路后续会接独立用例”这类施工中提示。
  4. 处理设置概览中仍然偏过渡态的 `当前版本...` 说法。
  5. 更新 focused tests。
- 本轮不要做：
  1. 不改真实权限模型。
  2. 不改工具策略逻辑。
  3. 不处理拆书文案。
- 验收标准：
  1. 权限/工具策略/工作台不再对用户讲“宿主”“后续会接”“当前版本”这种明显内部或过渡口吻。
  2. focused tests 全通过。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md` 执行 `UFDL-FU-02`。只做权限页、工具策略页和工作台的内部话术 polish：收掉“宿主”“后续会接独立用例”“当前版本...”这类用户面残留。不要改权限模型和工具策略逻辑，不碰拆书，不开启下一任务。补 focused tests。
```

## UFDL-FU-03 拆书路径内部称呼 polish

- 本轮目标：
  把拆书用户面和相关 view data 中残留的内部模块称呼、工程菜单话术收掉。
- 层级归属：
  `App / book deconstruction presentation`
- 必读文件：
  - `apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
  - 相关拆书 tests
- 必须完成：
  1. 收掉 `information GUI` 这类内部模块称呼。
  2. 收掉 `资料桥`、`工程菜单`、过多的“后续路线/后续派生”工程味说法。
  3. 保持拆书能力语义不变，只做用户面语言优化。
  4. 更新 focused tests。
- 本轮不要做：
  1. 不改 follow-up 逻辑。
  2. 不改 derived project plan。
  3. 不新加拆书功能。
- 验收标准：
  1. 拆书页和相关 view data 读起来更像正式产品，而不是内部工作流说明。
  2. focused tests 全通过。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md` 执行 `UFDL-FU-03`。只做拆书路径内部称呼 polish：收掉 `information GUI`、`资料桥`、`工程菜单` 和过重的工程味“后续派生”表述。不要改 follow-up 逻辑和 plan，不开启下一任务。补 focused tests。
```

## UFDL-FU-04 回归补强与最终收口

- 本轮目标：
  把这轮 polish 加进黑名单回归，并输出简短 closeout。
- 层级归属：
  `Regression / documentation`
- 必读文件：
  - `docs/important/user-facing-development-leftovers-followup-audit-2026-06-16.md`
  - `apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart`
  - 本主线改动涉及的 tests
- 必须完成：
  1. 把这轮新清理的词加入黑名单回归，或补相应 focused regression。
  2. 运行本主线相关 tests。
  3. 生成一个简短 closeout 文档，说明收掉了哪些剩余工程味文案、还有没有残留。
- 本轮不要做：
  1. 不扩展新功能。
  2. 不引入新主线。
  3. 不把问题做大。
- 验收标准：
  1. regressions 全通过。
  2. 有简短 closeout。
- 直接可用提示词：

```text
根据 `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md` 执行 `UFDL-FU-04`。只做回归补强与最终收口：把这轮新清理的词加入黑名单回归或 focused regression，跑相关 tests，并输出简短 closeout。不要扩展新功能，不开启其他主线。
```

---

## 8. 总启动提示词

```text
根据 `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md` 连续执行 `UFDL-FU` 主线，从 `UFDL-FU-01` 开始，完成一个 session 后再进入下一个，直到 `UFDL-FU-04` 全部完成。

执行规则：

1. 每轮只做当前 session，完成后更新本任务顺序文档里的完成记录，再进入下一轮。
2. 必须先读：
   - `docs/important/user-facing-development-leftovers-followup-audit-2026-06-16.md`
   - `docs/user-facing-development-leftovers-followup-session-order-2026-06-16.md`
   - `agent.md`
3. 这是文案和投影 polish 主线，不要借机重构大业务，不要扩展到底层合同。
4. 只在必要的 view data / policy / widget 文案层改动，避免把逻辑塞回 controller。
5. 每个 session 都要补 focused tests 或 regression。
6. 不要开启下一条主线，不要顺手做 CLI，不要扩大为大重构。
```

---

## 9. 完成记录占位

### UFDL-FU-01 完成记录

- 状态：已完成
- 完成时间：2026-06-16
- 主要改动：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`
  - 将 `预留输出 token`、`预留输出字符`、`优先 exact count` 和原始枚举 hint 收成更自然的用户语言。
  - 把自动压缩策略与压缩输出样式改成下拉选择，保留原始合同键不变。
  - `apps/novel_agent_app/test/context_settings_panel_test.dart`
  - 补了回归断言，锁住新文案与保存值投影。
- 验证命令：
  - `flutter test test/context_settings_contract_service_test.dart`
  - `flutter test test/context_settings_panel_test.dart`
- 验证结果：
  - `context_settings_contract_service_test.dart` 通过。
  - `context_settings_panel_test.dart` 通过。
- 剩余风险：
  - 设置页其余高级模型面板仍可能保留少量接口术语，但不在本轮 `UFDL-FU-01` 范围内。
- 下一步：
  - 进入 `UFDL-FU-02`，收权限页、工具策略页和工作台概览里的内部/过渡话术。

### UFDL-FU-02 完成记录

- 状态：已完成
- 完成时间：2026-06-16
- 主要改动：
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`
  - 把权限页里的“宿主”话术收成更自然的“应用 / 本机程序”表达。
  - `apps/novel_agent_app/lib/features/settings/presentation/widgets/tool_strategy_settings_panel.dart`
  - 把工具策略页里直接指向宿主放行的描述改成权限放行口吻。
  - `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
  - 收掉 optimize 提示里的路线图式说法，并把附件不支持提示改成“本机环境”表述。
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - 把设置概览里的“当前版本”过渡口吻收成直接规则说明。
  - `apps/novel_agent_app/test/permissions_settings_panel_test.dart`
  - `apps/novel_agent_app/test/tool_strategy_settings_panel_test.dart`
  - `apps/novel_agent_app/test/tool_preview_settings_test.dart`
  - `apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart`
  - `apps/novel_agent_app/test/settings_page_projection_regression_test.dart`
  - `apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart`
  - 补了对应 focused tests 和黑名单回归。
- 验证命令：
  - `flutter test test/permissions_settings_panel_test.dart`
  - `flutter test test/tool_strategy_settings_panel_test.dart`
  - `flutter test test/tool_preview_settings_test.dart`
  - `flutter test test/workbench_conversation_controller_agent_selection_test.dart`
  - `flutter test test/settings_page_projection_regression_test.dart`
- 验证结果：
  - 全部通过。
- 剩余风险：
  - 其他工作台/壳层内部注释仍会保留“宿主”这个工程术语，但不再出现在本轮聚焦的用户面文案里。
- 下一步：
  - 进入 `UFDL-FU-03`，收拆书页和相关 view data 里的内部称呼与工程菜单话术。

### UFDL-FU-03 完成记录

- 状态：已完成
- 完成时间：2026-06-16
- 主要改动：
  - `apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`
  - 将 `共享资料桥`、`后续工程菜单` 这类内部味标题改成更自然的用户语言。
  - `apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`
  - 将 `information GUI`、`后续派生` 等字面收成“资料与设定 / 后续方案”这类正式表达。
  - `apps/novel_agent_app/test/book_deconstruction_preview_panel_test.dart`
  - `apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart`
  - 补了拆书投影回归，锁住新文案。
- 验证命令：
  - `flutter test test/book_deconstruction_view_data_service_test.dart`
  - `flutter test test/book_deconstruction_preview_panel_test.dart`
- 验证结果：
  - 全部通过。
- 剩余风险：
  - 拆书相关注释和部分服务/文档仍保留“后续路线”这类正常产品语义，但不再是内部模块直译。
- 下一步：
  - 进入 `UFDL-FU-04`，做黑名单回归补强和最终 closeout。

### UFDL-FU-04 完成记录

- 状态：已完成
- 完成时间：2026-06-16
- 主要改动：
  - `apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart`
  - `apps/novel_agent_app/test/settings_page_projection_regression_test.dart`
  - `apps/novel_agent_app/test/book_deconstruction_preview_panel_test.dart`
  - `apps/novel_agent_app/test/book_deconstruction_view_data_service_test.dart`
  - `apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart`
  - 把本轮新清理词汇补进黑名单回归，并补上整体 closeout。
  - `docs/user-facing-development-leftovers-followup-closeout-2026-06-16.md`
  - 生成简短 closeout，说明本轮收口范围与剩余风险。
- 验证命令：
  - `flutter test test/user_facing_development_leftovers_regression_test.dart`
  - `flutter test test/settings_page_projection_regression_test.dart`
  - `flutter test test/book_deconstruction_view_data_service_test.dart`
  - `flutter test test/book_deconstruction_preview_panel_test.dart`
  - `flutter test test/workbench_conversation_controller_agent_selection_test.dart`
- 验证结果：
  - 全部通过。
- 剩余风险：
  - 壳层和控制器内部注释仍会保留少量工程术语。
  - 拆书相关文档里还保留正常的“后续方案/后续路线”语义，不属于本轮问题。
- 下一步：
  - 本主线收口完成，如需再收只能另起更细的用户面 polish 任务。
