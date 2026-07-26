import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/models/custom_model_reasoning_override_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/model_editor_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/model_parameter_entry_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/project_creation_expression_constraint_defaults_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_search_option.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/models/theme_settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/model_settings_panel.dart';

void main() {
  testWidgets(
    'model settings panel keeps writing controls visible and advanced options collapsed by default',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'deepseek',
                    title: 'DeepSeek',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.deepseek.com',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'other-provider-model',
                    label: 'other-provider-model',
                    note: 'Other Provider',
                  ),
                  SettingsSearchOptionViewData(
                    value: 'deepseek-v4-pro',
                    label: 'deepseek-v4-pro',
                    note: 'DeepSeek',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'deepseek',
                defaultModelId: 'deepseek-v4-pro',
                modelSettings: const {
                  'provider_id': 'deepseek',
                  'model_id': 'deepseek-v4-pro',
                  'temperature': '0.7',
                  'top_p': '0.9',
                  'thinking_enabled': true,
                  'thinking_effort': 'medium',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'deepseek',
                  providerLabel: 'DeepSeek',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://api.deepseek.com',
                  modelId: 'deepseek-v4-pro',
                  supportsReasoning: true,
                  reasoningCanToggle: true,
                  reasoningDefaultEnabled: true,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: true,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'deepseek_thinking_object',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: true,
                  thinkingEffortSupported: true,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'medium',
                  thinkingEffortOptions: ['low', 'medium', 'high'],
                  temperature: 0.7,
                  topP: 0.9,
                  topK: 40,
                  modelSuggestions: [
                    SettingsSearchOption(
                      value: 'deepseek-v4-pro',
                      label: 'deepseek-v4-pro',
                      note: 'DeepSeek',
                    ),
                  ],
                  customParameters: [
                    ModelParameterEntryViewData(
                      keyName: 'response_format',
                      valueType: 'json',
                      value: '{"type":"json_object"}',
                    ),
                  ],
                  supportedParameters: ['temperature', 'top_p', 'top_k'],
                  unsupportedParameters: [],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                  capabilityExposure: CapabilityExposureViewData(
                    protocolMode: 'openai_compatible',
                    protocolLabel: 'OpenAI 协议格式',
                    apiMode: 'chat',
                    routeFamily: 'chat_completions',
                    allowedApiModes: ['chat'],
                    allowedRouteFamilies: ['chat_completions'],
                    apiModeVisible: false,
                    visibleAdvancedFields: const ['top_k'],
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (payload) {
                savedPayload = payload;
              },
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('写作模型'), findsOneWidget);
      expect(find.text('默认接口'), findsOneWidget);
      expect(find.text('默认模型'), findsOneWidget);
      expect(find.text('模型 ID'), findsNothing);
      expect(find.text('启用深度思考'), findsOneWidget);
      expect(find.text('深度思考强度'), findsOneWidget);
      expect(find.text('温度'), findsOneWidget);
      expect(find.text('Top P'), findsOneWidget);
      expect(find.text('能力摘要'), findsNothing);
      expect(find.text('Base URL'), findsNothing);
      expect(find.text('参数支持'), findsNothing);
      expect(find.text('API 模式'), findsNothing);

      expect(find.text('上下文窗口长度'), findsNothing);
      expect(find.text('Top K'), findsNothing);
      expect(find.text('添加高级参数'), findsNothing);
      expect(find.text('other-provider-model'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('展开高级项'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('展开高级项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('展开高级项'));
      await tester.pumpAndSettle();

      expect(find.text('上下文窗口长度'), findsOneWidget);
      expect(find.text('应用上下文长度'), findsOneWidget);
      expect(find.text('Top K'), findsOneWidget);
      expect(find.text('添加高级参数'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('保存模型设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('保存模型设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存模型设置'));
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(savedPayload!['provider_id'], 'deepseek');
      expect(savedPayload!['temperature'], '0.7');
      expect(savedPayload!['top_p'], '0.9');
      expect(savedPayload!['thinking_enabled'], isTrue);
    },
  );

  testWidgets(
    'model settings panel saves the selected provider/model pair when editor suggestions come from another provider',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'deepseek',
                    title: 'DeepSeek',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.deepseek.com',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                  ProviderEndpointViewData(
                    id: 'siliconflow',
                    title: 'SiliconFlow',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.siliconflow.cn/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'deepseek-v4-pro',
                    label: 'deepseek-v4-pro',
                    note: 'DeepSeek',
                  ),
                  SettingsSearchOptionViewData(
                    value: 'deepseek-ai/DeepSeek-V4-Flash',
                    label: 'deepseek-ai/DeepSeek-V4-Flash',
                    note: 'SiliconFlow',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'siliconflow',
                defaultModelId: 'deepseek-ai/DeepSeek-V4-Flash',
                modelSettings: const {
                  'provider_id': 'siliconflow',
                  'model_id': 'deepseek-ai/DeepSeek-V4-Flash',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'deepseek',
                  providerLabel: 'DeepSeek',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://api.deepseek.com',
                  modelId: 'deepseek-v4-pro',
                  supportsReasoning: true,
                  reasoningCanToggle: true,
                  reasoningDefaultEnabled: true,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'deepseek_thinking_object',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: true,
                  thinkingEffortSupported: true,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'medium',
                  thinkingEffortOptions: ['low', 'medium', 'high'],
                  temperature: 0.7,
                  topP: 0.9,
                  topK: 0,
                  modelSuggestions: [
                    SettingsSearchOption(
                      value: 'deepseek-v4-pro',
                      label: 'deepseek-v4-pro',
                      note: 'DeepSeek',
                    ),
                  ],
                  customParameters: [],
                  supportedParameters: ['temperature', 'top_p'],
                  unsupportedParameters: [],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (payload) {
                savedPayload = payload;
              },
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('保存模型设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('保存模型设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存模型设置'));
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(savedPayload!['provider_id'], 'siliconflow');
      expect(savedPayload!['model_id'], 'deepseek-ai/DeepSeek-V4-Flash');
    },
  );

  testWidgets(
    'model settings panel saves custom reasoning override for unknown models',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'custom_provider',
                    title: 'Custom Provider',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://custom.example.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'custom-writer-v1',
                    label: 'custom-writer-v1',
                    note: 'Custom Provider',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'custom_provider',
                defaultModelId: 'custom-writer-v1',
                modelSettings: const {
                  'provider_id': 'custom_provider',
                  'model_id': 'custom-writer-v1',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'custom_provider',
                  providerLabel: 'Custom Provider',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://custom.example.com/v1',
                  modelId: 'custom-writer-v1',
                  supportsReasoning: false,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: false,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'none',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: false,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: [],
                  temperature: 0.8,
                  topP: 0.95,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: [],
                  unsupportedParameters: [],
                  customReasoningOverride: CustomModelReasoningOverrideViewData(
                    isKnownWritingModel: false,
                    supportsReasoning: false,
                    reasoningCanToggle: true,
                    reasoningDefaultEnabled: false,
                    reasoningSupportsEffort: false,
                    toggleStrategyKind: 'boolean',
                    toggleKey: 'enable_thinking',
                    toggleEnabledValue: 'true',
                    toggleDisabledValue: 'false',
                    effortKey: 'reasoning_effort',
                    effortValues: {},
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (payload) {
                savedPayload = payload;
              },
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('展开高级项'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('展开高级项'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('展开高级项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('展开高级项'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('支持深度思考'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '例如 enable_thinking',
        ),
        'thinking_mode',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '例如 true / enabled',
        ),
        'enabled',
      );
      await tester.ensureVisible(find.text('支持强度调节'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('强度键名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '例如 reasoning_effort',
        ),
        'thinking_level',
      );
      await tester.tap(find.text('添加值项'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '例如 dynamic',
        ),
        'balanced',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == '例如 dynamic / budget / 200',
        ),
        'high',
      );

      await tester.scrollUntilVisible(
        find.text('保存模型设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('保存模型设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存模型设置'));
      await tester.pumpAndSettle();

      final customOverride =
          savedPayload!['custom_reasoning_override'] as Map<String, Object?>;
      expect(customOverride['supports_reasoning'], isTrue);
      expect(
        (customOverride['reasoning_toggle_parameter_strategy']
            as Map<String, Object?>)['key'],
        'thinking_mode',
      );
      expect(
        (customOverride['reasoning_effort_parameter_strategy']
            as Map<String, Object?>)['key'],
        'thinking_level',
      );
      expect(
        (customOverride['reasoning_effort_parameter_strategy']
            as Map<String, Object?>)['values'],
        containsPair('balanced', 'high'),
      );
    },
  );

  testWidgets(
    'model settings panel hides toggle strategy fields for always-thinking custom models',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'custom_provider',
                    title: 'Custom Provider',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://custom.example.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'custom-thinking-writer',
                    label: 'custom-thinking-writer',
                    note: 'Custom Provider',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'custom_provider',
                defaultModelId: 'custom-thinking-writer',
                modelSettings: const {
                  'provider_id': 'custom_provider',
                  'model_id': 'custom-thinking-writer',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'custom_provider',
                  providerLabel: 'Custom Provider',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://custom.example.com/v1',
                  modelId: 'custom-thinking-writer',
                  supportsReasoning: false,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: false,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'none',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: false,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: [],
                  temperature: 0.8,
                  topP: 0.95,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: [],
                  unsupportedParameters: [],
                  customReasoningOverride: CustomModelReasoningOverrideViewData(
                    isKnownWritingModel: false,
                    supportsReasoning: true,
                    reasoningCanToggle: false,
                    reasoningDefaultEnabled: true,
                    reasoningSupportsEffort: false,
                    toggleStrategyKind: 'boolean',
                    toggleKey: 'enable_thinking',
                    toggleEnabledValue: 'true',
                    toggleDisabledValue: 'false',
                    effortKey: 'reasoning_effort',
                    effortValues: {
                      'auto': 'auto',
                      'low': 'low',
                      'medium': 'medium',
                      'high': 'high',
                      'max': 'max',
                    },
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (payload) {
                savedPayload = payload;
              },
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('展开高级项'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('展开高级项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('展开高级项'));
      await tester.pumpAndSettle();

      expect(find.text('允许开关'), findsOneWidget);
      expect(find.text('当前会按“始终思考”处理，不需要额外填写开关参数。'), findsOneWidget);
      expect(find.text('开关参数类型'), findsNothing);
      expect(find.text('开关键名'), findsNothing);
      expect(find.text('开启时传值'), findsNothing);
      expect(find.text('关闭时传值'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('保存模型设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('保存模型设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存模型设置'));
      await tester.pumpAndSettle();

      final customOverride =
          savedPayload!['custom_reasoning_override'] as Map<String, Object?>;
      expect(customOverride['supports_reasoning'], isTrue);
      expect(customOverride['reasoning_can_toggle'], isFalse);
    },
  );

  testWidgets(
    'model settings panel shows read-only reasoning state for always-thinking custom models',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'custom_provider',
                    title: 'Custom Provider',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://custom.example.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'custom-thinking-writer',
                    label: 'custom-thinking-writer',
                    note: 'Custom Provider',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'custom_provider',
                defaultModelId: 'custom-thinking-writer',
                modelSettings: const {
                  'provider_id': 'custom_provider',
                  'model_id': 'custom-thinking-writer',
                  'thinking_effort': 'medium',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'custom_provider',
                  providerLabel: 'Custom Provider',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://custom.example.com/v1',
                  modelId: 'custom-thinking-writer',
                  supportsReasoning: true,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: true,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'reasoning_effort_only',
                  thinkingParameterLabel: '自定义深度思考参数',
                  thinkingEnabled: true,
                  thinkingEffortSupported: true,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'medium',
                  thinkingEffortOptions: ['low', 'medium', 'high'],
                  temperature: 0.8,
                  topP: 0.95,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: [
                    'temperature',
                    'top_p',
                    'reasoning_effort',
                  ],
                  unsupportedParameters: ['top_k'],
                  customReasoningOverride: CustomModelReasoningOverrideViewData(
                    isKnownWritingModel: false,
                    supportsReasoning: true,
                    reasoningCanToggle: false,
                    reasoningDefaultEnabled: true,
                    reasoningSupportsEffort: true,
                    toggleStrategyKind: 'custom_text',
                    toggleKey: 'thinking_mode',
                    toggleEnabledValue: 'enabled',
                    toggleDisabledValue: 'disabled',
                    effortKey: 'thinking_level',
                    effortValues: {
                      'auto': 'auto',
                      'low': 'low',
                      'medium': 'mid',
                      'high': 'high',
                      'max': 'max',
                    },
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启用深度思考'), findsNothing);
      expect(find.text('当前模型始终启用'), findsOneWidget);
      expect(find.text('深度思考强度'), findsOneWidget);
      expect(find.text('温度'), findsOneWidget);
      expect(find.text('Top P'), findsOneWidget);
    },
  );

  testWidgets(
    'model settings panel preserves thinking object override values from valid json text',
    (tester) async {
      Map<String, Object?>? savedPayload;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'custom_provider',
                    title: 'Custom Provider',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://custom.example.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'custom-object-reasoning-model',
                    label: 'custom-object-reasoning-model',
                    note: 'Custom Provider',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'custom_provider',
                defaultModelId: 'custom-object-reasoning-model',
                modelSettings: const {
                  'provider_id': 'custom_provider',
                  'model_id': 'custom-object-reasoning-model',
                  'custom_reasoning_override': {
                    'supports_reasoning': true,
                    'reasoning_can_toggle': true,
                    'reasoning_default_enabled': false,
                    'reasoning_supports_effort': false,
                    'reasoning_toggle_parameter_strategy': {
                      'kind': 'thinking_object',
                      'key': 'thinking',
                      'enabled_value': {'type': 'enabled'},
                      'disabled_value': {'type': 'disabled'},
                    },
                  },
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'custom_provider',
                  providerLabel: 'Custom Provider',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://custom.example.com/v1',
                  modelId: 'custom-object-reasoning-model',
                  supportsReasoning: false,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: false,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'none',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: false,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: [],
                  temperature: 0.8,
                  topP: 0.95,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: [],
                  unsupportedParameters: [],
                  customReasoningOverride: CustomModelReasoningOverrideViewData(
                    isKnownWritingModel: false,
                    supportsReasoning: true,
                    reasoningCanToggle: true,
                    reasoningDefaultEnabled: false,
                    reasoningSupportsEffort: false,
                    toggleStrategyKind: 'thinking_object',
                    toggleKey: 'thinking',
                    toggleEnabledValue: '{"type":"enabled"}',
                    toggleDisabledValue: '{"type":"disabled"}',
                    effortKey: 'reasoning_effort',
                    effortValues: {
                      'auto': 'auto',
                      'low': 'low',
                      'medium': 'medium',
                      'high': 'high',
                      'max': 'max',
                    },
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (payload) {
                savedPayload = payload;
              },
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('展开高级项'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('展开高级项'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('展开高级项'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.controller?.text == '{"type":"enabled"}',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.controller?.text == '{"type":"disabled"}',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('保存模型设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('保存模型设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存模型设置'));
      await tester.pumpAndSettle();

      final customOverride =
          savedPayload!['custom_reasoning_override'] as Map<String, Object?>;
      final toggleStrategy =
          customOverride['reasoning_toggle_parameter_strategy']
              as Map<String, Object?>;
      expect(toggleStrategy['enabled_value'], {'type': 'enabled'});
      expect(toggleStrategy['disabled_value'], {'type': 'disabled'});
    },
  );

  testWidgets(
    'model settings panel hides reasoning controls for non-reasoning models',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'openai',
                    title: 'OpenAI',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.openai.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'gpt-4.1-mini',
                    label: 'gpt-4.1-mini',
                    note: 'OpenAI',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'openai',
                defaultModelId: 'gpt-4.1-mini',
                modelSettings: const {
                  'provider_id': 'openai',
                  'model_id': 'gpt-4.1-mini',
                  'temperature': '0.7',
                  'top_p': '0.9',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'openai',
                  providerLabel: 'OpenAI',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://api.openai.com/v1',
                  modelId: 'gpt-4.1-mini',
                  supportsReasoning: false,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: false,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'none',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: false,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: [],
                  temperature: 0.7,
                  topP: 0.9,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: ['temperature', 'top_p'],
                  unsupportedParameters: ['thinking', 'reasoning_effort'],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启用深度思考'), findsNothing);
      expect(find.text('深度思考强度'), findsNothing);
      expect(find.text('当前模型始终启用'), findsNothing);
      expect(find.text('温度'), findsOneWidget);
      expect(find.text('Top P'), findsOneWidget);
    },
  );

  testWidgets(
    'model settings panel shows read-only reasoning state for thinking-only models',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'moonshot',
                    title: 'Kimi',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://platform.kimi.ai',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'kimi-k2-thinking',
                    label: 'kimi-k2-thinking',
                    note: 'Kimi',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'moonshot',
                defaultModelId: 'kimi-k2-thinking',
                modelSettings: const {
                  'provider_id': 'moonshot',
                  'model_id': 'kimi-k2-thinking',
                  'thinking_effort': 'high',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'moonshot',
                  providerLabel: 'Kimi',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://platform.kimi.ai',
                  modelId: 'kimi-k2-thinking',
                  supportsReasoning: true,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: true,
                  supportsTemperature: false,
                  supportsTopP: false,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'reasoning_effort_only',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: true,
                  thinkingEffortSupported: true,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: ['low', 'medium', 'high'],
                  temperature: 0.0,
                  topP: 0.0,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: ['reasoning_effort'],
                  unsupportedParameters: ['temperature', 'top_p', 'top_k'],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启用深度思考'), findsNothing);
      expect(find.text('当前模型始终启用'), findsOneWidget);
      expect(find.text('深度思考强度'), findsOneWidget);
      expect(find.text('温度'), findsNothing);
      expect(find.text('Top P'), findsNothing);
    },
  );

  testWidgets(
    'model settings panel hides api mode when capability exposure says only one route is visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'anthropic',
                    title: 'Anthropic',
                    protocol: 'anthropic_compatible',
                    baseUrl: 'https://api.anthropic.com/v1',
                    rawApiKey: '',
                    apiKeyState: 'configured',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [],
                tabSections: const {},
                defaultProviderId: 'anthropic',
                defaultModelId: 'claude-3-5-sonnet-20241022',
                modelSettings: const {
                  'provider_id': 'anthropic',
                  'model_id': 'claude-3-5-sonnet-20241022',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'anthropic',
                  providerLabel: 'Anthropic',
                  protocolMode: 'anthropic_compatible',
                  baseUrl: 'https://api.anthropic.com/v1',
                  modelId: 'claude-3-5-sonnet-20241022',
                  supportsReasoning: true,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: true,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'content_block_thinking',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: true,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: ['high'],
                  temperature: 0.7,
                  topP: 0.9,
                  topK: 0,
                  modelSuggestions: const [],
                  customParameters: const [],
                  supportedParameters: const [],
                  unsupportedParameters: const [],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                  capabilityExposure: CapabilityExposureViewData(
                    protocolMode: 'anthropic_compatible',
                    protocolLabel: 'Anthropic 协议格式',
                    apiMode: 'messages',
                    routeFamily: 'messages',
                    allowedApiModes: ['messages'],
                    allowedRouteFamilies: ['messages'],
                    apiModeVisible: false,
                    visibleAdvancedFields: const ['stream'],
                  ),
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (_) async =>
                  ProviderConnectionValidationResultViewData.initial,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('API 模式'), findsNothing);
      expect(find.text('Top K'), findsNothing);
    },
  );

  testWidgets(
    'model settings panel runs connection test with the selected provider+model pair',
    (tester) async {
      Map<String, Object?>? testPayload;
      const testResult = ProviderConnectionValidationResultViewData(
        isSuccess: true,
        summary: '连接成功（测试）',
        details: ['探测明细 A'],
        errors: [],
        templateId: '',
        providerId: 'deepseek',
        protocolId: '',
        protocolMode: 'openai_compatible',
        routeFamily: '',
        selectedRouteFamily: '',
        allowedRouteFamilies: [],
        hideOptions: [],
        fallbackNotAllowed: false,
        warnings: [],
        matchedTemplateId: '',
        matchedTemplateLabel: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'deepseek',
                    title: 'DeepSeek',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.deepseek.com',
                    rawApiKey: 'sk-test',
                    apiKeyState: '已配置密钥',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [
                  SettingsSearchOptionViewData(
                    value: 'deepseek-chat',
                    label: 'deepseek-chat',
                    note: 'DeepSeek',
                  ),
                ],
                tabSections: const {},
                defaultProviderId: 'deepseek',
                defaultModelId: 'deepseek-chat',
                modelSettings: const {
                  'provider_id': 'deepseek',
                  'model_id': 'deepseek-chat',
                },
                modelEditor: const ModelEditorViewData(
                  providerId: 'deepseek',
                  providerLabel: 'DeepSeek',
                  protocolMode: 'openai_compatible',
                  baseUrl: 'https://api.deepseek.com',
                  modelId: 'deepseek-chat',
                  supportsReasoning: false,
                  reasoningCanToggle: false,
                  reasoningDefaultEnabled: false,
                  supportsTemperature: true,
                  supportsTopP: true,
                  supportsTopK: false,
                  supportsStreaming: true,
                  supportsTools: true,
                  supportsToolChoice: false,
                  supportsFileAttachments: false,
                  supportsImageAttachments: false,
                  supportsAttachmentUrlsOnly: false,
                  supportsMultiAttachments: false,
                  thinkingParameterFormat: 'none',
                  thinkingParameterLabel: '深度思考',
                  thinkingEnabled: false,
                  thinkingEffortSupported: false,
                  thinkingEffortParameterLabel: '深度思考强度',
                  thinkingEffort: 'high',
                  thinkingEffortOptions: [],
                  temperature: 0.8,
                  topP: 0.95,
                  topK: 0,
                  modelSuggestions: [],
                  customParameters: [],
                  supportedParameters: ['temperature', 'top_p'],
                  unsupportedParameters: [],
                  customReasoningOverride:
                      CustomModelReasoningOverrideViewData.initial,
                ),
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (payload) {
                testPayload = payload;
                return Future.value(testResult);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 中文注释: 已选接口+模型时测试按钮可用；点击后用真实配对发起探测并展示结果。
      final testButton = find.text('测试连接');
      expect(testButton, findsOneWidget);
      await tester.ensureVisible(testButton);
      await tester.pumpAndSettle();
      await tester.tap(testButton);
      await tester.pumpAndSettle();

      expect(testPayload, isNotNull);
      expect(testPayload!['source_id'], 'deepseek');
      expect(testPayload!['provider_id'] ?? testPayload!['source_id'], 'deepseek');
      expect(testPayload!['model_id'], 'deepseek-chat');
      expect(find.text('连接成功（测试）'), findsOneWidget);
      expect(find.text('• 探测明细 A'), findsOneWidget);
    },
  );

  testWidgets(
    'model settings panel disables connection test until both provider and model are chosen',
    (tester) async {
      Map<String, Object?>? testPayload;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ModelSettingsPanel(
              viewData: SettingsViewData(
                activeTabId: 'models',
                tabs: const [],
                providers: const [
                  ProviderEndpointViewData(
                    id: 'deepseek',
                    title: 'DeepSeek',
                    protocol: 'openai_compatible',
                    baseUrl: 'https://api.deepseek.com',
                    rawApiKey: 'sk-test',
                    apiKeyState: '已配置密钥',
                    description: '',
                  ),
                ],
                providerDirectoryOptions: const [],
                allModelOptions: const [],
                tabSections: const {},
                defaultProviderId: '',
                defaultModelId: '',
                modelSettings: const {},
                modelEditor: ModelEditorViewData.initial,
                defaultProjectPath: '',
                permissionSettings: const {},
                toolStrategySettings: const {},
                projectCreationExpressionConstraintDefaults:
                    ProjectCreationExpressionConstraintDefaultsViewData.initial(),
                networkSettings: const {},
                contextSettings: const {},
                themeSettings: const {},
                themeViewData: ThemeSettingsViewData.initial(),
                settingsRootPath: '',
                settingsSearchRoots: const [],
                defaultProjectsRootPath: '',
                isMobileProjectRootLocked: false,
              ),
              onSaved: (_) {},
              onConnectionTestRequested: (payload) {
                testPayload = payload;
                return Future.value(
                  ProviderConnectionValidationResultViewData.initial,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 中文注释: 未选接口/模型时按钮禁用，点击不会触发探测。
      final testButton = find.text('测试连接');
      expect(testButton, findsOneWidget);
      await tester.ensureVisible(testButton);
      await tester.pumpAndSettle();
      await tester.tap(testButton);
      await tester.pumpAndSettle();

      expect(testPayload, isNull);
    },
  );
}
