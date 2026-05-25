# 第一种长任务模式架构设计

## 目标

本文只定义第一种长任务模式，也就是：

`灵感托管式长篇`

它的基本含义是：

- 人类先提供创作灵感、题材、世界观、禁区、偏好、目标感
- 智能体负责把这些种子收束成长期可执行的长篇计划
- 后续大部分推进由智能体主导
- 人类只在关键检查点确认，而不是逐章盯写

但这份设计不会把逻辑写死在这个模式里。

相反，这一轮的重点是：

1. 明确这个模式自己的专属策略
2. 把真正可以复用的层先摘出来
3. 给以后其他模式留下平行接入位

## 依赖文档

本文不是独立设计，它显式建立在下面几份已提取文档之上：

- `docs/architecture.md`
- `docs/core-strategy.md`
- `docs/migrated-capability-classification.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/legacy-migration-boundary.md`

它们各自提供的约束如下：

### 1. `architecture.md`

提供总边界：

- GUI / CLI / core / adapters 分层
- 共享逻辑必须优先进入 core
- 不把模式逻辑压进 Flutter 控制器

### 2. `core-strategy.md`

提供技术策略：

- 继续坚持纯 Dart core
- 这类模式逻辑不下沉到 C++ 或宿主层

### 3. `migrated-capability-classification.md`

提供能力归属：

- 哪些是长任务专属
- 哪些是长任务与一般协作模式共用
- 哪些属于策略控制项

本文新增的第一种模式设计，必须遵守那份分类，而不是另起一套归属标准。

### 4. `mumuainovel-absorption-analysis.md`

提供参考来源：

- 风格资产化
- 伏笔对象化
- 角色 / 组织卡片化
- 分阶段闭环
- 结构化结果优先

本文中的资产层设计，直接继承那份文档已经确认过的可吸收结论。

### 5. `legacy-migration-boundary.md`

提供迁移边界：

- 哪些规则进 core
- 哪些 IO 进 adapters
- 哪些视图和交互留在 app / ui

因此本文不会把“模式引导策略”“角色别名解析”“风格注入规则”写成 UI 逻辑。

## 与 MuMu 吸收项的覆盖核对

这里专门核对 `docs/mumuainovel-absorption-analysis.md` 中的全部可吸收理念，确认哪些已经被本文显式吸收，哪些还只是共享依赖，哪些后续要补进实施清单。

### 已显式纳入本文主体的

1. 灵感模式
2. 自定义写作风格
3. 思维链与章节关系图谱
4. 根据分析一键重写
5. 角色/组织卡片导入导出背后的“卡片资产化”
6. 伏笔管理

这些在本文中已经明确落到了：

- 模式引导
- 共享资产层
- 风格层
- 实体身份层
- 长任务运行层

### 已作为共享依赖纳入，但本文尚未展开细节的

1. 数据导入导出
2. Prompt 调整界面
3. 章节字数限制
4. 职业等级体系
5. 提示词工坊
6. 拆书功能

这些并不是“不吸收”，而是：

- 它们不应在第一种模式文档里冒充模式专属逻辑
- 它们应作为平行可复用能力挂到共享策略与资产层

换句话说，第一种模式必须兼容它们，但不该吞掉它们。

### 需要在本文中补明的统一落点

为了避免遗漏，这里正式补充它们的架构归属：

#### 数据导入导出

- 归属：共享资产层 + adapters
- 作用：把世界规则、角色蓝图、风格、伏笔、模板、模式状态做成可迁移包

#### Prompt 调整界面

- 归属：共享模板 / 策略支持层
- 作用：为不同 `workflow_strategy` 提供可视化模板调优入口，而不是把 prompt 硬写死

#### 章节字数限制

- 归属：共享生成策略层
- 作用：成为章纲、正文、重写等生成动作的参数约束，而不是某种模式专属字段

#### 职业等级体系

- 归属：共享设定资产层
- 作用：作为世界规则与角色成长约束的可选 schema，被第一种模式按需引用

#### 提示词工坊

- 归属：共享模板包层
- 作用：为模式策略、智能体、技能、风格模板提供本地包化复用能力

#### 拆书功能

- 归属：平行项目策略 + 共享资产输入层
- 作用：它不是第一种模式的一部分，但其输出资产应能喂给第一种模式使用

### 当前结论

所以，严格地说：

- 本文已经覆盖了 `mumuainovel-absorption-analysis.md` 的核心可吸收理念骨架
- 但其中 6 项属于“共享平行能力”，不应硬塞成第一种模式专属逻辑
- 本文现在已经把这些遗漏显式补成“共享依赖与统一落点”

这才符合我们的长期策略：模式平行，资产共享，工作流可替换

## 先给结论

第一种模式不应该被实现成“一个大 prompt + 一套页面分支”。

它应该被拆成四层：

1. `模式目录层`
2. `模式引导层`
3. `共享资产层`
4. `长任务生成与运行层`

其中只有“引导问题顺序、默认检查点密度、默认协作强度”属于模式专属；
其余大部分能力都应该抽成可复用层。

## MuMuAINovel 对这轮最有价值的吸收点

参考 `references/MuMuAINovel-main`，这轮最值得吸收的不是页面，而是三类产品策略：

### 1. 把写作对象做成结构化资产

尤其是：

- 风格
- 伏笔
- 角色 / 组织
- 章节分析结果
- 导入导出包

这和我们第一种模式高度契合，因为“灵感托管式长篇”最怕前期灵感散、后期失忆。

### 2. 把复杂流程拆成阶段闭环

`MuMuAINovel` 在灵感、风格、伏笔、重写、导入导出上的可取之处，是它把流程拆成了：

- 采集
- 分析
- 建议
- 应用
- 回看

这正是我们第一种模式应该采用的形状。

### 3. 用结构化视图代替裸上下文

风格不是一段散文。
伏笔不是正文里的备注。
角色不是只有名字。

都应该有自己的对象结构、状态变化和引用关系。

## MuMuAINovel 是否有多智能体

从当前参考仓库里，我没有看到像我们现在这样明确的：

- 子智能体调度
- 委派计划
- 协作组
- 专职 agent orchestration

所以这次可以明确判断：

- `MuMuAINovel` 更像单智能体产品参考
- 它能提供的是“资产化和流程拆分”的经验
- 它不能直接提供我们的多智能体架构答案

因此我们不应该照搬它的单智能体实现，
但也不应该为了多智能体而把第一种模式做重。

## 第一种模式的推荐协作策略

### 默认策略

第一版建议采用：

`单主智能体 + 可选专职子智能体`

而不是“一上来就全流程多智能体”。

原因：

1. 这种模式的核心是“前期收束 + 后期托管”，主线必须稳定
2. 如果一开始就多智能体并发讨论，风格和世界观更容易漂
3. 我们现在最需要的是一个稳的共用骨架，而不是更花的 orchestration

### 具体建议

第一种模式里：

- `主智能体` 负责用户对话、信息收束、计划确认、统一风格、最终决策
- `子智能体` 只在这些专职场景出场：
  - 世界观补全
  - 角色设计
  - 风格校准
  - 伏笔 / 连续性检查
  - 旧资料清洗

并且：

- 默认不让多个子智能体并发直接对用户说话
- 所有子智能体结果都先回主智能体整合
- 主智能体始终是唯一对外叙事口径

这能同时保留：

- 统一风格
- 长期可控
- 多智能体扩展口

## 第一种模式的用户引导目标

这个模式不是让用户一下填完大表单。

它的目标是分阶段帮用户把“模糊灵感”变成五类长期稳定资产：

1. `作品承诺`
2. `世界规则`
3. `核心角色群`
4. `目标风格`
5. `长任务执行边界`

只有这五类收束后，才进入正式长任务队列生成。

## 推荐引导阶段

### 阶段 A：创作种子收束

目标：

- 确认题材、基调、主冲突、主角体验

用户交互：

- 可点选项
- 也允许自由输入

主智能体应优先给 2 到 4 个选项，不要甩问卷。

建议问题顺序：

1. 这部小说最想给人的感觉是什么
2. 主角处在怎样的世界与处境
3. 你更在意“剧情推进”还是“氛围体验”
4. 你有没有明确不想写的方向

产出资产：

- `project_seed_record`
- `creative_boundaries`

### 阶段 B：世界观托底

目标：

- 把世界观从“印象”变成“可持续约束”

建议不是一次性铺满所有设定，
而是最少先落：

1. 世界类型
2. 力量 / 技术规则
3. 社会结构
4. 主要风险和代价
5. 不可违反规则

产出资产：

- `world_rule_set`
- `setting_glossary`
- `forbidden_assumptions`

### 阶段 C：角色骨架

目标：

- 不先追求完整角色卡
- 先建立“功能角色网络”

用户先确认：

1. 主角
2. 核心对立面
3. 第一批关键关系
4. 最少必需组织 / 势力

产出资产：

- `character_blueprints`
- `organization_blueprints`
- `relationship_skeleton`

### 阶段 D：风格定锚

目标：

- 确定长期写作风格的统一锚点

这一步不能只问“你想要什么风格”，
而要拆成更容易确认的几个维度：

1. 叙述密度
2. 语言质地
3. 节奏快慢
4. 情绪浓度
5. 允许的修辞倾向
6. 禁止的语言坏习惯

建议交互：

- 先给选项
- 再允许用户补充自由描述
- 最后由主智能体归纳成结构化风格规范

产出资产：

- `style_profile`
- `style_guardrails`
- `style_examples`

### 阶段 E：托管边界确认

目标：

- 确认智能体到底可以自主到什么程度

这一步非常关键，因为它直接决定第一种模式和其他模式的边界。

至少要确认：

1. 是否允许智能体自主扩展支线
2. 是否允许智能体自主新增角色
3. 是否允许智能体跨卷调整结构
4. 多久回到用户确认一次
5. 哪类改动必须先征求确认

产出资产：

- `autonomy_policy`
- `checkpoint_policy`
- `change_authority_policy`

### 阶段 F：生成长任务骨架

目标：

- 不直接写正文
- 先产出可恢复任务链

第一种模式下，初始任务链建议先包含：

1. 世界观收束
2. 主角与关键角色收束
3. 风格规范定稿
4. 全书主线规划
5. 分卷结构规划
6. 第一卷细化
7. 第一批章纲
8. 正文起写前检查

产出资产：

- `long_task_mode_record`
- `long_task_plan`
- `checkpoint_schedule`

## 选项引导与自由输入的架构做法

我们已经有：

- `present_user_options`
- 用户直接输入

所以第一种模式不需要另一套输入系统。

应新增的是：

`模式引导状态机`

它的职责不是 UI，而是决定：

- 当前该问哪一类问题
- 当前是否该优先出选项
- 当前缺什么信息
- 什么情况下允许提前跳阶段

推荐放置：

- `packages/novel_agent_core/lib/src/modes/`

建议新增：

- `mode_definition.dart`
- `mode_stage_definition.dart`
- `mode_guidance_state.dart`
- `mode_guidance_transition_service.dart`
- `mode_guidance_question_service.dart`
- `mode_guidance_gap_detector_service.dart`

## 第一种模式的上下文记忆策略

这个模式最怕两件事：

1. 前期信息散掉
2. 后期风格和设定漂掉

因此不能只依赖普通会话上下文。

必须拆成：

### 1. 会话短期上下文

用途：

- 本轮对话和最近几轮补充

沿用现有：

- `session_record`
- `session_context_renderer`
- `compression_strategy`

### 2. 模式阶段记忆

用途：

- 当前引导已经收集了什么
- 还缺什么
- 哪些项已确认

建议新增：

- `mode_memory_snapshot`
- `stage_completion_record`

### 3. 项目长期结构记忆

用途：

- 世界规则
- 角色蓝图
- 风格规范
- 伏笔对象
- 长任务边界

建议新增项目级资产：

- `project_memory/world/`
- `project_memory/characters/`
- `project_memory/style/`
- `project_memory/foreshadows/`
- `project_memory/modes/`

### 4. 运行期可注入上下文

用途：

- 在生成章纲、正文、修订时，只注入当前需要的结构记忆片段

这部分应该复用现有：

- `context_assembler`
- `context_budgeter`

但要新增：

- `mode_context_selector_service`
- `style_context_section_service`
- `character_context_section_service`

## 角色卡设计约束

你提的这个点非常重要。

### 结论

角色卡绝对不能和“名字”绑死。

应该采用：

- `稳定角色ID`
- `可变显示名`
- `别名映射`

### 推荐模型

不要把角色主键设计成名字。

而应拆成：

- `character_id`
- `display_name`
- `aliases`
- `name_history`
- `role_function`

其中：

- `character_id` 永久稳定
- `display_name` 是当前展示名
- `aliases` 包含旧名、代称、外号、称谓
- `name_history` 记录改名过程
- `role_function` 表示这个角色在叙事里的职责

这样才能保证：

1. 改名不会打断引用
2. 伏笔、关系、章节分析都还能继续关联到同一个角色
3. 后续可以做批量改名传播

### 架构落点

应进入 `core`：

- `character_identity.dart`
- `character_alias_resolver_service.dart`
- `entity_reference_service.dart`

应进入 `adapters`：

- 项目持久化
- 改名同步写回

应进入 `ui`：

- “显示名 / 别名 / 当前称谓”编辑

## 风格统一架构

风格统一不能只靠一个系统提示词。

推荐拆成三层：

### 1. 风格资产层

描述“这个项目想写成什么样”。

建议对象：

- `style_profile`
- `style_guardrails`
- `style_example_excerpt`

### 2. 风格注入层

在不同用例里把风格投给模型。

比如：

- 开局规划
- 章纲
- 正文
- 修订
- 子智能体任务

建议服务：

- `style_prompt_section_service`
- `style_override_merge_service`
- `style_consistency_brief_service`

### 3. 风格校验层

当正文产出后，检查：

- 是否偏离约定风格
- 是否语言质地漂移
- 是否节奏失控

建议服务：

- `style_drift_detection_service`
- `style_review_task_factory_service`

## 第一种模式与一般小说项目的关系

必须明确：

- 一般小说项目
- 第一种长任务模式
- 其他长任务模式
- 拆书
- 短文集

这些都应该是：

`平行策略`

不是“长任务是一般小说项目里的一个特殊页面”。

因此需要新增更清晰的策略层：

- `project_strategy`
- `mode_strategy`
- `workflow_strategy`

推荐关系：

### `project_strategy`

决定一个项目属于什么大类：

- 一般小说
- 长篇托管
- 短文集
- 拆书
- 知识整理

### `mode_strategy`

决定同一大类内部采用哪种进入模式。

例如长篇托管里：

- 灵感托管式
- 全书共拟式
- 分卷检查点式

### `workflow_strategy`

决定当前动作采用什么执行规则。

例如：

- 先问选项
- 先读资产
- 先调子智能体
- 先做结构化分析

## 推荐新增模块位置

### Core

建议新增子域：

```text
packages/novel_agent_core/lib/src/
  modes/
  assets/
  style/
  entity/
```

#### `modes/`

放模式定义和引导状态机：

- `mode_definition.dart`
- `mode_catalog_service.dart`
- `mode_guidance_state.dart`
- `mode_guidance_transition_service.dart`
- `mode_guidance_question_service.dart`
- `mode_guidance_gap_detector_service.dart`
- `mode_context_selector_service.dart`

#### `assets/`

放项目级结构资产合同：

- `world_rule_set.dart`
- `style_profile.dart`
- `character_blueprint.dart`
- `organization_blueprint.dart`
- `foreshadow_record.dart`
- `autonomy_policy.dart`
- `checkpoint_policy.dart`

#### `entity/`

放角色与组织的身份映射：

- `entity_identity.dart`
- `entity_alias.dart`
- `entity_reference.dart`
- `entity_reference_resolver_service.dart`

#### `style/`

放风格相关逻辑：

- `style_profile_normalizer_service.dart`
- `style_prompt_section_service.dart`
- `style_consistency_brief_service.dart`
- `style_drift_detection_service.dart`

### Adapters

建议新增：

```text
packages/novel_agent_adapters/lib/src/
  assets/
  modes/
```

职责：

- 项目内资产读写
- 模式状态落盘
- 风格资产导入导出
- 角色别名映射持久化

### App

建议新增：

```text
apps/novel_agent_app/lib/features/
  mode_guidance/
  style_center/
  entity_center/
```

职责：

- 把 core 里的模式状态投影成界面
- 模式引导页的视图状态
- 风格中心、角色中心、组织中心的 view data

### UI

第一种模式最少需要这些界面入口：

- 模式说明页
- 阶段引导页
- 风格确认页
- 角色蓝图确认页
- 托管边界确认页
- 长任务队列生成确认页

## 适合引入的设计模式

这轮可以适当引入，但不要过度设计。

### 1. Strategy

用于：

- 不同项目策略
- 不同模式策略
- 不同工作流策略

这是必要的。

### 2. State Machine

用于：

- 模式引导阶段推进
- 阶段完成判定
- 回退 / 跳过 / 补问

这也是必要的。

### 3. Specification / Rule Object

用于：

- 判断当前资料是否足够进入下一阶段
- 判断是否允许自动推进
- 判断哪些信息是必填、建议填、可选填

这很适合“灵感托管式长篇”。

### 4. Facade

用于：

- 给 GUI / CLI 提供统一的模式启动入口

但 facade 必须薄，只做编排，不吸业务。

## 第一种模式的最小实施顺序

### 第一批

- 模式目录与模式定义
- 模式引导状态机
- 世界 / 角色 / 风格 / 托管边界四类资产合同
- 长任务开局模式到引导状态的衔接

### 第二批

- 风格资产编辑与注入
- 角色稳定 ID + 别名映射
- 阶段记忆落盘
- 长任务计划生成接线

### 第三批

- 风格漂移检查
- 伏笔与章节关系回填
- 子智能体专职协作
- 导入导出和跨项目复用

## 最后的边界提醒

第一种模式不是“大而全小说系统”的中心。

它只是：

- 一种长任务策略
- 一组可复用资产层的第一个真正落点

所以必须坚持：

1. 模式专属逻辑进入 `modes/`
2. 角色、风格、世界、伏笔进入共享资产层
3. 长任务调度继续留在现有 `workflow/`
4. 多智能体只作为可选增强，不反客为主

如果后面第二种、第三种长任务模式出现，
它们应该复用：

- 资产层
- 引导状态机骨架
- 上下文选择器
- 风格注入层
- 角色映射层

而只替换：

- 阶段顺序
- 检查点密度
- 自主权策略
- 默认协作强度
