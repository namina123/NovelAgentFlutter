import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';

void main() {
  test('app theme composes color theme and control style independently', () {
    final linear = AppTheme.tokenSetFor('builtin.light');
    final gentle = AppTheme.tokenSetFor(
      'builtin.light',
      controlStyleId: 'builtin.gentle',
    );

    expect(linear.descriptor.id, gentle.descriptor.id);
    expect(linear.colors.canvasBackground, gentle.colors.canvasBackground);
    expect(linear.colors.accentColor, gentle.colors.accentColor);

    expect(linear.controlStyle.descriptor.id, 'builtin.linear');
    expect(gentle.controlStyle.descriptor.id, 'builtin.gentle');
    expect(linear.surfaces.panel.radius, 0);
    expect(gentle.surfaces.panel.radius, 8);
    expect(linear.surfaces.inputDock.radius, 0);
    expect(gentle.surfaces.inputDock.radius, 8);
  });
}
