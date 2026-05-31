import 'package:flutter/material.dart';

import '../../app/theme/control_style_specs.dart';
import '../../app/theme/control_style_token_set.dart';
import '../../app/theme/novel_theme_extension.dart';
import '../../app/theme/theme_color_tokens.dart';
import '../../app/theme/theme_descriptor.dart';
import '../../app/theme/theme_surface_spec_set.dart';
import '../../app/theme/theme_token_set.dart';

extension NovelThemeContext on BuildContext {
  ThemeTokenSet get novelThemeTokenSet {
    final extension = Theme.of(this).extension<NovelThemeExtension>();
    if (extension == null) {
      throw StateError('NovelThemeExtension is not attached to ThemeData.');
    }
    return extension.tokenSet;
  }

  ThemeDescriptor get novelThemeDescriptor => novelThemeTokenSet.descriptor;

  ThemeColorTokens get novelThemeColors => novelThemeTokenSet.colors;

  ControlStyleTokenSet get novelControlStyleTokenSet =>
      novelThemeTokenSet.controlStyle;

  PanelChromeSpec get novelPanelChrome => novelControlStyleTokenSet.panel;

  ButtonChromeSpec get novelButtonChrome => novelControlStyleTokenSet.button;

  ToolbarChromeSpec get novelToolbarChrome => novelControlStyleTokenSet.toolbar;

  InputChromeSpec get novelInputChrome => novelControlStyleTokenSet.input;

  ChipChromeSpec get novelChipChrome => novelControlStyleTokenSet.chip;

  CardChromeSpec get novelCardChrome => novelControlStyleTokenSet.card;

  ThemeSurfaceSpecSet get novelThemeSurfaces => novelThemeTokenSet.surfaces;
}
