import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/routing/app_shell_page_descriptor.dart';
import 'package:novel_agent_app/app/routing/app_shell_page_host.dart';

void main() {
  testWidgets(
    'AppShellPageHost lazily builds pages and preserves state across destination changes',
    (WidgetTester tester) async {
      _CounterPageState.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: AppShellPageHost(
            selectedDestination: AppDestination.workbench,
            pageDescriptors: <AppShellPageDescriptor>[
              AppShellPageDescriptor(
                destination: AppDestination.workbench,
                builder: (_) => const _CounterPage(label: 'workbench'),
              ),
              AppShellPageDescriptor(
                destination: AppDestination.longTaskStation,
                builder: (_) => const _CounterPage(label: 'longTaskStation'),
              ),
            ],
          ),
        ),
      );

      expect(_CounterPageState.initCount['workbench'], 1);
      expect(_CounterPageState.initCount['longTaskStation'] ?? 0, 0);
      expect(_CounterPageState.disposeCount['workbench'] ?? 0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: AppShellPageHost(
            selectedDestination: AppDestination.longTaskStation,
            pageDescriptors: <AppShellPageDescriptor>[
              AppShellPageDescriptor(
                destination: AppDestination.workbench,
                builder: (_) => const _CounterPage(label: 'workbench'),
              ),
              AppShellPageDescriptor(
                destination: AppDestination.longTaskStation,
                builder: (_) => const _CounterPage(label: 'longTaskStation'),
              ),
            ],
          ),
        ),
      );

      expect(_CounterPageState.initCount['workbench'], 1);
      expect(_CounterPageState.initCount['longTaskStation'], 1);
      expect(_CounterPageState.disposeCount['workbench'] ?? 0, 0);
      expect(_CounterPageState.disposeCount['longTaskStation'] ?? 0, 0);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(_CounterPageState.disposeCount['workbench'], 1);
      expect(_CounterPageState.disposeCount['longTaskStation'], 1);
    },
  );
}

class _CounterPage extends StatefulWidget {
  const _CounterPage({required this.label});

  final String label;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  static final Map<String, int> initCount = <String, int>{};
  static final Map<String, int> disposeCount = <String, int>{};

  static void reset() {
    initCount.clear();
    disposeCount.clear();
  }

  @override
  void initState() {
    super.initState();
    initCount.update(widget.label, (value) => value + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    disposeCount.update(widget.label, (value) => value + 1, ifAbsent: () => 1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(widget.label, textDirection: TextDirection.ltr),
    );
  }
}
