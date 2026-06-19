# Product Design UI Audit 2026-06-18

本轮审计基于本地 `product-design` 技能的工作方式执行：从真实界面链路、view-model、文案和条件显示逻辑出发，专门抓以下几类问题：

- 测试残留或内部术语直接漏给用户
- 一眼看上去不像正式产品，而像开发中间态
- 信息层级过厚、重复、误导
- 某类项目不该看到的能力仍然暴露
- 能力存在，但入口命名不直观

## 本轮已确认并已落到源码的修正

1. `知识库项目` 的 `项目` 侧栏已经在源码里改为紧凑结构，不再保留原来那种厚重的“项目摘要”正文块。
   - 文件：
     - [apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_project_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_project_panel.dart)

2. `知识库项目` 的 `文件` 侧栏已经在源码里按 `projectTypeId == knowledge_base` 隐藏 `资料与设定` 区块。
   - 文件：
     - [apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart)

3. `knowledge_base` 原始项目类型 id 不再应该出现在副标题里，本轮已经补上正式中文标签，并停止给知识库项目拼接不合语境的运行模式文案。
   - 文件：
     - [apps/novel_agent_app/lib/features/workbench/application/services/project_subtitle_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/project_subtitle_view_data_service.dart)

4. `budget_exhausted` 这类内部 omission reason 不应直接端给用户，本轮已经补上最基础的人话映射。
   - 文件：
     - [apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart)

## 主要发现

### P1. 知识库项目副标题链路长期存在“内部枚举直接显示”的风险

虽然本轮已补 `knowledge_base`，但当前副标题服务仍是“已知映射显示中文，未知值直接回退原始字符串”的模式。只要后面再新增项目类型、存储策略、运行基线或运行模式，没有同步补文案，就会再次把内部 id 直接展示给用户。

- 典型风险表现：
  - `knowledge_base`
  - 未来新增 project type id
  - 未来新增 runtime mode id
- 文件：
  - [apps/novel_agent_app/lib/features/workbench/application/services/project_subtitle_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/project_subtitle_view_data_service.dart)
  - [apps/novel_agent_app/lib/shared/services/runtime_label_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/shared/services/runtime_label_service.dart)

建议：
- 给项目类型、运行模式、存储策略建立“用户可见标签必须显式声明”的规则
- 未注册值不要直出，统一回退成更安全的中性文案

### P1. 资料卡系统仍然容易把内部状态原因直接暴露给用户

本轮已经收了 `budget_exhausted`，但当前 `riskLabel` 仍然是从 omitted reason 直接拼接出来的，说明体系上仍是“内部 reason code 可能直接上屏”。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/workspace_information_projection_service.dart)

建议：
- 建立 omission / blocker / diagnostic 的统一人话映射层
- UI 层永远不要直接显示内部码值或英文 reason

### P1. 会话开局引导仍有“机械提示语”味道，离真实产品文案还有距离

当前 opening guide 的拼接方式仍然偏“状态行叠状态行”，例如：

- `当前智能体组：...`
- `当前还缺：...`
- `当前已可直接进入普通协作会话。`

这类文案虽然信息是对的，但读感像系统状态输出，而不是为用户组织过的引导。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart)

建议：
- 改成“当前阶段结论 + 下一步动作”的组织方式
- 少用重复的 `当前...`
- 对不同项目类型分开写，不共用一套机械模板

### P1. 项目侧栏虽然已经收短，但“协作设置”区仍偏开发式，不够结果导向

当前项目面板已经比之前好很多，但 `协作设置` 里核心仍然是“当前智能体组”，这对用户来说仍偏配置视角，而不是结果视角。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_project_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_project_panel.dart)
  - [apps/novel_agent_app/lib/features/workbench/application/services/project_agent_group_panel_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/project_agent_group_panel_view_data_service.dart)

建议：
- 对普通用户优先展示“当前谁在负责什么”或“当前协作方案”
- 把“智能体组”作为次级说明，而不是主感知单位

### P2. 结构化文档渲染仍然带着明显的内部视角

`DocumentStructuredResourceRenderer` 现在已经比早期好，但仍然会展示：

- `投影 ID`
- `真相源标签`
- `只读投影状态`
- `SQLite 语义投影`

这些词对于调试和内部治理有意义，但对于普通用户并不自然，仍带有明显的“系统设计自述”感。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_structured_resource_renderer.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/renderers/document_structured_resource_renderer.dart)

建议：
- 保留“来源 / 是否可编辑 / 资源类型”这种用户能理解的字段
- 把 `projection id` 一类字段降到开发模式或隐藏区

### P2. 资源树语义标签里仍保留了内部分类词 `投影`

资源树现在已经朴素很多，但 `sqlite_projection -> 投影` 这种 badge 仍然是面向系统结构命名，不是面向用户任务命名。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/presentation/services/resource_tree_entry_semantic_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/services/resource_tree_entry_semantic_service.dart)

建议：
- 如果用户的任务是“查看资料摘要”或“查看结构化资产”，标签应当直接服务这个目标
- `投影` 这种词可以退到内部，不必做一线 badge

### P2. 侧栏 contract 文案仍有一部分“给开发者看的注释式表述”

目前 side panel contract 里的文案，例如：

- `只承接当前项目摘要、项目级协作基线和少量项目动作`
- `不夹带项目配置或系统跳板入口`

虽然不一定直接大面积上屏，但这类表达方式本身就带有强设计说明书气质。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/application/services/workbench_side_panel_contract_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/workbench_side_panel_contract_service.dart)

建议：
- 若这些文案会被 tooltip / 辅助说明读取到，应改成真实用户语言
- 若不会直接暴露，则仍建议和用户侧术语对齐，避免以后被错误复用

### P2. “写作资料”虽然比“项目资产”好，但仍然是中间层名词

对普通创作用户来说：

- `RAG 资料库`
- `规则与资料卡`

已经比旧的 `项目资产` 清晰，但仍略带实现层语感，尤其是 `资料卡` 这个词，需要在用户教育和真实用途上进一步收口。

- 文件：
  - [apps/novel_agent_app/lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart)

建议：
- 后续考虑针对不同项目类型再细分入口文案
- 至少在二级页标题里解释“这里能做什么”，而不是只解释“这是什么”

## 总体判断

当前 GUI 已经不再是最早那种“满屏解释、残留调试词、入口混乱”的状态，方向是对的；但离“正式产品感”还差一层统一的人话收口，尤其体现在：

1. 内部分类词还在渗漏
2. 状态文案仍偏机械拼接
3. 一些命名仍站在系统实现侧，而不是用户任务侧

## 下一步最值的三刀

1. 建立统一的“内部状态码 -> 用户文案”映射层
   - 覆盖 omission reason、blocker、projection、strategy、runtime mode

2. 重写 opening / guide / side-panel 的用户语言
   - 少状态播报，多“当前结论 + 下一步”

3. 对结构化资料和资源树再做一轮术语降噪
   - 把 `投影 / 真相源 / projection id` 这类词尽量退到内部

## 本轮补记的问题

下面这些是本轮清理 GUI 时实际碰到的阻塞或非 GUI 问题，先记录，不在这次硬修：

1. `apps/novel_agent_app` 的 `flutter test` 套件加载失败已确认是本机代理环境问题，不是 GUI 源码回归。
   - 根因：`HTTP_PROXY` / `HTTPS_PROXY` 指向 `127.0.0.1:7890`，但当前 shell 没有 `NO_PROXY=127.0.0.1,localhost`，导致 Flutter test 自己的本地回环请求被代理截走。
   - 当前处理：已为环境补上 `NO_PROXY` / `no_proxy`，后续跑 Flutter 测试时需确保当前 shell 继承到这个值。

2. `packages/novel_agent_core/test/project_type_transition_use_case_test.dart` 的 `briefContent == null` 已确认是旧测试路径仍在读 `project_brief.md`。
   - 当前处理：测试已改为走正式的 `project_overview.md` 合同路径，core 测试现已通过。

3. 导入资料智能分析链路里，用户文案曾经直接提到 `RAG 源材料`。
   - 这类词已经继续往“语料”收口，后续如果再发现类似实现词泄漏，优先继续做文案降噪而不是先追逻辑。

4. 结构化资源渲染里，`SQLite`、`来源`、`只读` 这些标签已经尽量保留在用户能理解的层面，但仍有少量数据库术语需要后续统一口径。
   - 本轮又进一步把 `SQLite 结构化资源 / SQLite 数据库文件` 一类说明收口成更自然的 `结构化资料 / 项目资料库文件`。
