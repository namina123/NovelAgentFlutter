# 项目存储策略与兼容设计

最后更新：2026-05-25

## 目标

本项目必须同时满足四件事：

1. 系统支持多种项目主存储策略
2. 用户可以选择以 Markdown / 普通文件为主的项目
3. 系统也可以支持以 SQLite 为主内容存储的项目
4. GUI 与 CLI 不能各自长出一套存储语义

因此，这里的“双兼容”首先是“策略双轨兼容”，不是“双写一份随缘同步”。

当前第一阶段明确支持两种主存储策略：

- `markdown_project_store`
- `sqlite_project_store`

二者的共同要求是：

- `core` 只依赖合同，不依赖具体是 Markdown 还是 SQLite
- 上层工作流、策略、任务、资产模型尽量复用
- 底层通过不同 adapter / codec / repository 实现

## 存储策略定义

### 1. `markdown_project_store`

主内容落在分散的 Markdown / 普通文本文件中。

### 2. `sqlite_project_store`

主内容落在 SQLite 中。

但必须注意：

- 正文内容应存为正文文本或结构化分段文本
- 不允许把整篇 Markdown 文档原样塞进 SQLite 正文字段冒充 SQLite 存储
- Markdown 只能作为导出、投影、预览、互转结果

### 3. 后续扩展策略

后续允许加入更多轻量策略，但前提是：

- 仍然通过统一的 `ProjectStorageStrategy` 合同接入
- 不破坏既有项目的可识别性
- 不让 controller 直接感知底层细节

## 总原则

### 1. 先分清“项目主存储策略”，再谈兼容

每个项目都必须有明确的主存储策略元数据。

### 2. Markdown 策略下，用户可编辑叙事资产以 Markdown 为主

以下内容默认以 Markdown / 常规文件为主表达：

- 项目规格
- 风格
- 世界设定
- 角色卡
- 大纲 / 卷纲 / 章纲
- 草稿 / 正文
- 可读的模式摘要
- 可读的运行回放

### 3. SQLite 策略下，SQLite 才是主内容事实来源

在 `sqlite_project_store` 中：

- 正文、章纲、角色说明、风格说明等内容应存为数据库字段或分段记录
- 项目事实来源是 SQLite
- 如需导出 Markdown，则由 codec / renderer 生成

### 4. SQLite 不抢 Markdown 策略的“用户主编辑入口”

在 `markdown_project_store` 中，SQLite 的职责不是替代 Markdown，而是：

- 建索引
- 记稳定 ID
- 记关系
- 记状态投影
- 支撑筛选 / 图谱 / 统计 / 恢复

### 5. UI 树默认展示“当前策略的用户主内容”

资源树与普通浏览默认：

- 展示当前策略下的用户主内容投影
- 隐藏 `.novel_agent/`
- 对 Markdown 项目隐藏 SQLite 文件
- 隐藏内部 JSON 状态文档

## 分层职责

### Core

只定义：

- 资产模型
- 模式状态模型
- 稳定 ID 规则
- 存储策略 port
- Markdown codec 合同
- SQLite codec 合同
- 跨策略迁移合同
- SQLite 可投影的结构化字段语义

### Adapters

只负责：

- Markdown 真落盘
- SQLite 真建表、读写、迁移
- 文件路径解析
- 当前策略识别
- 跨策略导入 / 导出 / 迁移

### App / CLI

只负责：

- 调用 use case
- 展示结构化结果
- 控制哪些内容可见
- 在创建项目时选择主存储策略

## 项目文件层级

### 用户可见层

这些目录默认作为 `markdown_project_store` 的用户主视图：

- `premise/`
- `outlines/story/`
- `outlines/volumes/`
- `outlines/chapters/`
- `drafts/chapters/`
- `drafts/scenes/`
- `assets/characters/`
- `assets/organizations/`
- `assets/locations/`
- `assets/items/`
- `assets/styles/`
- `assets/world/`
- `assets/foreshadows/`
- `assets/relationships/`
- `assets/timeline/`
- `tasks/plans/`
- `tasks/reviews/`
- `tasks/revisions/`
- `analysis/`
- `exports/`

兼容期内，以下目录仍允许作为“高级但可见的兼容层”存在：

- `agents/`
- `agent_groups/`
- `skills/`
- `skill_groups/`
- `prompts/`
- `tracking/modes/<mode_id>/guidance.md`
- `tracking/long_task/*.md`
- `tracking/task_chain_views/*.md`
- `runs/`
- `backups/`

### 内部隐藏层

统一放到：

- `.novel_agent/`

建议结构：

```text
.novel_agent/
  state/
  runtime/
  runs/
  threads/
  tasks/
  checkpoints/
  indexes/
  cache/
  settings/
  logs/
  modes/
    <mode_id>/
      guidance_state.json
  sqlite/
    novel_agent.db
```

说明：

- `state/`：项目级隐藏状态文档与恢复锚点
- `runtime/`：运行态中间产物与宿主恢复信息
- `runs/` / `threads/` / `tasks/` / `checkpoints/`：长任务与会话运行记录
- `indexes/` / `cache/` / `settings/` / `logs/`：索引、缓存、项目内设置和日志
- `modes/.../guidance_state.json`：模式引导的隐藏结构化状态文档
- `sqlite/novel_agent.db`：
  - 在 Markdown 项目中是索引库
  - 在 SQLite 项目中是主内容库 + 索引库

### 可见与隐藏的关系

以第一种长任务模式为例：

- 可见：`tracking/modes/seed_autopilot_novel/guidance.md`
- 隐藏：`.novel_agent/modes/seed_autopilot_novel/guidance_state.json`
- 隐藏：`.novel_agent/sqlite/novel_agent.db`

Markdown 项目里，用户主看 Markdown，程序恢复看隐藏状态，筛选/查询走 SQLite。
SQLite 项目里，用户主看投影视图，程序事实来源是 SQLite。

## SQLite 建模原则

### 1. 不把大 JSON blob 塞进 SQLite

SQLite 表字段要尽量拆平：

- 稳定 ID
- 记录类型
- stage / field / relation
- 文本值
- 枚举值
- 时间戳
- 对应 Markdown 路径
- 对应隐藏状态路径

### 2. SQLite 项目正文不存 Markdown 文档串

如果是 `sqlite_project_store`：

- 正文表应存正文纯文本、片段文本、段落文本或结构化块
- 不应直接存“带 Markdown 标记的整篇正文文件文本”
- Markdown 仅作为导出或兼容投影使用

### 3. 一张表只承担一种结构语义

第一种长任务模式先落：

- `mode_guidance_state`
- `mode_guidance_answer`

当前 Session 04 已落的 SQLite 主内容基础表：

- `project_store_meta`
- `body_text_document`
- `body_text_segment`

其中：

- `body_text_document` 只负责正文文档级元数据与纯文本总览
- `body_text_segment` 只负责段级正文内容
- 两张表共同表达 `plain_text / segmented_text`
- 明确不提供 `markdown_blob` 这种正文主存储格式

后续资产层继续扩：

- `style_profile`
- `style_rule`
- `entity_identity`
- `entity_alias`
- `foreshadow_record`
- `foreshadow_link`

### 4. SQLite 记录必须能回指主内容来源或投影来源

每条 SQLite 记录都应尽量回指：

- `markdown_path`
- `state_path`
- `content_origin_kind`

## 浏览与显示方案

### 资源树

默认资源树：

- Markdown 项目：展示用户目录与 Markdown / 普通文件
- SQLite 项目：展示用户目录投影视图，而不是裸数据库表
- 不展示 `.novel_agent/`
- 不展示 SQLite

### 结构化面板

结构化面板不直接显示数据库文件，而是显示投影结果：

- 角色列表
- 别名映射
- 风格规则
- 伏笔状态
- 模式阶段完成情况
- 章节关系 / 图谱

### Markdown 与 SQLite 混合浏览

规则如下：

1. Markdown 项目主浏览仍从文件树进入
2. SQLite 项目主浏览进入的是投影后的内容树或结构化视图
3. 结构化中心从 SQLite 查询
4. 任何结构化条目都要能回到其主内容来源或可读投影视图
5. 任何隐藏内部文件都不默认暴露给用户

## 第一种长任务模式的落地规则

第一种模式 `seed_autopilot_novel` 先按下面规则实施：

### Markdown 项目

- `tracking/modes/seed_autopilot_novel/guidance.md`

用于：

- 给用户阅读当前模式收束结果
- 给模型在真正建队列前读取
- 给 CLI 直接检查当前阶段

### 通用隐藏状态侧

- `.novel_agent/modes/seed_autopilot_novel/guidance_state.json`

用于：

- 精准恢复当前阶段
- 保留 stage / field 级答案
- 供未来模式 2/3 复用相同状态机骨架

### SQLite 侧

- `mode_guidance_state`
- `mode_guidance_answer`

用于：

- 快速展示当前卡在哪个阶段
- 筛选已完成 / 未完成阶段
- 做未来的结构化摘要与模式对比

如果项目是 `sqlite_project_store`，则：

- `guidance_state` 与 `guidance_answer` 可以直接成为主事实来源
- `guidance.md` 只作为用户可读投影按需生成

## GUI / CLI 共享方式

GUI 与 CLI 一律只通过 core port / use case 操作：

- load mode guidance state
- save mode guidance state
- answer guidance question
- build summary markdown
- export readable projection
- migrate project storage strategy

真正的 SQLite 细节只允许存在于 adapters。

## 当前代码落点

### Core 合同

- `packages/novel_agent_core/lib/src/project/project_storage_strategy.dart`
  - 项目主存储策略枚举
- `packages/novel_agent_core/lib/src/ports/project_content_repository.dart`
  - 主内容初始化合同
- `packages/novel_agent_core/lib/src/project/project_readable_projection_service.dart`
  - 可读投影合同
- `packages/novel_agent_core/lib/src/project/project_directory_layout.dart`
  - 目录布局描述对象
- `packages/novel_agent_core/lib/src/project/project_directory_layout_service.dart`
  - 按存储策略解析目录布局
- `packages/novel_agent_core/lib/src/project/project_manifest.dart`
- `packages/novel_agent_core/lib/src/project/project_manifest_codec_service.dart`
- `packages/novel_agent_core/lib/src/project/project_descriptor.dart`
  - 三者已带 `storage_strategy` 元数据

### Adapters 基础壳

- `packages/novel_agent_adapters/lib/src/storage/markdown_project_content_repository.dart`
- `packages/novel_agent_adapters/lib/src/storage/sqlite_project_content_repository.dart`
  - 两个主内容初始化壳当前只负责最小目录与占位文件
- `packages/novel_agent_adapters/lib/src/storage/markdown_project_readable_projection_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/sqlite_project_readable_projection_service.dart`
  - 两个可读投影壳当前只负责最小可读入口
- `packages/novel_agent_adapters/lib/src/storage/delegating_project_content_repository.dart`
- `packages/novel_agent_adapters/lib/src/storage/delegating_project_readable_projection_service.dart`
  - 按存储策略做分发
- `packages/novel_agent_adapters/lib/src/storage/project_storage_strategy_resolver.dart`
  - 从项目根目录识别主存储策略

### 已接入的创建链

- `packages/novel_agent_core/lib/src/use_cases/create_project_workspace_use_case.dart`
  - 项目创建改为“目录布局 + 主内容初始化 + 可读投影”三段式
- `packages/novel_agent_adapters/lib/src/bootstrap/adapter_bundle.dart`
  - 标准装配已暴露双策略仓储与投影服务
- `apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart`
  - Flutter app 已接入新的创建链

## 下一步扩展点

### 目录结构重排扩展点

- `ProjectDirectoryLayoutService`
  - Session 03 真正切换到新目录树时，优先改这里，不要散改 controller / widget 常量

### SQLite 主内容建模扩展点

- `SqliteProjectContentRepository`
- `ProjectSqlitePathService`
  - Session 04 在这里补最小建库与表结构初始化，不要把 schema 细节塞回创建用例

### Markdown/SQLite 可读投影扩展点

- `MarkdownProjectReadableProjectionService`
- `SqliteProjectReadableProjectionService`
  - 后续补 richer projection / export 时继续沿这两个入口扩展

### 跨策略迁移扩展点

- `ProjectContentRepository`
- `ProjectReadableProjectionService`
  - 当前只定义“初始化”和“可读投影”，跨策略迁移合同应在后续单独新增，不要反向污染这轮的基础壳

## 策略识别与项目创建

### 创建项目时必须选择

项目创建时必须至少确定：

- `storage_strategy`

当前允许值：

- `markdown_project_store`
- `sqlite_project_store`

### 如果完全互转做不到

那就按项目策略强隔离：

- Markdown 项目按 Markdown 规则运行
- SQLite 项目按 SQLite 规则运行
- 共享上层策略与工作流
- 分开底层存储实现

## 迁移顺序

### 第一批

- 第一种长任务模式的 guidance state
- Markdown 摘要
- 隐藏 JSON 状态
- SQLite 索引表

### 第二批

- style profile
- world rule set
- entity identity / alias
- foreshadow record

### 第三批

- 图谱关系
- 导入导出包索引
- 分析结果 / 重写建议索引

## 当前结论

当前正式基线已经明确改为“存储策略双轨制”：

1. 项目必须有明确的主存储策略
2. `markdown_project_store` 中，Markdown 是主内容，SQLite 是索引/恢复层
3. `sqlite_project_store` 中，SQLite 是主内容，Markdown 只是导出/投影/兼容层
4. SQLite 项目正文不允许简单存 Markdown 文档串
5. 如果暂时做不到完全互转，就在创建项目时明确选择策略并各自隔离运行
6. GUI / CLI 只经由共享 core 合同访问，不直连底层实现
