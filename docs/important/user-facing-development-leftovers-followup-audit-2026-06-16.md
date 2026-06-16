# 面向用户开发遗留补充审计

最后更新：2026-06-16

关联文档：

- `docs/important/user-facing-development-leftovers-audit-2026-06-16.md`
- `docs/user-facing-development-leftovers-closeout-2026-06-16.md`

---

## 1. 结论

`UFDL` 主线这轮已经把最刺眼、最影响发布可信度的遗留问题收掉了：

1. Android release 不再回退到 debug signing。
2. 正式入口不再直接向用户吐 `未接入执行链`。
3. 设置页主路径不再暴露 `开发` tab、宿主根路径和内部类名。
4. 主题页、拆书预览页、技能装载页的明显占位块和伪状态说明已经清掉。

但我做完复核后，仍然抓到一批**不算阻断发布、但还带着明显内部/半成品味道的用户面瑕疵**。它们比上一轮轻很多，不过如果目标是“尽量像正式产品”，这批还值得再收一刀。

---

## 2. 本轮补充发现

## 2.1 P1：设置页仍残留少量工程味词面

### 证据

文件：`apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart`

仍存在这些用户可见词：

1. `预留输出 token`
2. `预留输出字符`
3. `优先 exact count`
4. `disabled / warning / warning_and_critical`
5. `structured_bullets / balanced_bullets / detailed_bullets`

### 为什么值得继续收

这些不是错误，但会让设置页仍然偏“面向实现者”，不像面向普通用户。

尤其是：

1. `预留输出 token/字符`
   听起来像内部计算术语，不像用户能直觉理解的参数。
2. `优先 exact count`
   直接混入英文实现说法，产品感偏弱。
3. 枚举 hintText 直接暴露原始值
   更像配置键，而不是用户选项。

### 建议

1. 把这些字段收成更自然的中文产品词。
2. 原始枚举值若必须保留，放到内部映射或下拉选择，不要直接裸露成 hint。

---

## 2.2 P1：权限与工具策略页仍直接使用“宿主”话术

### 证据

文件一：`apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart`

1. `这里定义宿主允许哪些能力真正进入执行链`
2. `这里只决定“宿主是否允许做”`
3. `允许宿主进程调用`

文件二：`apps/novel_agent_app/lib/features/settings/presentation/widgets/tool_strategy_settings_panel.dart`

1. `它不负责宿主放行与否`

### 为什么值得继续收

“宿主”这个词对开发者是准的，对普通用户却不是自然的产品语言。

用户更容易理解的是：

1. 应用是否允许
2. 当前项目是否允许
3. 是否需要确认

而不是“宿主是否放行”。

### 建议

1. 设置页统一改成“应用权限 / 执行权限 / 需要确认的能力”一类口径。
2. “宿主进程调用”可以改成更自然的结果导向表达，比如“允许启动本机程序”或“允许调用本机命令”。

---

## 2.3 P1：部分用户文案仍带“后续会接”的半成品语气

### 证据

文件：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

第 937 行附近：

`当前先直接发送自然语言需求；提示词优化链路后续会接独立用例。`

### 为什么值得继续收

这已经不是内部注释，而是会发给用户的提示。

它的问题不是信息错误，而是仍然在向用户暴露产品施工状态：

1. “当前先……”
2. “后续会接……”

这类话术明显像开发过程中的过渡说明。

### 建议

1. 改成纯当前能力说明，不提未来接线计划。
2. 如果该入口其实只是暂时没有完整功能，优先改成自然指引，而不是路线图式提示。

---

## 2.4 P1：设置页概览里仍有“当前版本”话术

### 证据

文件：`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

权限概览描述：

`当前版本只在项目工作区内读写，不向移动端额外申请外部存储权限。`

### 为什么值得继续收

“当前版本”这类说法并不算严重，但它仍然隐含一种“以后可能会不同”的开发过渡口气。

如果这是正式产品说明，更自然的表述通常是直接描述当前规则，而不是先加一句版本阶段话术。

### 建议

把它改成更稳定的描述，例如直接说明：

1. 应用只会在项目工作区内读写
2. 不会主动申请额外外部存储权限

---

## 2.5 P1：拆书用户面仍保留少量内部称呼

### 证据

文件：`apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart`

仍有用户可见文案：

1. `共享 information GUI`
2. `后续路线`
3. `后续派生`

文件：`apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart`

仍有标题：

1. `后续用途与共享资料桥`
2. `续写基座与后续工程菜单`

### 为什么值得继续收

这里已经比之前好很多了，但仍残留两类内部词：

1. `information GUI`
   这是明显的实现/模块称呼，不该直接给用户看。
2. `资料桥 / 工程菜单 / 后续派生`
   语气更像内部工作流，不像用户向能力说明。

### 建议

1. 把 `information GUI` 收成“资料与设定”之类的正式产品名。
2. 把 `资料桥 / 工程菜单 / 后续派生` 收成更自然的“可继续做什么”“可创建什么”“可延展为哪些项目”。

---

## 3. 这轮为什么没有直接判定“完全没问题”

原因很简单：

**硬问题已经收掉了，但产品语言层还有一层薄薄的工程味。**

这和上一轮不是一个量级：

1. 不再是“点进去撞未接入”这种严重问题。
2. 也不再是“主题页摆着一堆占位块”这种完成度问题。

现在剩下的，更多是：

1. 术语不够用户化。
2. 个别提示仍像在对开发者说话。
3. 少量工作流页面仍保留内部模块称呼。

所以这轮更像“产品 polish 补收口”，不是结构性返工。

---

## 4. 建议的处理方式

如果接下来要继续收，而不是马上停在这里，建议就做一个很小的 follow-up：

1. 统一设置页剩余工程味词面。
2. 把权限/工具策略页的“宿主”话术改成用户语言。
3. 清掉工作台里那句“后续会接”的提示。
4. 清掉拆书相关页面里 `information GUI`、`资料桥`、`工程菜单` 这种内部味词。
5. 顺手把黑名单回归再补一轮。

这会是一条很短的 polish 主线，不需要再拆大任务。

---

## 5. 当前打包结论

### 已确认通过

1. focused tests：
   - `user_facing_development_leftovers_regression_test.dart`
   - `settings_page_projection_regression_test.dart`
   - `theme_settings_panel_test.dart`
   - `book_deconstruction_preview_panel_test.dart`
   - `project_skill_loadout_view_data_service_test.dart`
   - `opening_session_panel_test.dart`

2. Windows release：
   - `flutter build windows --release`
   - 已成功生成 `build/windows/x64/runner/Release/novel_agent_app.exe`

### 已确认符合预期但未形成可分发包

1. Android release：
   - `flutter build apk --release --no-pub`
   - 当前会因未配置正式 signing 而明确失败
   - 这是符合 `UFDL-03` 设计的结果，不是回退到 debug signing

---

## 6. 最终判断

当前项目**已经可以做 Windows 包**，而且这轮没有再发现新的发布阻断级问题。

但如果目标是“尽量像正式产品而不是工程半成品”，我建议在真正对外发包前，再补收这一轮文档里列出的几处用户语言残留。

它们不重，不需要大主线，但值得做。
