import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/state/app_shell_auxiliary_controllers.dart';

void main() {
  group('LazyChangeNotifierSlot', () {
    test('creates controller only on first access and reuses instance', () {
      var createCount = 0;
      final slot = LazyChangeNotifierSlot<FakeNotifier>(() {
        createCount += 1;
        return FakeNotifier();
      });

      expect(slot.hasInstance, isFalse);

      final first = slot.instance;
      final second = slot.instance;

      expect(createCount, 1);
      expect(slot.hasInstance, isTrue);
      expect(identical(first, second), isTrue);
    });

    test('disposes created instance and resets slot', () {
      final created = <FakeNotifier>[];
      final slot = LazyChangeNotifierSlot<FakeNotifier>(() {
        final notifier = FakeNotifier();
        created.add(notifier);
        return notifier;
      });

      final first = slot.instance;
      slot.dispose();

      expect(first.disposed, isTrue);
      expect(slot.hasInstance, isFalse);

      final second = slot.instance;

      expect(identical(first, second), isFalse);
      expect(created.length, 2);
    });

    test('dispose is safe before controller creation', () {
      final slot = LazyChangeNotifierSlot<FakeNotifier>(() => FakeNotifier());

      slot.dispose();

      expect(slot.hasInstance, isFalse);
    });
  });
}

class FakeNotifier extends ChangeNotifier {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
