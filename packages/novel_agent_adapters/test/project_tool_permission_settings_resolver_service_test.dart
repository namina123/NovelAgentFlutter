import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolPermissionSettingsResolverService', () {
    const service = ProjectToolPermissionSettingsResolverService();

    test('defaults to safe tool permission context', () {
      final context = service.resolve(const <String, Object?>{});

      expect(context.allowRead, isTrue);
      expect(context.allowWrite, isTrue);
      expect(context.allowDelete, isFalse);
      expect(context.allowNetwork, isFalse);
      expect(context.allowProcess, isFalse);
      expect(context.allowSubAgents, isTrue);
      expect(context.allowLongTaskControl, isTrue);
      expect(context.allowFormalDelivery, isTrue);
      expect(context.permissionMode, HostToolPermissionModes.safe);
      expect(
        context.confirmationMode,
        HostToolConfirmationModes.userConfirmationRequired,
      );
    });

    test('maps open mode into fully enabled tool permission context', () {
      final context = service.resolve(const <String, Object?>{'mode': 'open'});

      expect(context.allowRead, isTrue);
      expect(context.allowWrite, isTrue);
      expect(context.allowDelete, isTrue);
      expect(context.allowNetwork, isTrue);
      expect(context.allowProcess, isTrue);
      expect(context.allowSubAgents, isTrue);
      expect(context.allowLongTaskControl, isTrue);
      expect(context.allowFormalDelivery, isTrue);
      expect(context.permissionMode, HostToolPermissionModes.open);
      expect(context.confirmationMode, HostToolConfirmationModes.automatic);
    });

    test('maps import_only into read and import friendly host context', () {
      final context = service.resolve(const <String, Object?>{
        'tool_permission_mode': 'import_only',
      });

      expect(context.allowRead, isTrue);
      expect(context.allowWrite, isFalse);
      expect(context.allowDelete, isFalse);
      expect(context.allowSubAgents, isFalse);
      expect(context.allowLongTaskControl, isFalse);
      expect(context.allowFormalDelivery, isFalse);
      expect(context.permissionMode, HostToolPermissionModes.importOnly);
    });

    test('respects explicit compatibility aliases', () {
      final context = service.resolve(const <String, Object?>{
        'permission_mode': 'custom',
        'tool_confirmation_mode': 'never',
        'allow_read': true,
        'allow_write': false,
        'allow_sub_agents': false,
        'allow_long_task_control': false,
        'allow_formal_delivery': false,
      });

      expect(context.permissionMode, HostToolPermissionModes.custom);
      expect(context.confirmationMode, HostToolConfirmationModes.never);
      expect(context.allowRead, isTrue);
      expect(context.allowWrite, isFalse);
      expect(context.allowSubAgents, isFalse);
      expect(context.allowLongTaskControl, isFalse);
      expect(context.allowFormalDelivery, isFalse);
    });
  });
}
