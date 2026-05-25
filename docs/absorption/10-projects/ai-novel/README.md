# Ai-Novel 吸收档案

## 1. 项目定位

- 来源项目：`references/Ai-Novel-main`
- 主要类型：`React + FastAPI` 的在线小说创作与项目管理系统
- 许可证：`MIT`
- 我们参考它的原因：
  - 它把“写作项目”拆成了很多可独立管理的资产对象，而不只是聊天
  - 它把 Prompt、模型配置、任务运行、记忆、RAG、图谱、导入导出做成了相对清晰的子系统
  - 它对 `OpenAI / OpenAI-compatible / Anthropic / Gemini / Responses API` 的兼容层思路，和我们当前正在补强的 provider 体系高度相关

## 2. 总判断

`Ai-Novel` 最值得吸收的，不是它的 Web SaaS 形态，而是它把小说工程拆成了“资产层 + 运行层 + Prompt 层 + 检索层 + 任务层”的能力结构。

它和 `MuMuAINovel` 的气质不太一样：

- `MuMuAINovel` 更偏产品闭环与创作体验
- `Ai-Novel` 更偏工程化、资产化、运行时治理

所以它对我们最有价值的地方，是补“基础设施脑子”，尤其是：

- 资产对象分层
- Prompt 资源化
- 任务运行时
- 检索上下文层
- 模型合同与任务级模型配置

## 3. 可吸收精髓

### 3.1 把小说项目拆成多个稳定资产中心

从它的页面与模型可以看出，它不是只有“项目 / 章节 / 会话”三件套，而是把很多对象独立出来：

- `worldbook`
- `writing_style`
- `story_memory`
- `structured_memory`
- `fractal_memory`
- `graph`
- `glossary`
- `project_table`
- `prompt_preset`
- `prompt_block`
- `project_source_document`
- `generation_run`
- `project_task`

这对我们的启发非常直接：

- 不要把“长期记忆”只做成一类东西
- 不要把“设定”只藏在系统提示词里
- 不要把“运行记录”只留在聊天消息里

我们更适合吸收成：

- `assets/setting`：世界观、规则、术语、数值体系
- `assets/style`：写作风格、表达约束、去 AI 约束
- `assets/memory`：故事记忆、结构化记忆、伏笔、关系图
- `assets/prompt`：模板、块、任务预设
- `assets/runtime`：生成记录、任务记录、回放记录、调试包

### 3.2 Prompt 不是一段字符串，而是一套“资源化模板系统”

它的 `prompt_presets.py` 和 `resources/prompt_presets/*` 很有参考价值。

我认为真正值得吸收的点有四个：

1. 任务有自己的 Prompt 预设
2. Prompt 由多个 block 组成，而不是一整段大文本
3. block 有优先级、启用条件、预算裁剪策略
4. Prompt 渲染和预算日志是可观察的

它甚至已经把很多写作任务做成资源：

- `outline_generate`
- `chapter_generate`
- `chapter_analyze`
- `chapter_rewrite`
- `plan_chapter`
- `memory_update`
- `post_edit`
- `content_optimize`

对我们来说，应该吸收成：

- `core` 中的 `PromptTemplateAsset / PromptBlockAsset / PromptTaskCatalog`
- `core` 中的 `PromptRenderUseCase / PromptBudgetUseCase / ContextTrimPolicy`
- `adapters` 中的模板资源加载与项目覆盖
- `app/ui` 中的 Prompt Studio、差异预览、恢复默认

这一点尤其适合：

- 一般小说项目
- 长任务模式 1
- 长任务模式 2
- 未来拆书、短文集、风格改写等平行策略

### 3.3 把“任务运行”当成正式子系统

它的 `project_task_runtime_service.py`、`project_task_event_service.py`、`task_queue.py` 非常像一套真正的运行时，而不是“顺手起个后台线程”。

值得吸收的不是 Redis/RQ 本身，而是这几个思想：

1. 任务有独立实体，不和会话消息混在一起
2. 任务有事件流，不只有最终状态
3. 有 heartbeat / watchdog / reconcile 这种运行时保活与修复
4. 失败、超时、重试、重排队都有明确状态
5. 运行记录可以被 UI 单独消费

这和我们现在已有的长任务运行记录、队列记录、checkpoint review 非常契合。

适合继续融合成：

- `core/runtime`：任务状态机、事件模型、重试策略、超时策略、恢复策略
- `adapters/runtime`：本地持久化、后台调度、平台差异执行器
- `app/task_center`：任务中心视图、事件回放、失败恢复入口

这里它的一个额外价值是：  
它证明了“生成任务”和“资产更新任务”应该共用一套运行骨架，而不是每种任务自己实现一套半残的状态流。

### 3.4 记忆不是一层，而是多层

`Ai-Novel` 这里的记忆层非常值得我们吸收思路，但不能原样照搬命名或字段。

它至少拆出了这些层次：

- `story_memory`：故事级记忆
- `structured_memory`：实体、关系、事件、伏笔等结构化变更集
- `fractal_memory`：长篇压缩视角下的分层记忆
- `graph_context`：从实体关系图抽出的上下文块
- `worldbook`：偏稳定设定知识
- `project_table`：偏结构化规则表

这给我们的启发很大：

1. “记忆”不能只有一个大列表
2. 不同记忆层对应不同用途
3. 不是所有长期信息都该塞进 prompt 的同一段

对于 NovelAgent，我建议吸收成下面这种更贴近我们项目的话语：

- `setting memory`：世界、规则、术语、职业等级、数值体系
- `story memory`：剧情已发生事实、阶段摘要、章节摘要
- `entity memory`：角色、组织、地点、物品、身份映射
- `relation memory`：角色关系、阵营关系、事件因果
- `foreshadow memory`：伏笔、承诺、待回收线索
- `compressed long-form memory`：长篇压缩记忆 / 分形摘要

这一层适用于：

- 长任务模式 1：强相关
- 长任务模式 2：强相关
- 一般小说项目：中高相关
- 拆书：可作为导入结果资产

### 3.5 世界书自动更新、角色自动更新、图谱更新这类“派生资产任务”

它的 `worldbook_auto_update_service.py`、`characters_auto_update_service.py`、`graph_auto_update_service.py` 很值得注意。

精髓不是“自动更新”三个字，而是：

1. 正文生成后，能派生出资产修订建议
2. 建议先是结构化操作，不直接粗暴改资产
3. 结构化结果有合同、有修复、有重试
4. 资产更新是任务，不是悄悄副作用

这非常适合我们现在的方向，因为我们已经有：

- 章节写入
- 工具执行
- 长任务运行
- review / checkpoint

下一步完全可以把“正文完成后的资产派生更新”纳入共享执行链。

适合吸收成：

- `core/derivation`：资产派生建议合同、变更计划、人工确认门
- `core/review`：建议到执行的转换器
- `adapters/persistence`：资产变更应用器、备份、回滚
- `app`：更新建议面板、差异确认面板

### 3.6 向量检索不是孤立功能，而是上下文的一部分

`vector_rag_service.py`、`vector_kb_service.py`、`rerank_service.py`、`embedding_service.py` 这一串说明它把检索做成了真正可治理的系统：

- 向量后端可切换
- 支持混合检索与 rerank
- 有预算观测
- 有来源分组和每源上限
- 有 query / candidate / final injection 的控制

这部分不能直接照搬到我们当前本地优先、轻量桌面/移动形态里，但它给了我们两个特别重要的方向：

1. 检索层必须是“可裁剪、可解释、可观察”的
2. 检索结果要和上下文装配层联动，而不是独立返回一坨文本

适合我们吸收成：

- `core/retrieval`：检索请求、候选、排序、裁剪、来源预算
- `core/context`：检索片段进入上下文包的规则
- `adapters/indexing`：本地 sqlite / 文件索引 / 可选 embedding 后端
- `app`：检索调试、来源说明、预算说明

### 3.7 风格是资产，不是某个设置框

`style_resolution_service.py` 做得很干净：  
请求风格 > 项目默认风格 > 设置回退风格。

这点特别适合我们现在的策略优先架构。

吸收重点：

1. 风格应有独立 ID
2. 风格应允许项目默认值
3. 风格应允许任务/智能体/模式临时指定
4. 风格解析应是共享服务，不放进 UI 或提示拼接里

这不仅适用于一般小说项目，也直接适用于长任务模式 1 的“统一文风守恒”。

### 3.8 模型配置不应只有“一个默认模型”

`llm_contract_service.py`、`llm_task_preset_resolver.py`、`llm_capabilities` 这一层对我们也很有帮助。

它的可吸收精髓包括：

1. provider + model 要走合同解析，不靠散乱 if/else
2. 不同任务可以走不同模型预设
3. `base_url / max_tokens / context / capability / pricing` 应有统一解析层
4. 兼容模式、Responses API、不同网关的兼容修正应尽量下沉到传输与合同层

这和我们现在已经开始做的 provider catalog / capability baseline 是同一方向。

建议继续吸收成：

- `core/provider`：合同、能力、参数支持矩阵、任务级模型策略
- `adapters/llm`：OpenAI / Anthropic / Gemini / compatible / Responses API 传输适配
- `app/settings`：模型/接口设置页、任务级默认参数入口

### 3.9 导入导出不是备份，而是“资产迁移链”

它的 `import_export_service.py` 有两个很值得记住的点：

1. 导入文档不是只存原文，还会切 chunk、入向量、生成世界书/记忆提议
2. 导出是围绕项目与资产对象做的，而不是只导一个数据库快照

对我们来说，可吸收的重点是：

- 源文档导入后，应该进入“源文档资产层”
- 导入后可派生出世界书 / 记忆 / 风格 / 术语建议
- 导出对象可以细到项目、角色、风格、提示模板、生态包

这与我们的 `Markdown + SQLite` 双兼容设计也很贴。

### 3.10 章节生成、分析、重写是一个可闭环的工作流

从 `chapter_context_service.py`、`chapter_analysis`、`chapter_rewrite`、`plot_analysis_service.py` 可以看出，它不是把“写正文”和“分析正文”看成两件毫无关系的事。

可吸收精髓：

1. 章节生成有单独上下文组装服务
2. 章节分析有单独任务与输出合同
3. 分析结果可以反推重写任务
4. 上下文中会显式区分大纲、人物、风格、上一章、草稿尾部等来源

这非常适合我们继续补强：

- 生成 -> 分析 -> 重写 -> 回看
- 普通协作模式也能走这条链
- 长任务则把它纳入章节完成后的标准后处理

## 4. 对 NovelAgent 的架构落点

### `core`

Ai-Novel 最适合沉到我们 `core` 的东西：

- 资产类型划分原则
- Prompt 任务目录与 block 化渲染
- 上下文预算与分组裁剪
- 任务状态机、事件流、重试/恢复策略
- 风格解析规则
- 任务级模型策略与 provider 合同
- 记忆分层模型
- 检索候选裁剪与上下文注入规则
- 资产派生更新合同

### `adapters`

- 本地文件 / sqlite 持久化实现
- 导入文档切块与索引适配
- 向量 / rerank / embedding 可选后端
- 模型兼容传输层
- 后台运行调度器
- 导入导出包实现

### `app`

- Prompt Studio 应用状态
- 资产中心页面状态
- 任务中心视图状态
- 运行回放、调试包、派生建议确认流程
- 检索调试和预算解释页

### `ui`

- 资产中心页面
- Prompt Studio 面板
- 任务中心面板
- 运行记录 / 调试 / 错误重试入口
- 检索来源说明和裁剪可视化

## 5. 可服务的策略

### `project_strategy`

强相关：

- 一般小说项目
- 长篇项目
- 拆书项目

中相关：

- 短文集项目

原因：

- 它最强的是资产层和运行层
- 这些能力不只服务长任务，也服务普通创作项目

### `mode_strategy`

强相关：

- `seed_autopilot_novel`
- `full_outline_consensus`

中相关：

- 灵感模式
- 普通协作写作模式

可选增强：

- 分析后重写模式
- 导入后结构化整理模式

### `workflow_strategy`

最适合服务这些共享工作流：

- 生成章节
- 分析章节
- 按分析重写
- 资产派生更新
- 导入后资产提议
- 检索增强生成
- 长任务阶段回放与失败恢复

## 6. 与现有设计的融合点

### 6.1 与我们的资产层融合

它能直接强化我们已经在做、但还没完全走到位的几个方向：

- 风格中心
- 伏笔中心
- 导入导出包
- 结构化记忆
- 项目内源文档资产

### 6.2 与我们的长任务架构融合

它很适合补强我们长任务的这几块：

- 任务事件流
- 运行状态恢复
- 资产自动派生更新
- 长篇压缩记忆
- 章节完成后的后处理链

### 6.3 与我们的 provider / tool / transport 体系融合

它对我们最现实的帮助是：

- 补充任务级模型配置思路
- 补充 Responses API 兼容回退思路
- 补充 provider/model 合同校验思路
- 补充不同兼容层的能力暴露口径

### 6.4 与 `Markdown + SQLite` 双兼容设计融合

它虽然本身偏数据库化，但其对象分类很适合映射为我们的“双轨表达”：

- 面向用户：Markdown / 目录 / 可浏览文档
- 面向运行：SQLite 索引 / 结构化视图 / 快速检索

也就是说，我们吸收它的“结构”，不必吸收它的“全数据库依赖”。

## 7. 不应吸收的部分

### 7.1 Web SaaS 壳层

不吸收：

- 登录注册
- 多租户项目成员体系
- 管理员用户管理
- LinuxDo OIDC
- 服务器部署形态

原因：

- 与我们当前本地优先路线不一致
- 会把桌面/移动端产品重心拉偏

### 7.2 后端先行的状态组织

不吸收：

- 一切以服务端数据库为绝对中心的状态表达
- 强依赖 Redis / RQ / Postgres / pgvector 的产品前提

原因：

- 我们需要 GUI / CLI 共用核心
- 我们需要移动端可落地
- 我们要优先适配 `Markdown + SQLite` 双兼容

### 7.3 直接照搬字段、Prompt、接口形状

虽然它是 MIT，法律上比 GPL 宽松，但我们这里仍然不建议直接搬：

- prompt 文本
- 表结构
- API 字段
- 页面组织

原因：

- 我们已经有自己的策略模式和项目结构
- 直接搬会破坏现有解耦边界

## 8. 后续实施候选

### 近期可做

1. 把 Prompt 任务目录和 block 化模板系统继续正式化
2. 把风格解析服务从“文本段”推进到“风格资产 + 解析优先级”
3. 把任务运行事件流和重试策略继续下沉到共享 runtime
4. 把源文档导入资产正式接到项目资产层
5. 把故事记忆 / 结构化记忆 / 伏笔 / 图谱的归属彻底理顺

### 中期可做

1. 做检索预算观测与上下文来源可视化
2. 做资产派生更新建议链
3. 做分形长篇记忆或长篇压缩摘要层
4. 做任务级模型预设

### 暂缓观察

1. 向量后端多实现并存
2. 更复杂的外部 KB / rerank 体系
3. 完整的 Web 式管理后台能力

## 9. 当前结论

如果只用一句话概括 `Ai-Novel` 对我们的价值，那就是：

它提醒我们，`NovelAgent` 不该只是“会写正文的聊天器”，而应该是一个把小说项目拆成稳定资产、共享运行时、可观察 Prompt 系统与可恢复任务流的本地创作平台。

它最适合作为我们后续这几条线的参考源：

- Prompt 资产层
- 运行时层
- 记忆分层
- 检索上下文层
- 任务级模型合同层
