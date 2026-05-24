# NovelAgent Flutter 迁移进度文档

最后更新：2026-05-24

## 当前结论

当前项目已经不只是空壳：

- 工作台可以加载项目、浏览资源、打开文档、编辑文档、保存文档
- 生态页可以浏览项目级与内置生态条目
- 生态页可以创建项目级智能体、技能、技能组、智能体组，并真实落盘
- 生态页可以打开项目内源文件进入工作区编辑
- 生态页可以预检并导入 `.customization.json` 生态包
- 生态页可以生成生态根索引和本地市场索引
- 项目级智能体 / 智能体组已经进入共享生成链和子智能体链
- CLI 与 GUI 已共用生态包预检、导入、索引生成和生态包导出核心链

但项目还没有达到“与旧项目别无二致”的状态，剩余主要缺口已经从“空页面”缩小到更深的交互链、生态编辑深水区、若干工具桩和体验对齐。

## 本轮前已完成

### 架构与基础

- 建立 `agent.md`
- 建立 core / adapters / app / ui 分层
- 建立桌面与移动端默认根目录策略

### 核心逻辑迁移

- 上下文预算与组装
- 会话记录与历史
- 生成记录
- revision diff
- task queue / task runtime
- workflow runtime、chapter atomic、long task 的一批核心纯逻辑
- 调度层：run center contract、scheduler tick plan、unattended strategy、next batch plan 等

### 生态与包结构

- `AGENT.md / SKILL.md` 解析与构建基础
- 项目级与内置技能加载
- `load_agent_skill` 真正接入项目技能作用域
- 项目级 `skill_groups / agent_groups` 目录扫描与加载

### GUI 侧已打通

- 项目创建、项目加载
- 资源树显示与中文映射
- 文档工作区编辑与保存
- 生态页浏览、创建、打开源文件

## 本轮新增完成

### 1. 维护恢复文档

- 新建本文件 `docs/migration-progress.md`
- 新建顺序文档 `docs/migration-order.md`

### 2. 文档编辑闭环

- 工作区正文从只读改成可编辑
- 增加 `activeDocumentDirty`
- 保存、打开、生成后正确清理脏状态

### 3. 生态页真实落盘

- 创建智能体、技能、技能组、智能体组时生成脚手架内容
- 用统一文本写入用例写到项目目录
- 刷新生态快照并自动选中新条目
- 自动打开源文件进入工作区

### 4. 项目级生态分组加载

- `skill_groups`
- `agent_groups`

### 5. 项目级协作智能体进入共享运行链

- `GenerateDraftUseCase`
- `SubAgentExecutionService`

现在都能合并项目级智能体与智能体组，而不是只依赖内置协作素材。

### 6. 生态包共享链补齐

- 新增共享预检用例 `PreviewCustomizationBundleImportUseCase`
- 新增共享导入用例 `ImportCustomizationBundleUseCase`
- 新增共享导出用例 `SaveCustomizationBundleUseCase`
- 新增共享本地市场索引用例 `SaveCustomizationMarketIndexUseCase`
- 新增共享根目录索引生成 `GenerateCustomizationIndexesUseCase`
- 修正 `SKILL.md / AGENT.md` 渲染，保留 `id + name`，不再丢显示名

### 7. GUI / CLI 同源生态入口

- Flutter 生态页增加导入弹层
- Flutter 生态页支持预检摘要、导入状态和索引生成状态
- CLI 新增：
  - `project import-bundle`
  - `project generate-index`
  - `project save-bundle`

### 8. 项目创建进一步补齐

- 新建项目时自动生成四个生态根目录的 `index.json`

### 9. 任务 / 审稿 / 模板 GUI 真接线

- Flutter 新增并接通：
  - `taskCenter`
  - `reviewCenter`
  - `promptTemplates`
- 三页都不再只是目录浏览壳，而是接到共享服务：
  - `ProjectWorkflowRuntimeService`
  - `ProjectReviewReportService`
  - `ProjectPromptTemplateService`
- 新增 app 层小型视图映射服务，避免继续把文案与展示规则堆进 `AppShellController`
- 工作台入口与文档工具栏入口改为真实跳转 / 真实动作：
  - 任务按钮 -> 长任务中心
  - 审稿按钮 -> 审稿中心
  - 模板按钮 -> 模板页
  - 文档栏审稿 -> 为当前文档创建审稿任务并跳任务中心
  - 文档栏大纲 -> 自动尝试打开常见大纲文件

### 10. CLI workflow 共享运行入口扩展

- `workflow` 不再只有 `draft`
- 已新增：
  - `create`
  - `list`
  - `next`
  - `preflight`
  - `chain`
  - `plan`
  - `prepare`
  - `run-once`
  - `run-next`
  - `run-queue`
  - `postprocess-once`
  - `postprocess-next`
  - `complete-next`
  - `pause`
  - `resume`
  - `accept-revision`
  - `rollback-revision`

### 11. 审稿报告落盘链补齐

- `run_continuity_check` 现在不再只写 Markdown
- 现在会同时写：
  - `reviews/.../*.json`
  - `reviews/.../*.md`
- 这样 GUI 审稿列表、详情页、修复任务生成就能稳定复用同一份结构化报告

## 已验证

最近一次通过验证：

- `flutter analyze` in `apps/novel_agent_app`
- `flutter test test/widget_test.dart` in `apps/novel_agent_app`
- `dart analyze` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart workflow help` in `apps/novel_agent_cli`
- `dart test` in `packages/novel_agent_core`
- `dart test` in `packages/novel_agent_adapters`
- `dart analyze` in `packages/novel_agent_adapters`

## 当前仍存在的明确缺口

### 生态系统

- 表单化编辑生态条目
- Flutter 侧生态包导出入口还没做成单独 UI

### 共享运行链与更深交互

- 长任务中心虽然已接运行动作，但还没有旧项目那种更完整的链路树、运行记录回放、日志视图
- 审稿中心目前已能看报告、建修复任务，但“直接发起审稿执行”的更完整引导仍可继续细化
- 模板页已能编辑、预览、保存、恢复、删覆盖，但还没有独立的 prompt debug 组合页
- CLI 目前重点补了 workflow；`review / template` 还没有拆成独立命令组
- host capability / process runner 仍有底层适配器待实现

### 工具与宿主适配

- `call_sub_agent`
- `rename_project`
- `reorder_project_file`
- `request_gateway_tool`

这些旧工具名仍处于已识别但未真正执行的状态。

## 当前工作原则

- 先消灭空入口，再做体验打磨
- 先走真实用例，再做表单壳
- 不把业务逻辑压进控制器
- 能抽服务就抽服务，能放 core 不放 app

## 下一步精确入口

恢复时从这里继续：

1. 继续把旧项目里剩余“运行记录 / 长任务链路树 / 日志 / prompt debug”那批更深交互迁到 Dart
2. 补生态页已有条目的表单化编辑闭环
3. 继续清理工具调度里仍是 `notExecuted` 的旧工具名
4. 最后做一轮 Windows 打包前的整体回归

## 恢复注意事项

- 若上下文压缩，优先读取本文件
- 不要回退到“只做 UI 壳”的路线
- 不要把新逻辑继续堆进 `AppShellController`
- 大块功能进入前，优先抽独立 service / use case / adapter
