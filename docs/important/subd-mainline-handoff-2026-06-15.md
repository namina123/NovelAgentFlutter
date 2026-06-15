# SUBD 主线交接摘要

日期：2026-06-15

本页用于把 `SUBD-01` 到 `SUBD-24` 的收口状态、验证证据和残留风险压成一份可直接接手的摘要。

## 当前状态

1. `SUBD-01` 到 `SUBD-24` 已全部完成。
2. 主任务文档的完成记录已补齐。
3. 这条主线当前没有未登记的高风险遗留问题。

## 已完成的关键收口

1. 开局 truth contract、工具暴露、协作合同、产物路径合同已在 core / workflow / adapters 中收口。
2. 共享来源解析、目录扫描、多格式 reader、原文归档、followup 分流、一般导入智能分析边界已收口。
3. 壳层与主工作台的入口语义、返回行为、项目创建阶段、知识库类型存储约束已验证并补上回归。
4. 高保真 probe 已验证拆书导入与一般导入链路，真实 GUI / ViewModel probe 也已通过。

## 关键证据

1. 主任务顺序与完成记录：
   - [docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md](/d:/FlutterProjects/NovelAgentFlutter/docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md)
2. 拆书与导入链高保真 probe 报告：
   - [artifacts/real_gui_book_deconstruction_import_probe_report.md](/d:/FlutterProjects/NovelAgentFlutter/artifacts/real_gui_book_deconstruction_import_probe_report.md)
   - [artifacts/real_gui_book_deconstruction_import_probe_report.json](/d:/FlutterProjects/NovelAgentFlutter/artifacts/real_gui_book_deconstruction_import_probe_report.json)
3. 章节型继续创作高保真验收 lane 报告：
   - [artifacts/high_fidelity_viewmodel_validation/2026-06-15T18-10-46-289841/lane_ordinary_chaptered_continuation/lane_report.json](/d:/FlutterProjects/NovelAgentFlutter/artifacts/high_fidelity_viewmodel_validation/2026-06-15T18-10-46-289841/lane_ordinary_chaptered_continuation/lane_report.json)

## 本轮验证概览

1. `flutter test test/project_import_execution_service_test.dart`
2. `flutter test test/real_gui_book_deconstruction_import_probe_test.dart`
3. `flutter test test/app_shell_compact_scaffold_test.dart`
4. `flutter test test/project_creation_controller_test.dart`
5. `flutter test test/project_launcher_view_data_service_test.dart`
6. `flutter test test/project_create_panel_continuity_test.dart`
7. `flutter test test/project_open_view_data_service_test.dart`

## 残留风险

1. `AppShellController` 体量仍然偏大，后续如果再加壳层能力，需要继续防止它重新长成事实源中心。
2. 真实 probe 仍依赖显式开闸与本地 `local/probe_api.txt` 配置。
3. 一般导入智能分析目前仍是轻量启发式分类，若未来要升级为更强分析智能体，需要继续在主链上扩展，而不是回流到 probe。
4. EPUB reader 当前覆盖常见 container / OPF / spine / XHTML 路线，复杂容器格式后续再扩。

## 下一阶段入口

1. 若继续推进新的主线，请先重新读这份主任务文档和相关分析文档，再定义新的 session 顺序：
   - [docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md](/d:/FlutterProjects/NovelAgentFlutter/docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md)
   - [docs/important/project-unreasonable-areas-audit-2026-06-15.md](/d:/FlutterProjects/NovelAgentFlutter/docs/important/project-unreasonable-areas-audit-2026-06-15.md)
   - [docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md](/d:/FlutterProjects/NovelAgentFlutter/docs/important/book-deconstruction-ingestion-and-followup-architecture-analysis-2026-06-14.md)
2. 若只做回归，优先从已完成的 focused tests 和 probe report 继续。

