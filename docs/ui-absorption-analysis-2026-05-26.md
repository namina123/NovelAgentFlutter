# UI 吸收分析（2026-05-26）

> 补充说明：这份文档保留为第一轮图片吸收记录。  
> 2026-05-27 之后的综合前端方向，请以
> `docs/frontend-evolution-synthesis-2026-05-27.md`
> 为新的总纲。

最后更新：2026-05-26

## 1. 本轮结论

基于以下参考图：

- `references/assets/ai_images_052601/主工作台：窄屏单列模式.png`
- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
- `references/assets/ai_images_052601/资产中心.png`

结合当前工程结构，结论是：

- 这不是“小修小补”级任务
- 这是一次 **工作台 UI 信息架构 + 组件职责 + 资源渲染模型** 的联合改造
- 因此本轮应先做分析与拆分，不适合在未拆任务的前提下直接一口气实现

原因不是“做不了”，而是如果现在直接硬改，很容易：

- 把 `workbench_page` 一类页面继续塞胖
- 让会话栏、资源栏、正文栏之间再次耦合
- 让“资源可渲染类型扩展”变成一堆 if/else
- 让桌面与窄屏布局逻辑重新散落在 widget 中

所以这轮最合理的动作是：**明确哪些点是轻量吸收、哪些点是中量改造、哪些点已经涉及新的 UI 合同和视图模型设计。**

---

## 2. 用户明确想吸收的点

### 2.1 窄屏单列模式

来自：

- `主工作台：窄屏单列模式.png`

希望吸收：

- 左下角可拉出 / 缩回的栏
- 单列模式下功能入口不能消失
- 仍保持会话卷轴为主视图

### 2.2 桌面三栏模式

来自：

- `主工作台：桌面三栏模式.png`

希望吸收：

- 更统一的背景色体系
- 会话栏输出格式
- 工具调用后显示完成勾等外显状态
- 工具调用细节可切换显示 / 隐藏
- 选项区域支持：
  - 折叠 / 展开细节
  - 折叠态等高
- 模型选择放到输入框下方
- 发送按钮放在会话输入区内部右下
- 发送中切换成停止按钮
- 增加深度思考开关（如果模型支持）
- 增加附件入口：
  - 桌面端显示
  - 移动端不显示

### 2.3 资产中心

来自：

- `资产中心.png`

希望吸收：

- 中间内容栏不局限于 Markdown / SQLite 文本
- 允许资源按类型渲染
- 需要考虑“智能适配”还是“显示模式切换”

### 2.4 总体约束

- 风格必须统一
- 不能一半旧风格、一半新风格
- 除保留：
  - 文件夹栏
  - 会话卷轴模式
  - 桌面三栏模式
  之外，其余均可重构

---

## 3. 难度评估

## 3.1 轻量级：可直接排进一次会话实现

这些不需要改动底层模型，只是 UI 组件调整：

1. 会话栏背景色体系统一
2. 工具调用完成状态展示为更轻量、更统一的状态样式
3. 工具调用细节显示 / 隐藏开关
4. 选项卡折叠 / 展开细节
5. 选项卡折叠态等高
6. 模型选择区域改到输入区下方
7. 输入区内部右下发送按钮
8. 发送态按钮变停止按钮（前提是控制器已有取消口子或先做 UI 壳）
9. 深度思考开关 UI 入口（先接模型能力判断）
10. 桌面端附件按钮显示、移动端隐藏

结论：

- **这些属于可实现项**
- 但最好拆成 1~2 次工作，而不是和布局改造混做

## 3.2 中量级：需要改工作台视图结构

这些不是简单换皮，需要调整工作台页面结构或视图模型：

1. 单列模式改成“主会话 + 可抽拉功能栏”
2. 单列模式入口重组
3. 会话栏头部、选择器、输入区重新分层
4. 桌面三栏模式颜色 / 分区风格整体统一
5. 资源栏与正文栏的视觉风格统一到新主题

影响面：

- `shared/widgets/app_shell*.dart`
- `features/workbench/presentation/pages/workbench_page.dart`
- `features/workbench/presentation/widgets/conversation_sidebar.dart`
- `features/workbench/presentation/widgets/resource_manager_panel.dart`
- `features/workbench/presentation/widgets/document_workspace_panel.dart`
- 相关布局策略类

结论：

- **这些已不再是“简单改样式”**
- 已经涉及 `workbench` 子域的布局合同

## 3.3 重量级：涉及新合同或新渲染模型

这些点必须先设计，不适合直接堆实现：

1. “中间内容栏不仅渲染 md/sqlite，也能渲染其他资源”
2. “资源按类型智能适配渲染，还是给显示模式切换按钮”
3. “附件能力桌面端可用、移动端隐藏”的宿主能力合同
4. “发送按钮变停止按钮”对应真实取消执行链
5. “工具细节显示 / 隐藏”是局部开关、会话级开关，还是全局设置

这些已经触及：

- 资源渲染抽象
- 文档工作区的 content renderer 策略
- 会话执行生命周期控制
- 宿主能力差异

结论：

- **这是需要先设计接口的部分**
- 当前不适合直接动手

---

## 4. 需要改的架构位置

## 4.1 工作台布局层

需要改：

- `apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/layout/workbench_surface_layout_policy.dart`
- `apps/novel_agent_app/lib/shared/widgets/app_shell.dart`

建议新增：

- `workbench_compact_shell.dart`
- `workbench_compact_drawer_controller.dart`
- `conversation_panel_layout.dart`

目标：

- 把“窄屏抽拉栏”作为正式布局模式
- 不把抽拉逻辑写进会话组件本身

## 4.2 会话栏组件层

需要改：

- `conversation_sidebar.dart`
- `conversation_timeline.dart`
- `conversation_entry_tile.dart`
- `composer_panel.dart`
- `selector_field.dart`
- `user_option_panel.dart`
- `user_option_tile.dart`

建议新增：

- `conversation_panel_header.dart`
- `conversation_model_strip.dart`
- `conversation_input_dock.dart`
- `tool_visibility_toggle.dart`
- `tool_event_row.dart`
- `expandable_option_tile.dart`

目标：

- 让“模型选择 / 发送 / 附件 / 深度思考 / 工具显示策略”分开
- 不把它们都压回 `conversation_sidebar.dart`

## 4.3 资源与正文工作区层

需要改：

- `resource_manager_panel.dart`
- `document_workspace_panel.dart`
- `document_content_canvas.dart`
- `document_markdown_canvas.dart`

建议新增：

- `resource_preview_mode.dart`
- `resource_renderer_contract.dart`
- `resource_renderer_registry.dart`
- `markdown_resource_renderer.dart`
- `plain_text_resource_renderer.dart`
- `structured_resource_renderer.dart`

目标：

- 先把“资源可按类型渲染”抽成合同
- 避免未来在 `document_workspace_panel.dart` 里写大段类型分支

## 4.4 会话控制器层

需要改：

- `workbench_conversation_controller.dart`

但注意：

- 不能继续往里堆 UI 状态

建议新增独立服务 / 状态：

- `conversation_tool_visibility_state.dart`
- `conversation_input_capability_service.dart`
- `conversation_stop_run_service.dart`
- `conversation_attachment_entry_service.dart`

目标：

- “是否显示工具细节”
- “是否支持附件”
- “是否支持停止生成”

都不要直接变成控制器里的零散 bool

---

## 5. 关于“中间栏可渲染其他资源”的专门判断

这是这一轮里最值得单独强调的点。

当前项目中，中间栏本质上还是：

- 文本文档编辑 / 渲染区

而你想要的是：

- 它是一个 **资源工作区**
- 文本只是资源的一种

这意味着后续更合理的方向不是：

- “给 Markdown 区加更多 if/else”

而是：

- 建立一个 **资源渲染器注册表**

也就是：

1. 先识别资源类型
2. 再决定默认渲染方式
3. 必要时允许手动切换显示模式

### 推荐方案

推荐采用：

- **默认智能适配**
- **辅以手动切换按钮**

原因：

- 纯智能适配：用户失去控制，出问题时难理解
- 纯手动切换：每次都要多一步，体验重

所以最合适的是：

- 默认根据资源类型选择渲染器
- 工具栏允许用户手动切换“源码 / 渲染 / 结构 / 预览”等模式

这已经是一个独立会话任务，不适合与本轮风格吸收混做

---

## 6. 关于附件按钮的专门判断

附件入口不是只画一个图标那么简单。

它背后至少有三层：

1. UI 是否显示
2. 宿主是否允许选择文件
3. 会话链是否支持把附件信息传入模型上下文

你当前明确要求：

- 桌面端显示
- 移动端不显示

这是合理的第一阶段。

建议后续实现方式：

- UI 能力判断单独放在 `conversation_input_capability_service`
- 桌面端文件选择单独走 host adapter
- 移动端先不显示，不留灰按钮

---

## 7. 关于“发送按钮变停止按钮”的专门判断

这点看起来像纯 UI，实际上不是。

因为它要求：

- 当前生成中的请求可取消

而当前系统里虽然有 `isGenerating`，但“停止”是否能真正中断：

- LLM 流
- 工具执行轮
- 长任务推进

要分开看。

结论：

- 如果先做 UI 壳，可以很快
- 如果要做“真实停止”，则要先补取消合同

所以这点属于：

- **中到重之间**

---

## 8. 推荐的后续实施顺序

如果下一轮开始真正实现，建议顺序如下：

### Session A：会话栏视觉和交互收束

只做：

- 工具细节开关
- 选项折叠卡
- 模型区下移到输入区上方或下方的最终布局
- 输入区内部发送按钮
- 深度思考开关 UI
- 桌面端附件按钮壳

不做：

- 真实附件传输
- 真实停止生成
- 中间资源渲染扩展

### Session B：单列模式抽拉功能栏

只做：

- 单列模式下左下角抽拉栏
- 单列导航与功能入口重组
- 保留会话卷轴主视图

不做：

- 桌面三栏大改

### Session C：桌面三栏风格统一

只做：

- 背景色体系
- 分隔线、面板表面、输入区、会话条目风格统一
- 资源栏 / 文档栏 / 会话栏视觉统一

### Session D：资源渲染器合同

只做：

- 中间栏“资源工作区”抽象
- 默认智能适配 + 手动切换按钮
- 渲染器注册表第一版

### Session E：停止生成与附件链路

只做：

- 真实停止生成合同
- 桌面端附件选择与会话接入

---

## 9. 最终判断

本轮用户提出的内容里：

- 有一部分是 **轻量可直接做**
- 但整体合在一起，已经属于 **较为复杂**

因此按当前要求，正确结论是：

- **本轮不直接实现**
- **先输出分析文档**

后续应按上面的 Session A ~ E 拆开逐步推进。

---

## 10. 下一轮建议提示词

如果下一轮从最自然的位置继续，建议先从会话栏开始，而不是先动资源工作区：

```text
按 docs/ui-absorption-analysis-2026-05-26.md 的 Session A 执行。先阅读 docs/ui-absorption-analysis-2026-05-26.md、references/assets/ai_images_052601/主工作台：桌面三栏模式.png、references/assets/ai_images_052601/主工作台：窄屏单列模式.png。只做会话栏视觉和交互收束：工具细节显示开关、可折叠且等高的选项卡、模型区重新排布、输入区内部发送按钮、深度思考开关 UI、桌面端附件按钮壳。不要做真实附件传输，不要做真实停止生成，不要碰资源渲染器抽象。注意单一职责、不要让 conversation_sidebar.dart 继续变重，优先拆新组件和轻量状态服务。
```
