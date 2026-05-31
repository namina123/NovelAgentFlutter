import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/provider_settings_panel.dart';

void main() {
  testWidgets('provider settings panel uses list-first flow on narrow layouts', (
    tester,
  ) async {
    String? selectedProviderId;
    var createRequested = false;
    var backRequested = false;

    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              final providers = <ProviderEndpointViewData>[
                ProviderEndpointViewData(
                  id: 'opencode',
                  title: 'opencode',
                  protocol: 'openai_compatible',
                  baseUrl: 'https://opencode.ai/zen/go/v1',
                  rawApiKey: '',
                  apiKeyState: '已配置密钥',
                  description: '',
                  isSelected: selectedProviderId == 'opencode',
                ),
                if (selectedProviderId == '__new__')
                  const ProviderEndpointViewData(
                    id: '__new__',
                    title: '',
                    protocol: 'openai_compatible',
                    baseUrl: '',
                    rawApiKey: '',
                    apiKeyState: '未配置密钥',
                    description: '',
                    isSelected: true,
                  ),
              ];
              return ProviderSettingsPanel(
                providers: providers,
                providerDirectoryOptions: const [
                  ProviderDirectoryOptionViewData(
                    id: 'openai',
                    label: 'OpenAI',
                    protocol: 'openai_compatible',
                    defaultBaseUrl: 'https://api.openai.com/v1',
                  ),
                ],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'gpt-5.5',
                    label: 'gpt-5.5',
                    note: 'OpenAI',
                  ),
                ],
                onProviderSelected: (value) {
                  setState(() {
                    selectedProviderId = value;
                  });
                },
                onProviderCreateRequested: () {
                  setState(() {
                    createRequested = true;
                    selectedProviderId = '__new__';
                  });
                },
                onProviderDetailBackRequested: () {
                  setState(() {
                    backRequested = true;
                    selectedProviderId = null;
                  });
                },
                onProviderSaved: (_) {},
                onProviderDeleted: (_) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('添加接口'), findsOneWidget);
    expect(find.text('返回接口列表'), findsNothing);
    expect(find.text('接口/厂商名称'), findsNothing);

    await tester.tap(find.text('opencode'));
    await tester.pumpAndSettle();

    expect(find.text('返回接口列表'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('接口/厂商名称'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('接口/厂商名称'), findsOneWidget);
    expect(find.text('模型 ID'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('返回接口列表'));
    await tester.pumpAndSettle();

    expect(backRequested, isTrue);
    expect(find.text('添加接口'), findsOneWidget);

    await tester.tap(find.text('添加接口'));
    await tester.pumpAndSettle();

    expect(createRequested, isTrue);
    expect(find.text('返回接口列表'), findsOneWidget);
  });

  testWidgets('provider detail draft survives width changes for the same provider', (
    tester,
  ) async {
    String? selectedProviderId = 'opencode';

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ProviderSettingsPanel(
                providers: [
                  ProviderEndpointViewData(
                    id: 'opencode',
                    title: 'opencode',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://opencode.ai/zen/go/v1',
                    rawApiKey: '',
                    apiKeyState: '已配置密钥',
                    description: '',
                    isSelected: selectedProviderId == 'opencode',
                  ),
                ],
                providerDirectoryOptions: const [
                  ProviderDirectoryOptionViewData(
                    id: 'openai',
                    label: 'OpenAI',
                    protocol: 'openai_compatible',
                    defaultBaseUrl: 'https://api.openai.com/v1',
                  ),
                  ProviderDirectoryOptionViewData(
                    id: 'deepseek',
                    label: 'DeepSeek',
                    protocol: 'openai_compatible',
                    defaultBaseUrl: 'https://api.deepseek.com',
                  ),
                ],
                allModelOptions: const [],
                onProviderSelected: (value) {
                  setState(() {
                    selectedProviderId = value;
                  });
                },
                onProviderCreateRequested: () {},
                onProviderDetailBackRequested: () {
                  setState(() {
                    selectedProviderId = null;
                  });
                },
                onProviderSaved: (_) {},
                onProviderDeleted: (_) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final titleField = find.descendant(
      of: find.byKey(const ValueKey('provider-directory-field')),
      matching: find.byType(EditableText),
    );
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'DeepSeek');
    await tester.pump();

    await tester.binding.setSurfaceSize(const Size(520, 900));
    await tester.pumpAndSettle();

    final narrowTitleField = find.descendant(
      of: find.byKey(const ValueKey('provider-directory-field')),
      matching: find.byType(EditableText),
    );
    expect(narrowTitleField, findsOneWidget);
    expect(
      tester.widget<EditableText>(narrowTitleField).controller.text,
      'DeepSeek',
    );
  });
}
