# SQLite 与 Markdown 双兼容设计

最后更新：2026-05-25

## 目标

本项目必须同时满足三件事：

1. 用户可以继续以 Markdown / 普通文件的方式理解和编辑项目
2. 系统可以用 SQLite 做结构化索引、关系查询、恢复加速和跨视图投影
3. GUI 与 CLI 不能各自长出一套存储语义

因此，双兼容不是“双写一份随缘同步”，而是明确分工：

- `Markdown / 普通文件` 负责用户可见、可检查、可迁移的内容层
- `SQLite` 负责结构化索引、关系层、检索层、恢复层
- `core` 只依赖合同，不依赖具体是 Markdown 还是 SQLite

## 总原则

### 1. 用户可编辑叙事资产以 Markdown 为主

以下内容默认以 Markdown / 常规文件为主表达：

- 项目规格
- 风格
- 世界设定
- 角色卡
- 大纲 / 卷纲 / 章纲
- 草稿 / 正文
- 可读的模式摘要
- 可读的运行回放

### 2. SQLite 不抢“用户主编辑入口”

SQLite 的职责不是替代 Markdown，而是：

- 建索引
- 记稳定 ID
- 记关系
- 记状态投影
- 支撑筛选 / 图谱 / 统计 / 恢复

### 3. UI 树默认强调 Markdown，隐藏内部存储

资源树与普通浏览默认：

- 展示用户资产目录
- 展示用户会关心的 Markdown 摘要 / 回放
- 隐藏 `.novel_agent/`
- 隐藏 SQLite 文件
- 隐藏内部 JSON 状态文档

## 分层职责

### Core

只定义：

- 资产模型
- 模式状态模型
- 稳定 ID 规则
- 存储 port
- Markdown 摘要渲染规则
- SQLite 可投影的结构化字段语义

### Adapters

只负责：

- Markdown / JSON 真落盘
- SQLite 真建表、读写、迁移
- 文件路径解析
- 数据同步

### App / CLI

只负责：

- 调用 use case
- 展示结构化结果
- 控制哪些内容可见

## 项目文件层级

### 用户可见层

这些目录继续作为用户主视图：

- `specs/`
- `styles/`
- `outline/`
- `volume_outlines/`
- `chapter_outlines/`
- `drafts/`
- `chapters/`
- `world/`
- `characters/`
- `summaries/`
- `knowledge/`
- `inspiration/`
- `tasks/`
- `reviews/`

对长任务模式，会继续复用或新增这类可读摘要：

- `tracking/modes/<mode_id>/guidance.md`
- `tracking/long_task/*.md`
- `tracking/task_chain_views/*.md`

### 内部隐藏层

统一放到：

- `.novel_agent/`

建议结构：

```text
.novel_agent/
  project_tree_order.json
  modes/
    <mode_id>/
      guidance_state.json
  sqlite/
    novel_agent.db
```

说明：

- `project_tree_order.json`：已有资源树排序元数据
- `modes/.../guidance_state.json`：模式引导的隐藏结构化状态文档
- `sqlite/novel_agent.db`：结构化索引库

### 可见与隐藏的关系

以第一种长任务模式为例：

- 可见：`tracking/modes/seed_autopilot_novel/guidance.md`
- 隐藏：`.novel_agent/modes/seed_autopilot_novel/guidance_state.json`
- 隐藏：`.novel_agent/sqlite/novel_agent.db`

用户看 Markdown，程序恢复看隐藏状态，筛选/查询走 SQLite。

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

### 2. 一张表只承担一种结构语义

第一种长任务模式先落：

- `mode_guidance_state`
- `mode_guidance_answer`

后续资产层继续扩：

- `style_profile`
- `style_rule`
- `entity_identity`
- `entity_alias`
- `foreshadow_record`
- `foreshadow_link`

### 3. SQLite 记录必须能回指文件

每条 SQLite 记录都应尽量回指：

- `markdown_path`
- `state_path`

## 浏览与显示方案

### 资源树

默认资源树：

- 只展示用户目录
- 只展示有意义的 Markdown / 普通文件
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

1. 主浏览仍从文件树进入
2. 结构化中心从 SQLite 加速查询
3. 任何结构化条目都要能回到原始 Markdown 或摘要 Markdown
4. 任何隐藏内部文件都不默认暴露给用户

## 第一种长任务模式的落地规则

第一种模式 `seed_autopilot_novel` 先按下面规则实施：

### Markdown 侧

- `tracking/modes/seed_autopilot_novel/guidance.md`

用于：

- 给用户阅读当前模式收束结果
- 给模型在真正建队列前读取
- 给 CLI 直接检查当前阶段

### 隐藏状态侧

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

## GUI / CLI 共享方式

GUI 与 CLI 一律只通过 core port / use case 操作：

- load mode guidance state
- save mode guidance state
- answer guidance question
- build summary markdown

真正的 SQLite 细节只允许存在于 adapters。

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

双兼容的正式基线是：

1. `Markdown` 负责用户主内容与可读摘要
2. `SQLite` 负责结构化索引与关系查询
3. `.novel_agent/` 承担内部状态与数据库文件
4. 资源树默认隐藏内部层
5. GUI / CLI 只经由共享 core 合同访问，不直连底层实现
