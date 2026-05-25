# Writingway 吸收档案

## 1. 项目定位

- 来源项目：`references/Writingway-main`
- 主要类型：`PyQt` 桌面写作工作台
- 许可证：`MIT`
- 我们参考它的原因：
  - 它不是单纯聊天器，而是明确围绕“写作工作台”组织界面和功能
  - 它把项目树、场景编辑、总结、Prompt、Compendium、Workshop、RAG、设置等拆成了相对独立的模块
  - 它对桌面端写作体验、侧栏切换、活动栏、可选上下文、项目内结构编辑这些地方，很有参考价值

## 2. 总判断

`Writingway` 最值得我们吸收的，不是它的 PyQt 具体做法，而是它对“写作 IDE”这件事的理解。

和前面几份参考项目相比：

- `AIxiezuo` 更像早期小说生成器骨架
- `Ai-Novel` 更像工程化资产平台
- `Writingway` 更像桌面写作工作台

所以它对 NovelAgent 的最大价值，在于补强这几条线：

- 工作台布局与多面板协作
- 项目树/章纲/场景编辑的交互组织
- Compendium 作为独立可选上下文源
- Prompt 与 Workshop 的协作入口
- 层级总结链
- 本地项目持久化与自动保存

## 3. 可吸收精髓

### 3.1 它把“写作应用”做成了真正的工作台

从 `project_window.py`、`activity_bar.py`、`bottom_stack.py` 可以看出，它的思路不是“打开一个文档，然后旁边塞个聊天框”，而是明确有几块协作区域：

- 左侧活动栏
- 左侧侧边栏
- 中央编辑区
- 底部辅助区
- 可切换的 Prompt / Compendium / Search / Outline 面板

这对我们的启发很直接：

- 工作台应是多面板协作，而不是单页面堆按钮
- 侧栏内容应按职责切换，而不是一直常驻堆叠
- 文本编辑、结构浏览、上下文选择、对话协作应各有区域

这和你一直强调的“像 VS Code 一样的工作台感”是同方向的。

我们应吸收的是它的工作台组织逻辑，而不是 PyQt 控件本身。

### 3.2 项目树不是简单文件树，而是“创作结构树”

它的 `tree_manager.py`、`project_tree_widget.py`、`project_model.py` 明确以：

- Act
- Chapter
- Scene
- Summary

这种创作层级组织项目。

而且树节点不是只显示结构，它还承载：

- `uuid`
- `has_summary`
- `latest_file`
- autosave / summary 状态

这给我们的启发是：

1. 小说项目左栏不能只是物理文件树
2. 需要一层“创作结构视图”
3. 结构节点要能关联正文、摘要、状态和附属资产

对 NovelAgent，很适合继续明确成两层并存：

- 物理资源树：用户真实看到的项目文件
- 逻辑创作树：卷/章/场景/摘要/任务结构

这也正好契合我们后面要继续改的工作区逻辑。

### 3.3 场景编辑器是独立能力，不应和主控制器揉在一起

`scene_editor.py` 很典型地把编辑器自己做成一块独立职责区域，里面包含：

- 文本编辑
- 基础格式
- 查找
- 拼写检查
- TTS
- 分析入口
- 手动保存 / 备份入口

这说明它把“编辑器”当成一个明确的子系统，而不是主窗口里的一个大文本框。

对我们来说，这个思想很重要：

- 文档编辑器应是一个独立 feature
- 工具栏、渲染、编辑、查找、状态提示应就近归属
- 不应再把这类逻辑继续往 `AppShellController` 里塞

这和你前面提醒的“`app_shell_controller.dart` 过大，后面别再往里补”正好对上。

### 3.4 Summary 不是附带功能，而是一条正式的层级链

它有：

- `summary_controller.py`
- `summary_model.py`
- `summary_service.py`
- `token_limit_dialog.py`

而且总结对象不是只有“单场景摘要”，还支持：

- scene -> chapter
- chapter -> act

同时它有一套很朴素但实用的逻辑：

- 如果故事太长，就优先用已有 summary
- 如果还超，就让用户改 summary
- summary 既是展示对象，也是上下文压缩对象

这对我们的启发很强：

1. 摘要应成为正式资产
2. 摘要应有层级
3. 摘要既服务阅读，也服务上下文压缩
4. 超预算时，摘要不是临时字符串，而是用户可干预对象

这和我们当前的：

- context assembler
- session record
- generation record
- checkpoint review

其实能很好融合。

### 3.5 Compendium 是非常值得吸收的“项目知识侧栏”

`enhanced_compendium.py`、`compendium_manager.py`、`context_panel.py` 这条线很有参考价值。

它的精髓不是“有个百科面板”，而是：

1. Compendium 是独立知识资产
2. 它可以按类别、条目、关系、图片来组织
3. 它和正文编辑区是分开的
4. 它可以被用户勾选为 Prompt 上下文的一部分

尤其是 `ContextPanel` 这一点很关键：

- 用户不是只能把“整个项目”喂给模型
- 可以精确选择哪些场景、哪些摘要、哪些 Compendium 条目参与当前请求

这对 NovelAgent 很有价值，因为它和我们的“工具 / 文件 / 资产 / 会话上下文策略”能够形成非常自然的结合。

我建议吸收为：

- 资产中心中的“知识条目”
- 会话中的“可选注入上下文”
- 长任务中的“长期约束来源”

### 3.6 Workshop 不是普通聊天，而是“带项目上下文的协作室”

`WorkshopController`、`WorkshopView`、`chat_session.py`、`conversation_manager.py` 这条线是 `Writingway` 的另一大亮点。

它的聊天不是裸聊，而是会把这些东西揉进去：

- prompt panel 中的 prompt
- context panel 选中的 project 内容
- compendium 选中的条目
- embedding query 返回的检索片段
- 当前会话历史

这说明它已经抓住一个很重要的点：

“写作聊天”本质上是一个带上下文拼装的协作请求，不是普通消息来回。

对我们来说，这一点特别值得吸收成更正式的 core 合同：

- 会话类型
- 会话上下文来源
- Prompt 模板
- 记忆窗口
- 检索片段
- 资产注入片段

### 3.7 会话可以按模式组织，而不是只有一个聊天流

它至少区分了：

- `Writing Coach`
- `Role Play`

这虽然还比较轻，但对我们很有启发。

也就是说，会话并不总是“一个默认智能体 + 一个输入框”。

不同模式可以有：

- 不同验证条件
- 不同 system prompt 组装方式
- 不同上下文要求
- 不同默认角色

这和我们当前已经在做的：

- project strategy
- mode strategy
- workflow strategy

是同方向的。

它给我们的提醒是：  
模式不只是一个标签，而应该改变“会话怎么被组装”。

### 3.8 Prompt 面板是工作台内的一等公民

它的 `muse/prompt_*`、`embedded_prompts_panel.py`、`prompt_preview_dialog.py` 这条线说明：

- Prompt 不应该躲在设置页深处
- Prompt 可以和当前项目工作区并排协作
- Prompt 预览和修改是日常写作动作的一部分

这一点非常值得吸收。

我们的新项目后面做 Prompt Debug / Prompt Studio 时，不该只是孤立页面，而应考虑：

- 与当前会话连通
- 与当前任务连通
- 与当前资产/文件上下文连通

### 3.9 本地项目持久化思路很务实

`project_model.py` 里有一些值得吸收的务实设计：

- 结构数据和正文文件分离
- autosave 作为独立层
- `latest_file` 指向最新内容
- 旧内容向新结构迁移
- summary 也可以从内嵌字段迁到文件

虽然具体实现比较老派，但思路很适合我们：

- 别把一切都内嵌到一个结构文件里
- 大正文和摘要应能独立成文件
- 索引层只追踪引用关系和元信息

这和我们的 `Markdown + SQLite` 双兼容非常一致。

### 3.10 Search / Rewrite / Analysis / Focus 这些辅助面板说明“写作不是只生成”

`search_replace_panel.py`、`rewrite_feature.py`、`focus_mode.py`、`text_analysis_gui.py` 这些说明：

真正的写作应用不是只有“生成”和“保存”。

还需要：

- 查找替换
- 局部重写
- 分析
- 专注模式

我们不一定要一比一实现它们，但它提醒我们：

- NovelAgent 的 GUI 不该只偏向对话
- 也要照顾真实编辑工作流

### 3.11 RAG / PDF / QA 的实现不成熟，但方向值得吸收

它的 `embedding_manager.py`、`rag_pdf.py`、`rag_smart_qa.py` 很粗糙，尤其 embedding 近乎 demo 性质。

但它有一个方向是对的：

- 外部资料导入
- 资料切片
- 问答式召回
- 结果进入当前协作上下文

所以我们不吸收它的具体检索实现，但可以吸收：

- “资料工作坊”是一个独立能力
- 外部文档与当前项目协作可以打通

### 3.12 设置层拆得比较清楚

它把设置拆到了：

- `settings_manager`
- `theme_manager`
- `autosave_manager`
- `backup_manager`
- `llm_api_aggregator`
- `llm_settings_dialog`
- `translation_manager`

说明它已经明确意识到：

- 设置不是一个 JSON 读写器就够了
- 主题、自动保存、备份、模型配置是不同职责

这对我们也是个提醒：

- 设置页只是 UI
- 设置处理逻辑仍然需要继续拆分

## 4. 对 NovelAgent 的架构落点

### `core`

最适合进入 `core` 的吸收点：

- 创作结构树模型
- 层级摘要策略
- 会话模式与上下文拼装合同
- 可选上下文注入规则
- Prompt 预览/渲染合同
- 正文 / 摘要 / 资产 / 检索片段的装配逻辑

### `adapters`

- 项目结构持久化
- autosave / backup 仓储
- 本地文件引用追踪
- 资料导入与切片
- 可选检索后端

### `app`

- 工作台状态装配
- 侧栏切换状态
- 编辑器与资源树联动
- 会话与上下文选择联动
- Prompt Studio / Prompt Debug 的应用状态

### `ui`

- 三栏/双栏/单栏工作台布局
- 活动栏
- 创作结构树
- Context 选择面板
- Compendium 浏览与编辑面板
- Prompt 面板
- 底部诊断/摘要/辅助面板

## 5. 可服务的策略

### `project_strategy`

强相关：

- 一般小说项目
- 长篇项目

中相关：

- 短文集项目

可选相关：

- 拆书项目

它最适合服务“持续创作型项目”，尤其是需要真正工作台的那类。

### `mode_strategy`

强相关：

- 一般协作写作模式
- `full_outline_consensus`

中高相关：

- `seed_autopilot_novel` 的前期讨论与后期编辑阶段
- 灵感模式进入整理阶段

它对“纯自动长任务调度”帮助没前几份大，但对“人机协作工作区”帮助非常大。

### `workflow_strategy`

最适合服务：

- 章纲到正文
- 场景编辑
- 章节摘要
- Act/Chapter/Scene 结构管理
- 可选上下文协作问答
- Prompt 调整与预览
- 局部改写和人工整理

## 6. 与现有设计的融合点

### 6.1 与我们的工作台布局直接相关

它最能帮助我们的，是你之前一直在强调的那些 UI/布局问题：

- 左侧栏不该只是按钮堆
- 主视图应是项目目录/正文工作区
- 各面板要能切换，不是都挤在一起
- 三栏/双栏/单栏应该是策略，不是写死布局

这部分非常适合继续指导我们 Flutter 工作台改造。

### 6.2 与我们的资产层融合

它的 Compendium 虽然不是我们最终形态，但很适合和我们的资产层结合：

- 风格
- 角色
- 世界设定
- 伏笔
- 术语
- 关系

都可以成为“可选注入上下文”的来源。

### 6.3 与我们的会话层融合

它已经在做一种很初级但方向正确的事情：

- 会话不是裸消息流
- 会话要挂上下文选择
- 会话要挂模式
- 会话要挂 Prompt

这非常适合继续和我们已有的 session core 合并。

### 6.4 与我们的 Prompt 系统融合

它证明了 Prompt 面板应尽量贴近工作流，而不是只藏在设置里。

这对我们后面做：

- Prompt Debug 组合页
- 模板编辑
- agent / skill / workflow prompt 可视化

都很有帮助。

## 7. 不应吸收的部分

### 7.1 PyQt 宿主实现

不吸收：

- PyQt 控件树
- 具体快捷键和窗口实现
- 直接把窗口状态逻辑搬进我们的 Flutter 层

我们只吸收交互组织，不吸收宿主细节。

### 7.2 粗糙的 RAG / embedding 实现

像 `embedding_manager.py` 这种 demo 式 embedding，我们不应吸收。

可吸收的是“资料工作坊”的方向，不是具体算法。

### 7.3 单窗口内仍然耦合过重

虽然它已经拆了不少文件，但 `ProjectWindow` 仍然很重。

这也是我们必须继续警惕的地方：  
别在 Flutter 里复刻一个新的巨型 `ProjectWindow` 或 `AppShellController`。

### 7.4 富文本 HTML 存正文的方式

它的场景内容部分走 HTML/RichText，对我们不适合。

我们更应坚持：

- Markdown
- 明确结构化元数据
- 可渲染但不锁死宿主富文本格式

## 8. 后续实施候选

### 近期可做

1. 继续拆我们的工作台布局策略层
2. 正式建立“创作结构树”和“物理资源树”的并存关系
3. 做独立的 Context 选择面板
4. 把 Prompt Debug / Prompt 面板接近真实工作流
5. 继续拆编辑器 feature，减少主控制器负担

### 中期可做

1. 做资产中心与工作台的联动注入
2. 做层级摘要中心
3. 做资料工作坊 / 外部资料问答入口
4. 做章节/场景重写与对比

### 暂缓观察

1. 它的旧式 embedding / RAG 实现
2. 基于富文本 HTML 的编辑持久化方式

## 9. 当前结论

`Writingway` 对我们的价值，在于它把“小说写作应用应该像一个工作台”这件事落得很具体。

它提醒我们：

- 目录和结构应该是主视图的一部分
- 编辑器应是独立能力
- Prompt、Compendium、上下文选择都不该只是附属弹窗
- 摘要是正式资产
- 会话应和项目结构、知识条目、Prompt 配置联动

如果 `AIxiezuo` 提醒我们“最小小说骨架不能丢”，  
那 `Writingway` 提醒我们的就是“工作台体验和上下文协作层也不能丢”。
