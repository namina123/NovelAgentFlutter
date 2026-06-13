# 开局分流与默认表达限制后续收口（2026-06-09）

## 本轮已完成

1. 修正普通项目开篇分流  
   - 开篇阶段不再仅凭主智能体像 writer 就默认走 `chapter`。
   - 现在会结合项目开局成熟度、当前打开文件路径、用户输入内容，优先把“背景/设定/主线/世界观”类输入判成 `planning`。
   - `planning` 已继续下沉到普通会话运行时，不再被底层重新当成正文交付任务。

2. 修正普通项目开篇引导文案  
   - fresh/opening 阶段不再提示“可以直接写第一章/续写下一章”。
   - 改为先鼓励用户整理题材、主线、角色、世界观和设定。

3. 修正工具时间线误导文案  
   - `submit_chapter_delivery` 改为“已交付章节”。
   - `write_project_file` 等写文件工具不再一律显示“已保存正文”。
   - 现在会区分正文、开局资料、信息资料和普通文件。

4. 修正项目创建默认表达限制装载缺失  
   - 新项目创建后，若项目里尚无表达限制 binding，会从应用设置读取默认 profile 列表并自动写入项目。
   - 当前无 GUI 配置时，默认回落到内置 `de_ai`。
   - 用户可先通过设置文件覆盖：
     ```json
     {
       "project_creation_defaults": {
         "expression_constraint_profile_ids": ["de_ai"]
       }
     }
     ```
   - 若明确写空数组，则创建项目时不自动装载：
     ```json
     {
       "project_creation_defaults": {
         "expression_constraint_profile_ids": []
       }
     }
     ```

5. 修正文档编辑区双滚动条  
   - 编辑器显式滚动条与桌面自动滚动条不再叠加。

## 本轮后续收口完成

1. 设置页已补上“项目创建默认表达限制”最小 GUI 入口  
   - 入口位于应用设置工具策略区，只控制“新项目创建后默认装载哪些 profile”。
   - 采用三态语义：
     - `builtinFallback`：不写显式配置，继续沿用内置回落。
     - `custom`：显式写入选中的 profile 列表。
     - `disabled`：显式写空列表，不自动装载。
   - 创建项目时仍只会在“项目当前无 binding”时种入默认值，不会在项目打开后反复覆盖。

2. 普通会话工具动态显示已补齐运行态区分  
   - 当前执行区和状态条现在区分：
     - `执行中`
     - `已完成`
     - `待确认`
     - `失败`
   - pending tool call 只出现在流式执行区，不污染稳定时间线。
   - 状态条优先显示工具阶段文案，例如读取文件、检查项目内容、写入文件、加载技能、资料研究、待确认整理、项目资料写回。
   - 工具返回但本轮尚未结束时，状态条显示“某工具已返回，正在整理结果”，避免过早投影成最终结果文案。

3. `GUI Viewmodel Probe Provider` 已完成专项核查  
   - 确认普通工作台 probe 里仍残留“普通会话直接写第 01 章并尽量 `submit_chapter_delivery`”的过时假设。
   - 已只在 probe 层修正为“普通会话：开篇筹备与资料核查”合同：
     - 优先推进资料、约束、研究 request/note 或待确认项。
     - 不再默认把普通开篇输入短路成第一章正文交付。
   - probe 成功条件也改为“形成有效推进”而不是“必须产出章节交付”。

## 本轮验证

- `flutter test`
  - `test/project_creation_expression_constraint_defaults_service_test.dart`
  - `test/project_creation_expression_constraint_defaults_settings_service_test.dart`
  - `test/project_creation_expression_constraint_defaults_panel_test.dart`
  - `test/conversation_tool_entry_projection_service_test.dart`
  - `test/conversation_streaming_state_service_test.dart`
  - `test/conversation_sidebar_test.dart`
  - `test/real_gui_viewmodel_information_long_task_probe_contract_test.dart`
- `dart analyze`
  - `lib/app/state/app_shell_controller.dart`
  - `lib/features/project_creation/...`
  - `lib/features/settings/...`
  - `lib/features/workbench/...`

## 给目标模式的提示词

按 `docs/important/opening-default-constraint-followup-2026-06-09.md` 继续，只做后续收口，不要重做本轮已完成内容。目标如下：

1. 给应用设置页增加“项目创建默认表达限制”最小 GUI 配置入口：
   - 这是应用级策略，不是项目级编辑器。
   - 用户只能决定“新项目默认装载哪些表达限制 profile”。
   - 没有配置时沿用当前内置回落；显式清空时不自动装载。
   - 不要把表达限制 binding 编辑逻辑搬进设置页。

2. 增强普通会话的工具动态显示：
   - 区分“执行中”“已完成”“待确认”“失败”。
   - 长耗时工具优先在当前执行区和状态条显示动态阶段，不要过早把它投影成最终结果文案。
   - 保持时间线是稳定结果，当前执行区是动态过程，不要混淆。

3. 单独核查 `GUI Viewmodel Probe Provider` / mock provider：
   - 确认是否存在把普通开篇输入直接短路成“产出第一章正文交付”的过时逻辑。
   - 若有，只修 probe/mock 层，不要污染真实生成链。

约束：

- 保持解耦，不要把设置页、项目 binding 编辑器、会话时间线逻辑硬糊在一个文件里。
- 不要把表达限制默认装载做成项目打开时反复覆盖，只允许在“新项目创建后且项目当前无 binding”时种入默认值。
- 不要把“执行中”的阶段文案写死成正文语义；文件写入、资料研究、技能加载、确认请求都要分开表达。
- 每改一层都补最小测试。
