# 职责拆分与错位审计分析

日期：2026-06-17

关联锚点：

- `docs/architecture.md`
- `docs/important/project-unreasonable-areas-audit-2026-06-15.md`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `apps/novel_agent_app/lib/features/project_assets/application/services/project_reference_extraction_execution_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/provider_connection_validation_service.dart`

---

## 1. 这份文档解决什么

这轮不讨论单点 bug，也不讨论某个功能好不好用，而是专门回答一个更底层的问题：

**当前项目里，哪些职责已经放错了地方，导致复用困难、协作困难、测试困难，或者让后续继续拆分变得越来越痛。**

这里的“职责错位”主要指五类问题：

1. 本应是壳层装配的逻辑，开始变成业务中心。
2. 本应是共享运行时的逻辑，被绑在 GUI 控制器里。
3. 本应拆成多个编排服务的逻辑，被堆进单个 runtime 巨石。
4. 本应是投影层的逻辑，开始夹带正式规则判断。
5. 本应在 core / adapters / app 三层分开的事实源，被某个中间层重新揉成一团。

---

## 2. 总体判断

这轮审计后的总体结论很明确：

### 2.1 方向是对的，但“边界退化”已经再次出现

项目的架构基线其实写得很清楚：

- `app` 只该是 GUI 壳层
- `core` 只该承载共享规则
- `adapters` 只该承载实现与运行时桥接
- 不鼓励新的巨型中心文件

但从当前主链实现看，已经出现了新的边界退化：

1. `AppShellController` 正在重新长成应用级业务中枢。
2. `WorkbenchWorkspaceController` 与 `WorkbenchConversationController` 不是“两个薄控制器协作”，而是两个次级业务中心。
3. `ProjectWorkflowRuntimeService` 虽然完成了很多能力，但已经明显超出“单一 runtime 编排器”的合理体积与职责范围。
4. 参考提取主链比长任务主链干净一些，但也开始显露“execution facade 变成半个业务中心”的趋势。

### 2.2 当前最严重的问题，不是文件大，而是“层级语义被跨层偷走”

如果只是文件长，还可以看成暂时欠拆。

但现在更关键的问题是：

1. GUI controller 在决定 workflow 行为。
2. runtime service 在自己 new 一整串次级服务并默认决定组合方式。
3. view-data service 在调用接近正式业务语义的解析与验证。
4. app feature service 在承担一部分本应由共享执行层收口的提取策略。

这会直接带来四个后果：

1. CLI 很难真正复用 GUI 已经验证过的行为。
2. 多入口行为容易分叉。
3. focused test 大量依赖壳层对象，回归脆弱。
4. 多会话并行协作时，极易出现“你动我的中心，我动你的中心”。

---

## 3. 本轮最重要的证据

本轮复核到的几个关键体积锚点：

1. `AppShellController`：`4711` 行
2. `WorkbenchWorkspaceController`：`2282` 行
3. `WorkbenchConversationController`：`2548` 行
4. `ProjectWorkflowRuntimeService`：`5688` 行
5. `ProjectReferenceExtractionRuntimeService`：`472` 行
6. `ModelSettingsViewDataService`：`369` 行
7. `ProviderConnectionValidationService`：`168` 行

这些数字本身不是定罪依据，但和 `docs/architecture.md` 中：

1. 超过 `400` 行就要复核职责
2. 超过 `700` 行原则上必须拆

结合起来看，就已经不是“小超标”，而是核心主链持续依赖超大对象存活。

---

## 4. 分层现状判断

## 4.1 app 层

当前 app 层里存在两种对象：

1. 合理的壳层对象
2. 已经承担共享业务判断的伪壳层对象

合理的部分主要是：

- 页面
- widget
- 单纯 view data projection
- 用户动作转发
- 平台 picker / dialog / UX 壳

问题主要集中在 controller 级对象。

## 4.2 adapters 层

adapters 层已经承担了很多正确职责：

- runtime 编排
- provider 协议接线
- 本地存储
- 提取与长任务的宿主桥接

但部分 runtime 服务已经从“适配器层编排”膨胀成“业务总中心”。

## 4.3 core 层

core 这轮相对不是问题中心。

反而恰恰说明：很多本应继续被抽进 core 或继续拆成独立 core/adapters 合同的东西，还停留在 app controller 或 adapter 巨石里。

---

## 5. 具体错位点

## 5.1 P0: `AppShellController` 已经重新变成应用级总业务中心

### 现象

`AppShellController` 当前同时承担了：

1. 导航切换
2. settings action handler
3. task center / review center / ecosystem 等多个 action handler
4. project creation 委派
5. provider connection test
6. workflow runtime 入口桥接
7. reference extraction execution 装配
8. 一部分长任务动作分发
9. 设置刷新与投影刷新
10. 子控制器组装与跨控制器协调

这已经不是单纯的 app shell。

### 为什么错位

按 `docs/architecture.md`，app shell 应该只做：

1. composition root
2. 导航壳
3. 生命周期接线
4. 外层状态汇总

但当前它不仅在“接”，还在“决定”：

1. 某类动作该走哪套 runtime
2. 某类设置动作该如何验证
3. 某些 workflow 工具动作如何直接映射到 runtime service
4. 某些 feature service 如何被即时构造和串起来

这导致它具备两个不该同时存在的身份：

1. 应用壳层
2. 跨 feature 业务调度中心

### 主要风险

1. 任何新 feature 都会倾向于继续接进这里。
2. 任何跨 feature 改动都容易落到这里硬接线。
3. 并行开发最容易冲突的就是这里。
4. 它会逐渐变成“只有它知道系统怎么活着”的对象。

### 正式建议

`AppShellController` 应继续瘦身为：

1. `ShellNavigationCoordinator`
2. `ShellFeatureAttachmentRegistry`
3. `ShellSettingsActionFacade`
4. `ShellRuntimeCommandBridge`

其中：

- shell 只保留外层装配与转发
- 具体业务动作桥接要继续下沉到 feature facade 或 runtime command service

---

## 5.2 P0: `WorkbenchWorkspaceController` 混合了项目工作区、导航跳转、设置持久化与导入编排

### 现象

`WorkbenchWorkspaceController` 当前至少同时承担：

1. 项目加载与切换
2. 资源树刷新与文档打开
3. 导入入口和导入执行
4. 项目类型转换入口
5. 与 long task station / settings / ecosystem / assets 的跳转
6. settings 静默保存
7. project long task summary 刷新
8. pending research action
9. draft recovery snapshot

### 为什么错位

工作区控制器本应只聚焦：

1. 当前项目工作区状态
2. 资源树 / 文档 / 工作区动作
3. 与 project workspace 直接相关的投影

但现在它已经把“工作区对象模型”和“应用跳转入口协调”揉在了一起。

特别明显的错位有：

1. 由 workspace controller 直接持有 `showSettings / showAgentEcosystem / showLongTaskStation / showProjectAssets`
2. 由 workspace controller 自己负责静默保存 app settings
3. 导入执行、类型转换、研究动作都从这里发出

这意味着“工作区”已经不只是工作区，而变成了项目级总入口。

### 主要风险

1. 后续如果 CLI 也要复用 project import / type transition / research action，会发现大量语义绑在 GUI 控制器里。
2. 工作区控制器不再能单独被当作“工作区子域”维护。
3. 任意项目级动作都容易继续往这个类里长。

### 正式建议

拆成至少三层：

1. `WorkbenchWorkspaceStateController`
   - 只管工作区状态、资源树、文档
2. `WorkbenchProjectActionFacade`
   - 只管项目级动作，如导入、类型转换、研究动作
3. `WorkbenchProjectNavigationBridge`
   - 只管跳转到 settings / assets / station / ecosystem

这样 workspace controller 才能重新回到“工作区对象控制器”。

---

## 5.3 P0: `WorkbenchConversationController` 混合了会话运行、开局语义、长任务启动、设置写回与附件链

### 现象

`WorkbenchConversationController` 当前同时承担：

1. 普通会话发送与流式运行
2. opening projection 刷新
3. mode guidance 进入与转换
4. 长任务启动与复用既有 workflow
5. 用户选项动作执行
6. conversation 附件选择与暂存
7. draft autosave 相关决策
8. settings 写回
9. tool/information permission 上下文拼装
10. 对 workspace controller 的回调协调

### 为什么错位

会话控制器本应主要负责：

1. 当前会话输入输出链
2. 会话运行期状态
3. 会话相关投影

但现在它承担了三类不该混在一起的职责：

1. 会话运行
2. 开局工程流转
3. 项目级 workflow 启动控制

尤其是这几个点最危险：

1. `opening.start_long_task_run` 相关动作直接在这里建链、跑队列
2. mode guidance / opening / workflow 进入逻辑在这里缠在一起
3. 它需要同时知道 workspace 当前文档、项目当前 profile、settings 写回、权限上下文、长任务 runtime

这不是“会话控制器懂得比较多”，而是“多个子域没有真正拆开”。

### 主要风险

1. 普通会话与长任务开局语义继续相互污染。
2. 单轮交互、开局引导、正式 workflow 启动共用一处大分发，后续越来越难测。
3. 任何关于用户选项、开局、长任务的修复都容易反复碰这一个类。

### 正式建议

至少继续拆为四块：

1. `ConversationRuntimeController`
   - 只管发送、流式、停止、错误恢复
2. `OpeningFlowController`
   - 只管 opening / mode guidance / 进入条件
3. `ConversationWorkflowLaunchBridge`
   - 只把开局动作桥接到 workflow runtime，不承载会话状态
4. `ConversationAttachmentFacade`
   - 只管附件拾取、暂存、可见性

`WorkbenchConversationController` 最终只应是薄协调层，而不是继续做业务中心。

---

## 5.4 P0: `ProjectWorkflowRuntimeService` 已经从“runtime service”膨胀成“长任务总系统”

### 现象

`ProjectWorkflowRuntimeService` 当前聚合了：

1. task definition / selection / queue option / stop policy / preflight
2. long task mode / run path / scheduler snapshot / prompt build
3. revision / review / checkpoint / gate
4. repair task / checkpoint follow-up / revision diff
5. permission approval resolution
6. reviewer dispatch
7. host-aware generate draft use case factory
8. run registry sync
9. postprocess result persistence
10. task center query surface

更重要的是，它不只是“依赖很多对象”，而是自己在构造链里默认 new 出大量次级服务。

### 为什么错位

runtime service 当然可以是编排中心，但不应该同时是：

1. 默认装配中心
2. 调度中心
3. 审稿中心
4. 修复分流中心
5. 权限决议中心
6. checkpoint 生命周期中心
7. revision 对比与落盘中心

这已经不再是“一个 service 协调多个 service”，而是“一个 service 拥有整个系统的局部宇宙”。

### 主要风险

1. 任意新长任务能力都会继续往这里塞。
2. review / checkpoint / repair / permission 这些本应可独立验证的能力，很难脱离这个类做真实复用。
3. 你后面想做第二类长任务、目标模式、watchdog 驱动连续任务时，会非常容易再次绑死在这里。

### 正式建议

这条链必须从“单 runtime 巨石”改成“runtime family”：

1. `WorkflowRuntimeFacade`
   - 对 app/cli 暴露统一入口
2. `WorkflowQueueRuntime`
   - 只管 task queue / task transition / next task
3. `WorkflowReviewRuntime`
   - 只管 review / reviewer dispatch / semantic review submission contract
4. `WorkflowCheckpointRuntime`
   - 只管 checkpoint review / follow-up / checkpoint action
5. `WorkflowRepairRuntime`
   - 只管 execution constraint repair / review repair / revision resolution
6. `WorkflowPostprocessRuntime`
   - 只管 postprocess / report / checkpoint postprocess persistence
7. `WorkflowPermissionBridge`
   - 只管 host tool permission / information permission / approval replay

`ProjectWorkflowRuntimeService` 应逐步退化成 facade，而不是继续拥有所有内部细节。

---

## 5.5 P1: `ProjectReferenceExtractionRuntimeService` 方向更健康，但已经出现“二次中心化”倾向

### 现象

相比长任务主链，参考提取 runtime 干净很多，它已经具备比较正确的结构：

1. path service
2. agent context service
3. source reader
4. mount service
5. continuity bridge
6. mount outcome resolver
7. proposal generator factory

但它当前仍然同时负责：

1. run id / package id / version id 生成
2. staging workspace 恢复
3. source language 推断
4. substrate run 执行
5. bundle export
6. project mount
7. continuity ledger bridge
8. continuous task sync

### 判断

这条链现在还没有失控，但如果后续继续加：

1. 批次续跑
2. watchdog 接管
3. 多阶段 extraction review
4. 用户审批/权限
5. 可视化审稿

那它也会很快复制 `ProjectWorkflowRuntimeService` 的膨胀路径。

### 正式建议

趁现在还不算太重，应提前冻结为：

1. `ReferenceExtractionRunCoordinator`
2. `ReferenceExtractionIdentityService`
3. `ReferenceExtractionPublicationService`
4. `ReferenceExtractionMountCoordinator`
5. `ReferenceExtractionLivenessBridge`

现在就拆，比以后带着更多状态拆要便宜很多。

---

## 5.6 P1: `ProjectReferenceExtractionExecutionService` 放在 app 层是合理的，但当前职责偏厚

### 现象

这个对象当前在 app 层承担：

1. source file picker 入口
2. settings / provider / model resolve
3. gateway 创建
4. request builder 调用
5. semantic continuation 重试循环
6. 用户侧状态文案生成

### 判断

它留在 app 层并不天然错误，因为：

1. 它确实是 GUI 用户动作的 execution facade
2. 它需要 file picker 和用户提示文案

但它现在已经不只是 facade，而是在承担部分正式执行策略：

1. 什么算“继续语义续跑”
2. 最多续跑几轮
3. 什么算“published projection result”

这类逻辑不应长期绑在 GUI service 里。

### 正式建议

保留 app 层 facade，但把以下内容下沉：

1. semantic continuation policy
2. extraction completion judgment
3. success / incomplete result classification contract

这样 app 层只保留：

1. 用户触发
2. 文件选择
3. 结果转成人话

---

## 5.7 P1: settings 投影链正在靠近正式业务规则边界

### `ModelSettingsViewDataService`

它当前做的很多事情本身是合理的：

1. 把 settings 持久化结构投影成 editor view data
2. 基于 runtime profile 拼装 UI 可见事实

但它也已经开始调用：

1. `ModelExecutionProfileService`
2. `ProviderProfileService`
3. `ProviderConnectionValidationService`

这说明它不只是 view projector，而是已经成为“设置页事实聚合器”。

这并不一定要立刻下刀拆，但需要明确定位：

- 它不是普通 widget helper
- 它是 app projection facade

如果后续让 settings page、CLI doctor、provider diagnostics、project runtime setup 都各自再做一份类似聚合，事实源会再次分裂。

### `ProviderConnectionValidationService`

它的体积不大，方向也基本对：

1. 统一产出 validation contract
2. 把协议、路由、fallback、可隐藏选项收成结构化结果

这类对象本身更像共享领域服务，而不是 app-only service。

### 正式建议

1. `ModelSettingsViewDataService` 继续留在 app，明确为“projection facade”。
2. `ProviderConnectionValidationService` 更适合逐步下沉到 core/adapters 共享层，至少变成 app/cli 可共用的正式合同服务。
3. 设置页未来不要再从 widget 或 controller 直接拼 provider/meta/request options 逻辑。

---

## 5.8 P1: adapters 层内存在“构造即策略”的倾向

### 现象

像 `ProjectWorkflowRuntimeService` 这类对象，不只是接收依赖，还会在构造函数里默认创建大量内部 service。

这会带来一个隐藏问题：

**运行时默认组合方式被类本身吞掉了。**

### 为什么麻烦

这样会导致：

1. 你以为自己在替换一个 service，实际上只是替掉一小段。
2. 真正的策略组合仍然藏在默认构造里。
3. CLI / GUI / probe / future docker runtime 想用不同组合方式时，会不断被默认装配逻辑顶回来。

### 正式建议

对大型 runtime family，要逐步把：

1. 默认装配
2. 正式执行
3. feature facade

彻底分开。

也就是：

- service 不再自己决定完整生态如何长出来
- bootstrap / bundle / composition root 决定默认拼法

---

## 6. 哪些地方没有明显放错

为了避免全盘否定，也要明确保留当前好的部分。

### 6.1 参考提取 runtime 链的分块意识是对的

`ProjectReferenceExtractionRuntimeService` 虽然还可继续拆，但它已经体现出：

1. path
2. agent context
3. mount
4. bundle export
5. continuity bridge

是分开的。

这条链的思路明显比长任务主链更健康，应作为后续治理模板。

### 6.2 provider compatibility 这轮新拆法是对的

新近完成的 API compatibility 收口已经证明：

1. route contract
2. request payload builder
3. stream adapter
4. response parser
5. gateway resolver

这种拆法是可行的。

也就是说，项目不是不会拆，而是某些旧主链还没按同等标准继续拆。

### 6.3 settings 的“先聚合再投影”方向是对的

虽然 settings facade 靠近业务边界，但比“widget 自己拼一堆 if/else”强得多。

这里该做的是继续明确 facade 身份，而不是退回散装判断。

---

## 7. 当前最值得优先收的职责错位顺序

如果下一阶段只按职责拆分角度推进，我建议优先级如下：

### 第一优先级

1. `ProjectWorkflowRuntimeService` runtime family 化
2. `WorkbenchConversationController` 从 opening / workflow launch / runtime send 三块中拆开
3. `WorkbenchWorkspaceController` 从 workspace state / project action / navigation bridge 三块中拆开

### 第二优先级

1. `AppShellController` 继续退回外层 facade
2. `ProviderConnectionValidationService` 下沉为共享合同服务
3. `ProjectReferenceExtractionExecutionService` 抽出 semantic continuation policy

### 第三优先级

1. `ProjectReferenceExtractionRuntimeService` 预防性拆分 publication / mount / identity
2. settings projection 链补清“正式事实源 vs UI 投影”边界

---

## 8. 对协作模式最重要的结论

用户之前反复强调的核心，其实不是“文件别太长”这么简单，而是：

**不能让并行会话最后都撞向同一个中心文件，然后彼此覆盖。**

从这个目标看，当前最不适合继续承受协作压力的文件就是：

1. `AppShellController`
2. `WorkbenchWorkspaceController`
3. `WorkbenchConversationController`
4. `ProjectWorkflowRuntimeService`

这四个对象如果不先按职责切碎，再继续多会话并行开发，几乎必然会反复出现：

1. 同一逻辑两个实现
2. 同一职责多个入口
3. 交叉修改无法安全合并
4. 修复只修半条链

所以这轮文档的核心结论可以收成一句话：

**当前项目最需要的，不是再补更多功能，而是把已经存在的主链中心对象拆回正式边界，让“一个职责只有一个正式出口”。**

---

## 9. 最终结论

这套架构并没有走错。

真正的问题是：随着能力快速接入，几个关键对象重新吸回了太多职责，开始偏离最初的边界纪律。

最明显的错位是：

1. app shell 重新中心化
2. workbench 双控制器重新业务中心化
3. workflow runtime 重新系统化巨石
4. reference extraction execution facade 开始夹带执行策略

而最值得肯定的部分是：

1. provider compatibility 新拆法是对的
2. reference extraction runtime 比较接近可维护形态
3. settings 聚合投影方向整体没错

下一阶段的正确动作，不是推翻重来，而是：

1. 保留已经可靠的合同层
2. 把错位职责从大控制器和大 runtime 中抽出来
3. 让 app / core / adapters 再次回到各自该承担的范围

只有这样，后面的 GUI、CLI、Docker、长任务、提取任务、多智能体协作，才不会继续在几个共享巨石上打结。
