# NovelAgentFlutter 大重构会话顺序文档

最后更新：2026-05-25

## 0. 文档目的

这份文档不是“长期路线图”，而是：

`把大重构拆成一轮一轮真正能做完的会话任务`

这里的每个条目都按下面的标准设计：

- 一次提问内应当可以完成
- 预计改动量控制在一轮约 `<= 2000` 行上下
- 必须有清晰收口，不留半套骨架
- 必须符合：
  - 单一职责
  - 单文件不可过重
  - 策略模式优先
  - GUI / CLI 共核
  - app / ui 不反向吞业务
  - adapters 不反向变业务中心

这份文档服务的不是“怎么想”，而是“下一轮具体怎么干”。

## 1. 使用方式

后续真正开工时，不要一句“继续做重构”就直接扑进代码。

应该按下面流程：

1. 先选一个会话条目
2. 按该条目的“必读文档”快速回收上下文
3. 完整执行它的“必须完成”
4. 严守它的“本轮不要做”
5. 完成后更新对应文档与进度

也就是说：

- 一轮只打一个结
- 不跨条目乱跳
- 不在同一轮里同时改目录结构、长任务监督器、图谱页、模板工坊这种多主线内容

## 2. 全局硬约束

每一轮都必须遵守下面这些规则。

### 2.1 文件职责约束

- 一个文件尽量只放一个职责类
- 单文件超过 `400` 行时必须自检
- 单文件接近 `700` 行必须拆
- 不允许再把新逻辑继续堆进：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

### 2.2 分层约束

- `core` 放合同、领域模型、策略、use case、workflow 规则
- `adapters` 放存储、provider、runtime 宿主、索引、导入导出实现
- `app` 放装配、视图状态、导航
- `ui` 放页面和控件

禁止：

- `ui` 直接管项目文件读写
- `app` 直接写 SQL
- `core` import Flutter
- `core` 直接依赖 adapter 细节

### 2.3 存储策略约束

项目主存储策略必须明确：

- `markdown_project_store`
- `sqlite_project_store`

如果某一轮涉及存储，不允许再把这两者写成含糊混存。

### 2.4 注释约束

实现代码里的新逻辑、复杂分支、状态转换、映射规则，继续要求中文注释，但只写有价值的解释，不写空注释。

### 2.5 验证约束

每轮至少做一种验证：

- 单元测试
- 探针脚本
- 小范围真实链路验证
- 文档回填核对

## 3. 会话任务总览

这次大改建议按下面顺序推进。

顺序是有意设计过的：

1. 先目录与存储策略
2. 再 runtime 合同
3. 再全局长任务系统
4. 再第二种长任务运行基准
5. 再共享资产层和分析闭环
6. 最后再把 GUI 工作台与中心页接细

## 4. Session 01：项目目录结构与存储策略合同落地

### 本轮目标

把“项目主存储策略”和“新目录结构”正式落到 core / adapters 合同里。

这是整个重构最根本的一轮，必须先做。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/major-redesign-master-plan.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/architecture.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 在 core 中建立项目主存储策略合同：
   - `ProjectStorageStrategy`
   - `ProjectContentRepository`
   - `ProjectReadableProjectionService`
2. 在 core 中建立项目目录结构描述合同：
   - 可见目录定义
   - 隐藏目录定义
   - 目录映射规则
3. 在 adapters 中建立：
   - `markdown_project_store` 基础仓储壳
   - `sqlite_project_store` 基础仓储壳
   - 存储策略识别器
4. 把“创建项目元数据必须带 storage strategy”立成正式模型
5. 文档回填：
   - 更新相关设计文档中的实际代码落点

### 本轮重点拆耦

- 存储策略合同不能塞进某个项目控制器
- 目录结构定义不能散落到多个 widget / controller 常量里
- Markdown 与 SQLite 仓储不要做成一个巨型万能 repository

### 本轮不要做

- 不改 UI 页面
- 不做数据库表细节
- 不做跨策略迁移
- 不接长任务中心

### 完成判定

- 新建项目的领域模型已经能声明主存储策略
- core 已经能表达不同存储策略下的主内容来源
- adapters 已有可继续扩展的双策略入口

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 01 执行。先阅读 agent.md、docs/major-redesign-master-plan.md、docs/storage-dual-compatibility-design.md、docs/architecture.md、docs/responsibility-matrix.md。把项目目录结构与存储策略合同正式落到 core/adapters：建立 ProjectStorageStrategy、ProjectContentRepository、ProjectReadableProjectionService，以及 markdown_project_store / sqlite_project_store 的基础仓储壳与策略识别器。注意单一职责、不要让单文件过重、不要碰 UI、不要顺手做数据库细节。完成后更新相关文档并说明哪些文件是后续扩展点。
```

## 5. Session 02：项目创建链改造成“项目类型 + 存储策略 + 运行基准”三段式

### 本轮目标

重做项目创建 use case 和 app 装配链，让创建流程在领域上先正确。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/migration-order.md`

### 必须完成

1. 建立新的项目创建请求模型：
   - 项目类型
   - 存储策略
   - 若为长任务项目，则可挂运行基准选择
2. 改造 core 的项目创建 use case
3. 改造 app 层的创建流程装配，不直接先碰最终 UI 样式
4. 为后续长任务运行基准选择留稳定接口

### 本轮重点拆耦

- “长任务项目”与“长任务运行基准”不是一个枚举
- 创建项目 use case 不要直接知道 Flutter 页面
- app 层不要硬编码所有项目类型行为

### 本轮不要做

- 不做完整漂亮 UI
- 不接长任务实际运行
- 不做项目打开逻辑大改

### 完成判定

- 新建项目领域请求已包含项目类型与主存储策略
- 长任务项目已能表达“下一步需要选择运行基准”

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 02 执行。先阅读 docs/major-redesign-master-plan.md、docs/storage-dual-compatibility-design.md、docs/migration-order.md。重构项目创建链：把创建项目正式改成“项目类型 + 主存储策略 + 长任务运行基准预留”的三段式领域流程。重点改 core use case 和 app 装配，先不做最终 UI 美化，不要让项目类型、模式、运行基准混在一个枚举里。
```

## 6. Session 03：目录生成器与 Markdown 项目骨架重排

### 本轮目标

先把 `markdown_project_store` 的目录生成器做对。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/legacy-project-audit.md`

### 必须完成

1. 建立目录骨架生成器：
   - 可见目录
   - 隐藏目录
2. 落地新的默认 Markdown 项目结构
3. 让资源树映射能理解新结构
4. 处理旧占位目录 / 无意义 README 清理策略

### 本轮重点拆耦

- 目录生成器独立成 adapter / service，不塞进 controller
- 目录显示中文映射与真实英文目录分离
- 资源树排序逻辑不要和目录创建器互相耦合

### 本轮不要做

- 不做 SQLite 项目真正内容建模
- 不改长任务监督器
- 不顺手改工作台布局

### 完成判定

- 新建 Markdown 项目可以生成新的可见/隐藏双层结构
- 资源树不再依赖旧占位做展示

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 03 执行。先阅读 docs/major-redesign-master-plan.md、docs/storage-dual-compatibility-design.md、docs/legacy-project-audit.md。只动 markdown_project_store 的目录生成器和项目骨架：建立新的可见/隐藏双层目录结构、真实英文目录与中文映射分离、资源树适配新结构。不要碰 SQLite 项目真实建模，不要碰长任务运行系统。
```

## 7. Session 04：SQLite 项目主内容仓储骨架与文本字段规则

### 本轮目标

把 `sqlite_project_store` 的基础仓储壳和“正文不是 Markdown blob”这条硬规则落成代码。

### 预计改动量

- 约 `1200 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/storage-dual-compatibility-design.md`
- `docs/major-redesign-master-plan.md`

### 必须完成

1. 建立 SQLite 项目主内容仓储基础接口实现
2. 立正文文本字段 / 分段字段模型
3. 建立最小可用建库 / 表结构初始化壳
4. 为 Markdown 导出投影预留 codec 接口

### 本轮重点拆耦

- SQLite schema 初始化不要长进一个万能服务
- 正文文本模型与 Markdown codec 分开
- 不要让 project repository 兼任 migration manager

### 本轮不要做

- 不做跨策略迁移
- 不做完整 UI
- 不做大规模资产表

### 完成判定

- SQLite 项目策略已经能合法表达正文主内容存储
- 文本模型中没有“整篇 Markdown 文档串入库”的偷懒路径

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 04 执行。先阅读 agent.md、docs/storage-dual-compatibility-design.md、docs/major-redesign-master-plan.md。实现 sqlite_project_store 的基础仓储壳，重点落地正文纯文本/分段文本模型与最小建库初始化，明确禁止整篇 Markdown blob 作为正文主存储。不要做跨策略迁移，不要把 schema、repository、codec 写成大一统文件。
```

## 8. Session 05：RuntimeBaseline、RunInstance 与长任务全局运行合同

### 本轮目标

把长任务从“项目内功能”提升为“全局运行系统”的领域合同。

### 预计改动量

- 约 `1000 ~ 1700` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/long-task-mode-2-implementation-order.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`

### 必须完成

1. 建立：
   - `RuntimeBaseline`
   - `RunInstance`
   - `LongTaskRunRegistry` 合同
   - `LongTaskHeartbeatPolicy` 合同
2. 建立长任务状态机基础模型
3. 建立全局运行实例与项目的关联模型

### 本轮重点拆耦

- 运行实例不是页面状态
- 运行基准不是模式策略本身
- 状态机模型不要塞进 adapter

### 本轮不要做

- 不接 Flutter 页面
- 不做自动恢复实现
- 不接现有运行详情 UI

### 完成判定

- core 已经能表达“一个项目外部也能继续存在的长任务运行实例”

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 05 执行。先阅读 docs/major-redesign-master-plan.md、docs/long-task-mode-1-architecture.md、docs/long-task-mode-2-implementation-order.md、docs/absorption/10-projects/deepseek-tui/README.md。把 RuntimeBaseline、RunInstance、LongTaskRunRegistry、LongTaskHeartbeatPolicy 和基础长任务状态机立到 core，明确长任务是全局运行对象而不是页面状态。不要接 UI，不要先写自动恢复实现。
```

## 9. Session 06：LongTaskSupervisor 与全局注册表 adapter 落地

### 本轮目标

把全局长任务监督器的 adapter 层落地成最小可运行版本。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/absorption/10-projects/deepseek-tui/README.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 落地：
   - `LongTaskSupervisor`
   - `LongTaskRunRegistry` 本地持久化实现
2. 建立心跳轮询基础调度
3. 建立运行实例加载 / 保存 / 状态更新链

### 本轮重点拆耦

- supervisor 只管监督与调度，不兼任 workflow runtime
- run registry 不兼任项目仓储
- 心跳 scheduler 不要和 Flutter 生命周期耦死

### 本轮不要做

- 不做完整自动恢复策略
- 不做长任务中心 UI
- 不改章节工作流

### 完成判定

- 运行实例可持久化
- app 重启后理论上可恢复 registry 信息

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 06 执行。先阅读 docs/major-redesign-master-plan.md、docs/absorption/10-projects/deepseek-tui/README.md、docs/responsibility-matrix.md。实现 LongTaskSupervisor、LongTaskRunRegistry 的本地持久化版和心跳基础调度。重点保持 supervisor、registry、scheduler 三者职责分离，不要接 Flutter 页面，不要顺手改章节 workflow。
```

## 10. Session 07：长任务中心 app 壳与全局入口

### 本轮目标

在 app 层建立独立的长任务中心壳，不再把这类逻辑塞进工作台或大控制器。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/architecture.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 新建 app 子域：
   - `long_task_station/`
2. 新建独立 controller / view model
3. 接全局运行实例列表、暂停/恢复/停止入口壳
4. 路由与导航接线

### 本轮重点拆耦

- 长任务中心不应放在工作台 controller 内
- 页面状态与 runtime registry 查询分开
- 动作接口与展示模型分开

### 本轮不要做

- 不做最终 UI 打磨
- 不接章节详情树
- 不做自动恢复细节

### 完成判定

- GUI 已有独立的全局长任务中心入口

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 07 执行。先阅读 docs/major-redesign-master-plan.md、docs/architecture.md、docs/responsibility-matrix.md。给 Flutter app 新建独立的 long_task_station 子域，接全局运行实例列表和暂停/恢复/停止入口壳，重点避免再把逻辑堆进 app_shell_controller 或工作台 controller。先求结构正确，不求最终 UI。
```

## 11. Session 08：第二种长任务运行基准 core 落地

### 本轮目标

把 `chapter_collaboration_autorun` 作为真正的 `RuntimeBaseline` 落到 core。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/long-task-mode-2-implementation-order.md`
- `docs/long-task-mode-1-architecture.md`

### 必须完成

1. 定义第二种基准：
   - 章级自动推进
   - 章级 gate
   - 章级 review / repair 接点
2. 复用现有章节工作流与 review / repair 共享能力
3. 建立“当前章完成后派生下一章”的 baseline 规则

### 本轮重点拆耦

- baseline 规则与 mode guidance 分离
- baseline 规则与 supervisor 分离
- 不要再造第二套 review / repair 逻辑

### 本轮不要做

- 不做 app UI
- 不做真正自动恢复
- 不重写现有章节生成链

### 完成判定

- 第二种运行基准已是 core 中的正式概念，而不是一堆临时 if/else

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 08 执行。先阅读 docs/major-redesign-master-plan.md、docs/long-task-mode-2-implementation-order.md、docs/long-task-mode-1-architecture.md。把 chapter_collaboration_autorun 作为正式 RuntimeBaseline 落到 core，复用现有章节 workflow 与 review/repair 能力，建立章级自动推进和章级 gate 规则。不要改 UI，不要再造第二套审稿返工系统。
```

## 12. Session 09：长任务运行基准选择链接入项目创建

### 本轮目标

把“长任务项目 -> 运行基准选择”真正接回项目创建链。

### 预计改动量

- 约 `1000 ~ 1700` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/long-task-mode-2-implementation-order.md`
- `docs/migration-order.md`

### 必须完成

1. 长任务项目创建后进入独立运行基准选择流程
2. 把选择结果写入项目创建元数据与运行初始配置
3. 让 mode 1 / mode 2 都能作为正式选项存在

### 本轮重点拆耦

- 运行基准选择不耦合最终工作台
- 项目创建结果与运行实例初始化分层

### 本轮不要做

- 不做最终卡片视觉优化
- 不把所有长任务引导流程一起塞进同一页

### 完成判定

- 长任务项目创建流程在领域上已经完整闭环

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 09 执行。先阅读 docs/major-redesign-master-plan.md、docs/long-task-mode-2-implementation-order.md、docs/migration-order.md。把“长任务项目 -> 独立运行基准选择”正式接回项目创建链，让 mode 1 / mode 2 作为正式选项写入项目元数据和初始运行配置。不要追求最终 UI 视觉，重点先把领域流程闭环。
```

## 13. Session 10：共享角色卡 / 组织卡 / 风格绑定合同收束

### 本轮目标

把最常用的共享资产合同重新收束，准备服务一般小说与长任务共用。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/strategy-first-predesign.md`

### 必须完成

1. 收束：
   - `AgentProfile`
   - `ProjectAgentBinding`
   - `ProjectAgentModelOverride`
   - 角色卡 / 组织卡主模型
   - 风格绑定主模型
2. 明确项目级智能体模型参数覆写合同
3. 明确角色卡与名字解耦的稳定 ID 规则

### 本轮重点拆耦

- 智能体身份和项目内模型绑定分开
- 角色身份和显示名分开
- 风格资产和智能体系统提示词分开

### 本轮不要做

- 不做完整资产中心 UI
- 不做图谱页
- 不做导入导出

### 完成判定

- 一般小说项目与长任务项目都可复用同一批核心资产合同

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 10 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/strategy-first-predesign.md。重收束角色卡/组织卡/风格绑定和项目级智能体模型覆写合同，重点落实 AgentProfile、ProjectAgentBinding、ProjectAgentModelOverride，以及角色稳定 ID 与显示名解耦。不要做完整 UI，不要碰导入导出。
```

## 14. Session 11：伏笔、时间线、关系图共享能力收束

### 本轮目标

把 `MuMuAINovel` 最值得吸收的一批共享写作对象继续正式化。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/long-task-mode-1-architecture.md`

### 必须完成

1. 收束：
   - `foreshadow_record`
   - `timeline_record`
   - `relationship_record`
2. 建立最小共享关联规则
3. 为一般小说与长任务都提供统一引用入口

### 本轮重点拆耦

- 伏笔状态机不要和长任务 mode 绑死
- 时间线与关系图不要先做 UI 驱动模型
- 分析结果对象与资产对象分开

### 本轮不要做

- 不做图谱页面
- 不做复杂可视化
- 不接自动审稿联动

### 完成判定

- 伏笔、时间线、关系已成为独立共享资产合同

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 11 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/long-task-mode-1-architecture.md。把伏笔、时间线、关系图先收束成共享资产合同和最小关联规则，重点服务一般小说与长任务共用。不要做图谱 UI，不要直接把这些资产和长任务 mode 绑死。
```

## 15. Session 12：分析结果对象与“一键重写计划” core 闭环

### 本轮目标

把 `MuMuAINovel` 的“分析 -> 建议 -> 重写”精华正式拉进 core。

### 预计改动量

- 约 `1200 ~ 1900` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/migration-order.md`

### 必须完成

1. 建立：
   - 章节分析结果对象
   - 建议对象
   - 重写计划对象
2. 支持：
   - 整章重写
   - 局部重写
   - 只输出建议
3. 让建议可转为正式任务

### 本轮重点拆耦

- 分析结果不等于 provider 原始响应
- 重写计划不等于直接重写执行
- 分析与重写不要耦在单个 service

### 本轮不要做

- 不做完整分析页 UI
- 不顺手做图谱页
- 不做导入导出

### 完成判定

- core 已经可以表达“分析后可选择性执行的重写计划”

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 12 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/migration-order.md。把章节分析结果、建议对象、重写计划对象和建议转任务闭环落到 core，支持整章重写、局部重写、只输出建议三种路径。不要把 provider 原始响应直接暴露成分析对象，不要做完整 UI。
```

## 16. Session 13：项目级导入导出与资产 bundle 合同

### 本轮目标

把版本化导入导出先立成合同，不先卷复杂 UI。

### 预计改动量

- 约 `1200 ~ 2000` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/storage-dual-compatibility-design.md`

### 必须完成

1. 建立 bundle 合同：
   - 项目包
   - 角色卡包
   - 风格包
   - 模板包
2. 建立版本头、校验、冲突预检模型
3. 建立 core 的导入预检 use case 壳

### 本轮重点拆耦

- bundle 合同不等于 zip 实现
- 导入预检不等于真正写入
- 项目包与生态包区分清楚

### 本轮不要做

- 不做最终导入向导 UI
- 不写完整 zip 实现
- 不做在线工坊

### 完成判定

- 版本化 bundle 体系已经能被 core 正式表达

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 13 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/storage-dual-compatibility-design.md。把项目级导入导出和资产 bundle 体系先立成 core 合同：项目包、角色卡包、风格包、模板包、版本头、校验和冲突预检。不要做最终 UI，不要直接写成 zip 工具实现。
```

## 17. Session 14：灵感模式与创意收束链

### 本轮目标

把 `MuMuAINovel` 的灵感模式正式拉成共享能力，而不是普通聊天附属。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `docs/mumuainovel-absorption-analysis.md`
- `docs/major-redesign-master-plan.md`
- `docs/long-task-mode-1-architecture.md`

### 必须完成

1. 定义灵感模式领域对象
2. 定义灵感收束阶段
3. 定义从灵感到：
   - premise
   - style
   - world
   - characters
   的映射入口

### 本轮重点拆耦

- 灵感模式不是长任务私有功能
- 灵感模式不是普通聊天的几条预设文案
- 创意收束结果与项目创建分离

### 本轮不要做

- 不做完整灵感工作台 UI
- 不做最终多轮视觉引导
- 不与长任务 mode 1 过度绑死

### 完成判定

- 灵感模式已经成为共享可复用能力

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 14 执行。先阅读 docs/mumuainovel-absorption-analysis.md、docs/major-redesign-master-plan.md、docs/long-task-mode-1-architecture.md。把灵感模式定义成共享能力：建立灵感对象、收束阶段、以及到 premise/style/world/characters 的映射入口。不要把它做成长任务私有功能，不要先做完整 UI。
```

## 18. Session 15：app 层大控制器拆分与工作台边界收口

### 本轮目标

真正对 `app_shell_controller.dart` 下手，按新架构拆壳。

### 预计改动量

- 约 `1400 ~ 2000` 行

### 必读文档

- `agent.md`
- `docs/major-redesign-master-plan.md`
- `docs/responsibility-matrix.md`

### 必须完成

1. 切出：
   - shell 装配职责
   - workbench 职责
   - long_task_station 职责
   - project_creation 职责
2. 把不该留在大控制器里的状态搬走
3. 保证旧功能不回归

### 本轮重点拆耦

- 不要只是“把一个大文件改名成两个大文件”
- controller 只保留投影与协调
- runtime 与 project IO 逻辑继续留在 core/adapters

### 本轮不要做

- 不顺手改 UI 风格
- 不顺手改 provider 层
- 不做新功能扩张

### 完成判定

- `app_shell_controller.dart` 明显瘦身
- app 子域边界开始稳定

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 15 执行。先阅读 agent.md、docs/major-redesign-master-plan.md、docs/responsibility-matrix.md。对 app_shell_controller.dart 做真正拆分，把 shell/workbench/long_task_station/project_creation 的职责拆出去，重点避免“一个大文件变两个大文件”的假拆分。不要顺手扩新功能，不要去改 provider 或底层 IO。
```

## 19. Session 16：目录、运行、资产三线联调与回归

### 本轮目标

不是继续扩功能，而是把前面几轮已经立起来的三条主线做一次联调回归。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `docs/major-redesign-master-plan.md`
- `docs/major-redesign-session-order.md`
- `docs/migration-progress.md`

### 必须完成

1. 验证目录新结构
2. 验证项目主存储策略创建链
3. 验证长任务全局运行实例链
4. 验证第二种运行基准可创建并进入运行态
5. 回填文档与测试缺口

### 本轮重点拆耦

- 只修联调暴露的问题
- 不顺手再开新主线

### 本轮不要做

- 不加新页面
- 不加新模式
- 不加新 bundle 类型

### 完成判定

- 新骨架第一次完成贯通回归

### 建议提示词

```text
按 docs/major-redesign-session-order.md 的 Session 16 执行。先阅读 docs/major-redesign-master-plan.md、docs/major-redesign-session-order.md、docs/migration-progress.md。做目录、存储策略、长任务全局运行、第二种运行基准四条链的联调回归，只修联调暴露的问题，不开新主线。完成后回填文档和验证结果。
```

## 20. 当前建议的真正起点

如果现在立刻开工，必须从：

- `Session 01：项目目录结构与存储策略合同落地`

开始。

原因很简单：

- 目录结构是根
- 主存储策略是根
- 后面的运行、资产、长任务、导入导出，都要建立在这两个根稳定以后

## 21. 结束判断

当下面四件事都成立时，才算这轮大改真正进入正轨：

1. 项目已能明确区分 `markdown_project_store` 与 `sqlite_project_store`
2. 长任务已经不是项目页附属功能，而是全局运行实例
3. 第二种长任务运行基准已正式成为 core 概念
4. 共享资产层已经不再被模式私有化
