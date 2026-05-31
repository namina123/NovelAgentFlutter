import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_state.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_input_action_row.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_input_dock.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_send_config_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'conversation input dock keeps a fixed-height scrolling text field',
    (tester) async {
      final textController = TextEditingController();
      final scrollController = ScrollController();
      addTearDown(() {
        textController.dispose();
        scrollController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: ConversationInputDock(
                  controller: textController,
                  scrollController: scrollController,
                  hintText: '输入你的需求',
                  capabilities: const ConversationInputCapabilityState(
                    supportsReasoningToggle: false,
                    showReasoningToggle: false,
                    reasoningEnabled: false,
                    supportsOptimizeAction: false,
                    showOptimizeAction: false,
                    supportsToolOptionsAction: false,
                    showToolOptionsAction: false,
                    supportsStopAction: false,
                    showStopAction: false,
                    supportsAttachmentEntry: false,
                    showAttachmentEntry: false,
                    canSendAction: true,
                    submitLabel: '发送',
                  ),
                  actionHandler: const _FakeConversationActionHandler(),
                  onSendRequested: () {},
                  modelLabel: '测试模型',
                  modelOptions: const <SelectorOptionViewData>[
                    SelectorOptionViewData(id: 'test_model', label: '测试模型'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final fieldBox = tester.renderObject<RenderBox>(find.byType(TextField));

      expect(textField.expands, isTrue);
      expect(textField.minLines, isNull);
      expect(textField.maxLines, isNull);
      expect(fieldBox.size.height, greaterThanOrEqualTo(90));
      expect(find.byType(ConversationSendConfigBar), findsOneWidget);
      expect(find.text('模型'), findsOneWidget);

      final configBarTop = tester.getTopLeft(
        find.byType(ConversationSendConfigBar),
      );
      final textFieldTop = tester.getTopLeft(find.byType(TextField));

      expect(configBarTop.dy, lessThan(textFieldTop.dy));
    },
  );

  testWidgets(
    'conversation input dock shows stop action while generation is active',
    (tester) async {
      final textController = TextEditingController();
      final scrollController = ScrollController();
      addTearDown(() {
        textController.dispose();
        scrollController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ConversationInputDock(
                controller: textController,
                scrollController: scrollController,
                hintText: '输入你的需求',
                capabilities: const ConversationInputCapabilityState(
                  supportsReasoningToggle: false,
                  showReasoningToggle: false,
                  reasoningEnabled: false,
                  supportsOptimizeAction: false,
                  showOptimizeAction: false,
                  supportsToolOptionsAction: false,
                  showToolOptionsAction: false,
                  supportsStopAction: true,
                  showStopAction: true,
                  supportsAttachmentEntry: false,
                  showAttachmentEntry: false,
                  canSendAction: false,
                  submitLabel: '生成中',
                ),
                actionHandler: const _FakeConversationActionHandler(),
                onSendRequested: () {},
                modelLabel: '测试模型',
                modelOptions: const <SelectorOptionViewData>[
                  SelectorOptionViewData(id: 'test_model', label: '测试模型'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('停止'), findsOneWidget);
      expect(find.text('发送'), findsNothing);
    },
  );

  testWidgets(
    'conversation input dock keeps reasoning toggle in inline action row below the text field',
    (tester) async {
      final textController = TextEditingController();
      final scrollController = ScrollController();
      addTearDown(() {
        textController.dispose();
        scrollController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ConversationInputDock(
                controller: textController,
                scrollController: scrollController,
                hintText: '输入你的需求',
                capabilities: const ConversationInputCapabilityState(
                  supportsReasoningToggle: true,
                  showReasoningToggle: true,
                  reasoningEnabled: true,
                  supportsOptimizeAction: false,
                  showOptimizeAction: false,
                  supportsToolOptionsAction: false,
                  showToolOptionsAction: false,
                  supportsStopAction: false,
                  showStopAction: false,
                  supportsAttachmentEntry: false,
                  showAttachmentEntry: false,
                  canSendAction: true,
                  submitLabel: '发送',
                ),
                actionHandler: const _FakeConversationActionHandler(),
                onSendRequested: () {},
                modelLabel: '测试模型',
                modelOptions: const <SelectorOptionViewData>[
                  SelectorOptionViewData(id: 'test_model', label: '测试模型'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConversationSendConfigBar), findsOneWidget);
      expect(find.text('深度思考'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(ConversationReasoningToggleChip), findsOneWidget);

      final configBarFinder = find.byType(ConversationSendConfigBar);
      final actionRowFinder = find.byType(ConversationInputActionRow);
      final textFieldTop = tester.getTopLeft(find.byType(TextField));
      final configBarTop = tester.getTopLeft(configBarFinder);
      final actionRowTop = tester.getTopLeft(actionRowFinder);

      expect(configBarTop.dy, lessThan(textFieldTop.dy));
      expect(textFieldTop.dy, lessThan(actionRowTop.dy));
      expect(
        find.descendant(of: configBarFinder, matching: find.text('深度思考')),
        findsNothing,
      );
      expect(
        find.descendant(of: actionRowFinder, matching: find.text('深度思考')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'conversation input dock renders reasoning chip as neutral when off and accent when on',
    (tester) async {
      Future<void> pumpDock({required bool reasoningEnabled}) async {
        final textController = TextEditingController();
        final scrollController = ScrollController();
        addTearDown(() {
          textController.dispose();
          scrollController.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: ConversationInputDock(
                  controller: textController,
                  scrollController: scrollController,
                  hintText: '输入你的需求',
                  capabilities: ConversationInputCapabilityState(
                    supportsReasoningToggle: true,
                    showReasoningToggle: true,
                    reasoningEnabled: reasoningEnabled,
                    supportsOptimizeAction: false,
                    showOptimizeAction: false,
                    supportsToolOptionsAction: false,
                    showToolOptionsAction: false,
                    supportsStopAction: false,
                    showStopAction: false,
                    supportsAttachmentEntry: false,
                    showAttachmentEntry: false,
                    canSendAction: true,
                    submitLabel: '发送',
                  ),
                  actionHandler: const _FakeConversationActionHandler(),
                  onSendRequested: () {},
                  modelLabel: '测试模型',
                  modelOptions: const <SelectorOptionViewData>[
                    SelectorOptionViewData(id: 'test_model', label: '测试模型'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await pumpDock(reasoningEnabled: false);
      await tester.pumpAndSettle();

      final offContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ConversationReasoningToggleChip.containerKey),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final offDecoration = offContainer.decoration! as BoxDecoration;

      expect(offDecoration.color, isNot(AppTheme.light().colorScheme.primary));

      await pumpDock(reasoningEnabled: true);
      await tester.pumpAndSettle();

      final onContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ConversationReasoningToggleChip.containerKey),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final onDecoration = onContainer.decoration! as BoxDecoration;

      expect(onDecoration.color, AppTheme.light().colorScheme.primary);
    },
  );
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  const _FakeConversationActionHandler();

  @override
  void onAgentGroupSelected(String groupId) {}

  @override
  void onConversationAgentSelected(String agentId) {}

  @override
  void onAttachmentRequested() {}

  @override
  void onConversationSettingsRequested() {}

  @override
  void onDocumentsWorkspaceDismissRequested() {}

  @override
  void onDocumentsWorkspaceRequested() {}

  @override
  void onHistoryRequested() {}

  @override
  void onModelSelected(String modelId) {}

  @override
  void onNewSessionRequested() {}

  @override
  void onOptimizeRequested() {}

  @override
  void onPrimaryActionRequested(String actionId) {}

  @override
  void onReasoningToggleChanged(bool enabled) {}

  @override
  void onQuickThemeRequested() {}

  @override
  void onRetryLastFailedRequested() {}

  @override
  void onScreenModeRequested() {}

  @override
  void onSendRequested(String text) {}

  @override
  void onSessionHistorySelected(String sessionId) {}

  @override
  void onStopRequested() {}

  @override
  void onToolOptionsRequested() {}

  @override
  void onUserOptionSelected(UserOptionViewData option) {}
}
