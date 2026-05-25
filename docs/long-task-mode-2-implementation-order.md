# 第二种长任务模式实施顺序

最后更新：2026-05-25

## 模式定义

第二种模式：

`全书共拟式长篇`

目标是：

- 人类与智能体先共同确认全书主线
- 先把卷结构、角色弧光、结局方向谈清楚
- 再进入可恢复长任务执行

## 与第一种模式的复用关系

第二种模式不应另起新系统。

直接复用：

- `StrategyCatalogService`
- `ModeGuidanceState`
- `ModeGuidanceTransitionService`
- `ModeGuidanceStatePort`
- `ProjectModeGuidanceRepository`
- `guidance.md + hidden json + sqlite` 三层落盘
- 现有 UI 引导壳

只新增：

- mode 2 的阶段定义
- mode 2 的投影文档
- mode 2 到长任务计划输入的映射

## 实施顺序

### Phase 1

- 已完成：把 mode 2 作为第二个可走 `mode_guidance` 的模式策略入口

### Phase 2

- [x] 补 mode 2 的阶段文档投影
- [x] 重点投到：
  - `outline/`
  - `volume_outlines/`
  - `characters/`
  - `styles/`
  - `specs/`

### Phase 3

- [x] 把 mode 2 的完成状态接到 `long_task.create_queue`
- [x] 让它优先生成：
  - 总纲
  - 分卷结构
  - 关键角色弧光
  - 结局承诺

### Phase 4

- [x] 做 mode 2 的真实 API 探针
- [x] 至少验证：
  1. 信息不足先补问
  2. 信息足够先写总纲 / 卷纲，再建队列

### Phase 5

- [x] 让 mode 2 复用 mode 1 的共享资产投影骨架
- [x] 验证 `set_agent_tasks` 与长任务任务文件可以闭环，不再停在“只会列计划”

## 当前结论

mode 2 已经被实现成 mode 1 的平行策略，而不是新的工作流分支系统。
