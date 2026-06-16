# UFDL Closeout

日期：2026-06-16

## 结论

`UFDL-01` 到 `UFDL-08` 已按顺序完成。

这条主线收掉了本轮审计确认的用户面开发遗留痕迹，主要包括：

1. 正式入口不再向用户回吐“未接入执行链”式提示。
2. 设置页默认路径不再暴露 `dev` 标签、宿主根路径和内部实现名。
3. 设置页和 opening 路径里的兼容/内部术语已收成更正式的用户口径。
4. 主题页、拆书预览页、技能装载页的占位壳和伪状态文案已清掉。
5. 用户面新增了一条黑名单回归，防止这轮清理过的词汇再次漏回去。
6. Android release 已保持正式包名和正式 signing 入口，且不会再静默回退到 debug 签名。

## 已收口的用户面

### 设置页

已确认普通用户路径不再展示：

1. `开发`
2. `设置根目录`
3. `搜索根目录`
4. `默认项目根`
5. `ProjectWorkspacePort`
6. `ToolExecutionService`
7. `ProjectToolDispatcher`

相关代码与回归：

- [app_shell_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_controller.dart)
- [settings_page_projection_regression_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/settings_page_projection_regression_test.dart)
- [user_facing_development_leftovers_regression_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart)

### 兼容/内部术语

已把这些用户可见词面收紧为更正式的表达：

1. `高级兼容桥` -> `历史上下文参数`
2. `压缩阈值百分比（兼容桥）` -> `压缩阈值百分比`
3. `兼容上下文长度` -> `上下文窗口长度`
4. `暂未返回额外适配信息` -> `暂无更多说明`

相关代码与回归：

- [context_settings_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart)
- [model_settings_advanced_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_advanced_panel.dart)
- [opening_session_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_session_panel.dart)
- [context_settings_panel_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/context_settings_panel_test.dart)
- [model_settings_panel_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/model_settings_panel_test.dart)
- [opening_session_panel_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/opening_session_panel_test.dart)

### 半成品壳与伪状态

已收掉：

1. `后续内置主题`
2. `自定义主题`
3. `注册表扩展位`
4. `用户自定义预留`
5. `当前保留为空分组，后续新增路线会继续挂到这里。`
6. `表达规则：已应用 / 建议加强 / 已阻塞修订 / 已关闭。`

相关代码与回归：

- [theme_settings_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/settings/presentation/widgets/theme_settings_panel.dart)
- [theme_settings_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/settings/application/services/theme_settings_view_data_service.dart)
- [book_deconstruction_preview_panel.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart)
- [project_skill_loadout_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart)
- [theme_settings_panel_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/theme_settings_panel_test.dart)
- [theme_settings_view_data_service_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/theme_settings_view_data_service_test.dart)
- [book_deconstruction_preview_panel_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/book_deconstruction_preview_panel_test.dart)
- [project_skill_loadout_view_data_service_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/project_skill_loadout_view_data_service_test.dart)

## Android Release

已完成的 release 基础收口：

1. `applicationId` 已从示例值改成正式值。
2. release signing 已切到正式配置入口。
3. 缺少 keystore 密钥时会明确失败，不会回退到 debug 签名。

验证结果：

- `flutter build apk --release --no-pub`
- 结果：失败，但失败原因是预期中的 signing 配置缺失，而不是 debug fallback。

相关文件：

- [build.gradle.kts](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/android/app/build.gradle.kts)
- [android-release-signing-2026-06-16.md](/d:/FlutterProjects/NovelAgentFlutter/docs/android-release-signing-2026-06-16.md)

## 回归防线

已新增一层用户面黑名单回归：

- [user_facing_development_leftovers_regression_test.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart)

黑名单覆盖了本轮最关键的用户可见残留词：

1. `开发`
2. `兼容桥`
3. `ProjectWorkspacePort`
4. `ToolExecutionService`
5. `ProjectToolDispatcher`
6. `后续内置主题`
7. `注册表扩展位`
8. `用户自定义预留`
9. `当前保留为空分组`
10. `暂未返回额外适配信息`
11. `表达规则：已应用`

## 还保留的残留

下面这些是刻意保留在范围外，或者暂时只保留内部投影，不继续作为本主线的收口对象：

1. 兼容字段的底层存储结构仍在 `context_settings_contract_service` 的归一化链路里。
2. `settingsRootPath` / `settingsSearchRoots` / `defaultProjectsRootPath` 仍存在于部分 view data 传递链上，但已不再进入普通用户路径。
3. `flutter test test/widget_test.dart` 仍有一个既有 smoke 期望失败，`正文工作区` 当前未出现，这个问题不属于本主线范围。

## 关键验证

本主线过程中已通过的关键验证包括：

1. `flutter test test/settings_page_projection_regression_test.dart test/theme_settings_panel_test.dart`
2. `flutter test test/context_settings_panel_test.dart test/model_settings_panel_test.dart test/opening_session_panel_test.dart`
3. `flutter test test/theme_settings_panel_test.dart test/theme_settings_view_data_service_test.dart test/book_deconstruction_preview_panel_test.dart test/project_skill_loadout_view_data_service_test.dart`
4. `flutter test test/user_facing_development_leftovers_regression_test.dart`
5. `flutter build apk --release --no-pub`

## 交接点

如果后续还要继续瘦身这条线，最自然的下一步是：

1. 进一步把 `settingsRootPath` / `settingsSearchRoots` / `defaultProjectsRootPath` 从 view data 传递链中下沉出去。
2. 再单独处理 `widget_test.dart` 的 smoke 期望，让它和当前真实启动行为对齐。

