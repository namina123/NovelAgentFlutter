import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/layout/app_layout_metrics.dart';
import 'package:novel_agent_app/app/layout/app_layout_scope.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/contracts/settings_action_handler.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/theme_settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/pages/settings_page.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/theme_settings_panel.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/theme_option_tile.dart';

void main() {
  testWidgets('theme settings panel saves selected theme id', (tester) async {
    Map<String, Object?>? savedPayload;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ThemeSettingsPanel(
            viewData: const ThemeSettingsViewData(
              selectedThemeId: 'builtin.light',
              currentThemeLabel: '明亮',
              builtInThemes: <ThemeOptionViewData>[
                ThemeOptionViewData(
                  id: 'builtin.light',
                  label: '明亮',
                  description: 'light',
                  badgeLabel: '明亮',
                  previewSwatches: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFF7F2E7),
                    Color(0xFF2D7A8C),
                  ],
                  isSelected: true,
                ),
                ThemeOptionViewData(
                  id: 'builtin.dark',
                  label: '偏暗',
                  description: 'dark',
                  badgeLabel: '偏暗',
                  previewSwatches: <Color>[
                    Color(0xFF141A1F),
                    Color(0xFF1E252B),
                    Color(0xFF78B6C7),
                  ],
                  isSelected: false,
                ),
              ],
              builtInSectionDescription: 'builtin',
              futureSectionDescription: 'future',
              customSectionDescription: 'custom',
            ),
            onSaved: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ThemeOptionTile).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('保存主题设置'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('保存主题设置'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['selected_theme_id'], 'builtin.dark');
  });

  testWidgets('settings page theme tab stays stable on desktop light layout', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => AppLayoutScope(
            metrics: AppLayoutMetrics.fromMediaQuery(MediaQuery.of(context)),
            child: SettingsPage(
              viewData: _themeSettingsPageViewData(),
              actionHandler: _FakeSettingsActionHandler(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('保存主题设置'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('返回工作台'), findsOneWidget);
    expect(find.text('保存主题设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings page theme tab stays stable on narrow dark layout', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => AppLayoutScope(
            metrics: AppLayoutMetrics.fromMediaQuery(MediaQuery.of(context)),
            child: SettingsPage(
              viewData: _themeSettingsPageViewData(),
              actionHandler: _FakeSettingsActionHandler(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('返回工作台'), findsOneWidget);
    expect(find.byType(ThemeOptionTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

SettingsViewData _themeSettingsPageViewData() {
  return SettingsViewData.initial().copyWith(
    activeTabId: 'theme',
    themeViewData: const ThemeSettingsViewData(
      selectedThemeId: 'builtin.light',
      currentThemeLabel: '明亮',
      builtInThemes: <ThemeOptionViewData>[
        ThemeOptionViewData(
          id: 'builtin.light',
          label: '明亮主题，适合中文长时间编辑与资料回看',
          description: '更适合白天编辑、资料整理、长时间扫描和长中文段落快速浏览。',
          badgeLabel: '当前默认',
          previewSwatches: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF7F2E7),
            Color(0xFF2D7A8C),
          ],
          isSelected: true,
        ),
        ThemeOptionViewData(
          id: 'builtin.dark',
          label: '偏暗主题，适合夜间连续创作与长任务值守',
          description: '更适合夜间连续创作、低照环境、长任务值守和减少浅底眩光干扰。',
          badgeLabel: '夜间推荐',
          previewSwatches: <Color>[
            Color(0xFF10161B),
            Color(0xFF182127),
            Color(0xFF84C9DD),
          ],
          isSelected: false,
        ),
      ],
      builtInSectionDescription: '当前内置主题会直接从 ThemeRegistry 读取，切换后立即作用到工作台核心表面。',
      futureSectionDescription: '后续新增的官方内置主题会继续沿同一注册表接入，不需要重写设置页结构。',
      customSectionDescription: '自定义主题入口暂时保留为壳，后续开放时会复用当前的主题描述与 token 合同。',
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _FakeSettingsActionHandler implements SettingsActionHandler {
  @override
  void onContextSettingsSaved(Map<String, Object?> payload) {}

  @override
  void onModelSettingsSaved(Map<String, Object?> payload) {}

  @override
  void onNetworkSettingsSaved(Map<String, Object?> payload) {}

  @override
  void onPermissionSettingsSaved(Map<String, Object?> payload) {}

  @override
  void onProviderCreateRequested() {}

  @override
  void onProviderDeleted(String providerId) {}

  @override
  void onProviderDetailBackRequested() {}

  @override
  void onProviderSaved(Map<String, Object?> payload) {}

  @override
  void onProviderSelected(String providerId) {}

  @override
  void onProjectCreationExpressionConstraintDefaultsSaved(
    Map<String, Object?> payload,
  ) {}

  @override
  void onSettingsBackRequested() {}

  @override
  void onSettingsTabSelected(String tabId) {}

  @override
  void onThemeSettingsSaved(Map<String, Object?> payload) {}

  @override
  void onToolStrategySettingsSaved(Map<String, Object?> payload) {}
}
