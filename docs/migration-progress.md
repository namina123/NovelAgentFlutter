# NovelAgent Flutter 迁移进度文档

最后更新：2026-05-24

## 当前结论

当前项目已经不只是空壳：

- 工作台可以加载项目、浏览资源、打开文档、编辑文档、保存文档
- 会话栏顶部模型 / 智能体选择已经接成真实选择器，不再只是伪下拉展示
- 文档工具栏的“渲染”已经改成当前 Markdown 文档级切换，不再把中宽布局误切进常驻文档工作区
- 资源树目录默认折叠，目录标题追加直接下级计数，占位 `README.md` 对用户隐藏
- 生态页可以浏览项目级与内置生态条目
- 生态页可以创建项目级智能体、技能、技能组、智能体组，并真实落盘
- 生态页可以打开项目内源文件进入工作区编辑
- 生态页可以预检并导入 `.customization.json` 生态包
- 生态页可以生成生态根索引和本地市场索引
- 项目级智能体 / 智能体组已经进入共享生成链和子智能体链
- CLI 与 GUI 已共用生态包预检、导入、索引生成和生态包导出核心链

但项目还没有达到“与旧项目别无二致”的状态，剩余主要缺口已经继续缩小到 Prompt Debug 组合页、生态导出 UI 入口，以及更完整的最终打包回归。

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

### 12. 生态页编辑闭环补齐

- 新增 `EcosystemEntryEditorService`
- 生态页项目级条目现在可以直接拉起表单编辑，而不是只能打开源文件手改
- 支持：
  - 项目级 `AGENT.md`
  - 项目级 `SKILL.md`
  - 项目级 `skill_group.json`
  - 项目级 `agent_group.json`
- 保存时会：
  - 重新渲染标准文件内容
  - 支持改 ID 后迁移到新路径
  - 删除旧路径
  - 刷新生态快照并回选新条目
- 删除时只删除项目级条目，不会动内置条目

### 13. 长任务链路树 / 回放 / 日志视图补齐一轮

- core 新增 `TaskChainViewService`
- `workflowChainView` 不再只是平铺节点，已恢复为按 `plan_id` 分组的链路视图
- `saveWorkflowChainSnapshot` 现在同时落：
  - `tracking/task_chain_views/*.json`
  - `tracking/task_chain_views/*.md`
- 任务中心新增：
  - 链路树页签
  - 最近长任务运行记录列表
  - 最近受控连续运行记录列表
  - 两类记录的 Markdown 回放 / 日志视图

### 14. CLI 命令组继续拆分

- 新增独立 `review` 命令组：
  - `list`
  - `show`
  - `types`
  - `create-task`
  - `repair-task`
- 新增独立 `template` 命令组：
  - `list`
  - `show`
  - `preview`
  - `save`
  - `delete`
  - `restore`
- 这样 `workflow` 不再继续挤进审稿 / 模板职责

### 15. 工具宿主能力补齐一轮

- `reorder_project_file` 不再返回未执行占位
- 新增内部排序元数据：
  - `.novel_agent/project_tree_order.json`
- 资源树 / CLI / 工作区列举现在都会应用同一份同级排序结果
- 内部排序元数据不会出现在普通项目资源树中
- `request_gateway_tool` 现在已经真正接通：
  - `fetch_url_content`
  - `search_internet`
  - `run_command`
- `generate_image` 不再返回旧式 `notExecuted` 占位，而是进入真实 gateway 分发分支，当前先保留为受参数约束的轻量实现
- 新增桌面端进程执行器 `DesktopProcessRunner`
- 新增适配器测试：
  - `project_tree_order_service_test.dart`
  - `project_gateway_tool_executor_test.dart`

### 16. 设置页与工作台交互修整一轮

- 接口设置：
  - 不再向用户暴露接口内部 `id`
  - 新建接口时由标题自动生成内部 `id`
  - 名称冲突时自动追加 `_1`、`_2`
  - 协议改为下拉选择，当前只开放：
    - OpenAI Compatible
    - Anthropic Compatible
  - 不再在接口页维护“默认接口 / 默认模型”
- 模型设置：
  - 改为单独维护接口选择、模型 ID、兼容上下文长度、应用上下文长度、流式模式、API 模式
  - 去掉默认智能体 ID 与自动保存草稿开关
- 主题设置：
  - 收缩为稳定可用的主题模式切换
  - 工作台主面板、按钮、资源树、编辑区等自绘组件已开始响应亮暗主题
- 权限页 / 工具策略页：
  - 模式切换现在会真实改写开关集合，不再只是改一行文案
- 工作台：
  - 二栏模式已支持拖拽调宽
  - 三栏改为更接近 VSCode 的连续分栏，不再显示成三张卡片夹分割线
  - 左栏操作区改为紧凑工具条，资源树成为主视图
- 资源树改为可展开目录结构
- 默认隐藏 `.json / .jsonl / .novel_agent`，避免用户误改内部结构
- 顶层目录按创作认知顺序重排，而不是纯字典序

### 17. 模型运行参数真实接线一轮

- 新增共享执行视图服务：
  - `ModelExecutionProfileService`
  - `ProviderRequestOptionsService`
- 设置文件中的模型默认参数现在已经真正进入 GUI / CLI / 长任务共用运行链：
  - `stream`
  - `temperature`
  - `top_p`
  - `top_k`
  - 深度思考开关与强度
  - 自定义高级参数条目
- 智能体层的模型重写也已接入执行链，不再只是 core 中孤立可用：
  - `thinking_enabled`
  - `thinking_effort`
  - `temperature`
  - `top_p`
  - `advanced_model_overrides`
- OpenAI 兼容网关已经开始真正透传这些请求参数，而不是只固定发送 `model + messages + tools`

### 18. Responses API 当前结论

- 已确认：`Responses API` 支持非流式请求
- 因此，“API 模式 = Responses API” 时，不应禁用“是否流式”开关
- 当前产品策略：
  - 默认仍是 `聊天 API`
  - 默认仍是“流式请求”
  - `Responses API` 相关设置先保留，但真实 HTTP 分流尚未完成
- 当前不要把 `Responses API` 误当成“只能流式”
- 当前也不要把 `Responses API` 假装成已经完全接通；它还处于“设置已保留、事实已确认、网关分流待补”的状态

### 19. 网络代理与共享生成入口补齐一轮

- 代理设置现在改为更贴近用户视角：
  - 代理模式只分为“系统网络环境 / 自定义代理”
  - 协议头允许留空，也可选：
    - `HTTP`
    - `SOCKS5`
  - 自定义代理拆成独立字段：
    - `代理 IP`
    - `代理端口`
    - `代理用户名（可选）`
    - `代理密码（可选）`
- 代理端口范围已收敛到共享策略：
  - 新增 `NetworkProxyPortPolicy`
  - GUI 输入与设置持久化统一复用同一套 `1-65535` 固定合法范围
- OpenAI 兼容网关现在会真正吃到设置页网络参数：
  - 自定义代理优先覆盖系统代理
  - 支持代理认证
  - 协议头留空时，仍按通用代理地址输入解释执行
- GUI / CLI / 长任务运行时三条链路都已补齐 `networkSettings` 传递：
  - 普通会话生成
  - CLI `workflow draft`
  - 长任务正文执行
  - 长任务后处理执行
- 去掉了几处过于内部化的用户可见文案：
  - `ToolCore: ...`
  - `上下文准备中 · 等待模型读取会话与项目信息`
  - 设置页中关于“临时代理”的旧迁移期说明

## 已验证

最近一次通过验证：

- `flutter analyze` in `apps/novel_agent_app`
- `flutter test` in `apps/novel_agent_app`
- `dart analyze` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart workflow help` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart review help` in `apps/novel_agent_cli`
- `dart run bin/novel_agent.dart template help` in `apps/novel_agent_cli`
- `dart test` in `packages/novel_agent_core`
- `dart analyze` in `packages/novel_agent_adapters`
- `dart test` in `packages/novel_agent_adapters`
- `flutter build windows --release` in `apps/novel_agent_app`

## 当前仍存在的明确缺口

### 生态系统

- Flutter 侧生态包导出入口还没做成单独 UI

### 共享运行链与更深交互

- 审稿中心目前已能看报告、建修复任务，但“直接发起审稿执行”的更完整引导仍可继续细化
- 模板页已能编辑、预览、保存、恢复、删覆盖，但还没有独立的 prompt debug 组合页
- `Responses API` 真实网关分流仍未补齐，目前运行链默认仍走 Chat API 兼容实现

### 工具与宿主适配

- 生态导出 GUI 入口仍未补齐
- `generate_image` 目前是轻量 gateway 分支，不是完整供应商图片工作流

## 当前工作原则

- 先消灭空入口，再做体验打磨
- 先走真实用例，再做表单壳
- 不把业务逻辑压进控制器
- 能抽服务就抽服务，能放 core 不放 app

## 下一步精确入口

恢复时从这里继续：

1. 补生态页生态包导出 UI 入口
2. 做独立 prompt debug 组合页
3. 补 `Responses API` 的真实 HTTP 分流，而不是只保留设置项
4. 继续把图片类 gateway 做成更完整的供应商 / 输出文件闭环
5. 做 Android 打包回归

## 恢复注意事项

- 若上下文压缩，优先读取本文件
- 不要回退到“只做 UI 壳”的路线
- 不要把新逻辑继续堆进 `AppShellController`
- 大块功能进入前，优先抽独立 service / use case / adapter
