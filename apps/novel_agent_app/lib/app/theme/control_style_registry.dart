import 'package:flutter/material.dart';

import 'control_style_descriptor.dart';
import 'control_style_specs.dart';
import 'control_style_token_set.dart';

class ControlStyleRegistry {
  ControlStyleRegistry.builtIn() : _tokenSets = _createBuiltInTokenSets();

  static const String defaultStyleId = 'builtin.studio';

  final Map<String, ControlStyleTokenSet> _tokenSets;

  List<ControlStyleDescriptor> builtInDescriptors() {
    return _tokenSets.values
        .map((tokenSet) => tokenSet.descriptor)
        .toList(growable: false);
  }

  bool contains(String id) => _tokenSets.containsKey(id);

  ControlStyleTokenSet requireTokenSet(String id) {
    final tokenSet = _tokenSets[id];
    if (tokenSet == null) {
      throw StateError('Unknown control style token set: $id');
    }
    return tokenSet;
  }

  ControlStyleTokenSet defaultStyle() => requireTokenSet(defaultStyleId);

  static Map<String, ControlStyleTokenSet> _createBuiltInTokenSets() {
    return <String, ControlStyleTokenSet>{
      defaultStyleId: ControlStyleTokenSet(
        descriptor: const ControlStyleDescriptor(
          id: defaultStyleId,
          label: '工作台',
        ),
        panel: const PanelChromeSpec(
          radius: 8,
          borderWidth: 1,
          shadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x18040A14),
            ),
          ],
        ),
        button: const ButtonChromeSpec(
          radius: 8,
          borderWidth: 1,
          regularMinHeight: 42,
          compactMinHeight: 34,
          regularPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          compactPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          regularIconSize: 18,
          compactIconSize: 14,
        ),
        toolbar: const ToolbarChromeSpec(
          radius: 8,
          borderWidth: 1,
          buttonSize: 40,
          padding: EdgeInsets.all(5),
          iconSize: 15,
        ),
        input: const InputChromeSpec(
          radius: 8,
          borderWidth: 1,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minHeight: 46,
        ),
        chip: const ChipChromeSpec(
          radius: 7,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minHeight: 30,
        ),
        card: const CardChromeSpec(
          radius: 8,
          borderWidth: 1,
          dividerWidth: 1,
          shadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 8),
              color: Color(0x14040A14),
            ),
          ],
        ),
      ),
      'builtin.linear': ControlStyleTokenSet(
        descriptor: const ControlStyleDescriptor(
          id: 'builtin.linear',
          label: '线性',
        ),
        panel: const PanelChromeSpec(radius: 0, borderWidth: 1),
        button: const ButtonChromeSpec(
          radius: 0,
          borderWidth: 1,
          regularMinHeight: 42,
          compactMinHeight: 34,
          regularPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          compactPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          regularIconSize: 18,
          compactIconSize: 14,
        ),
        toolbar: const ToolbarChromeSpec(
          radius: 0,
          borderWidth: 1,
          buttonSize: 40,
          padding: EdgeInsets.all(6),
          iconSize: 16,
        ),
        input: const InputChromeSpec(
          radius: 0,
          borderWidth: 1,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minHeight: 44,
        ),
        chip: const ChipChromeSpec(
          radius: 0,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minHeight: 28,
        ),
        card: const CardChromeSpec(radius: 0, borderWidth: 1, dividerWidth: 1),
      ),
      'builtin.gentle': ControlStyleTokenSet(
        descriptor: const ControlStyleDescriptor(
          id: 'builtin.gentle',
          label: '柔和',
        ),
        panel: const PanelChromeSpec(
          radius: 8,
          borderWidth: 1,
          shadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x14000000),
            ),
          ],
        ),
        button: const ButtonChromeSpec(
          radius: 8,
          borderWidth: 1,
          regularMinHeight: 42,
          compactMinHeight: 34,
          regularPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          compactPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          regularIconSize: 18,
          compactIconSize: 14,
        ),
        toolbar: const ToolbarChromeSpec(
          radius: 8,
          borderWidth: 1,
          buttonSize: 40,
          padding: EdgeInsets.all(6),
          iconSize: 16,
        ),
        input: const InputChromeSpec(
          radius: 8,
          borderWidth: 1,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minHeight: 44,
        ),
        chip: const ChipChromeSpec(
          radius: 999,
          borderWidth: 1,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minHeight: 28,
        ),
        card: const CardChromeSpec(
          radius: 8,
          borderWidth: 1,
          dividerWidth: 1,
          shadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 16,
              offset: Offset(0, 8),
              color: Color(0x12000000),
            ),
          ],
        ),
      ),
    };
  }
}
