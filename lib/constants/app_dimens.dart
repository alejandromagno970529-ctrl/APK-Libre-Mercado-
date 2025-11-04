import 'package:flutter/material.dart';

class AppDimens {
  // ESPACIADO
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;

  // BORDES REDONDEADOS
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;

  // TAMAÑOS DE WIDGETS
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double buttonHeight = 48.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // TAMAÑOS DE TEXTO
  static const double textSizeXS = 10.0;
  static const double textSizeS = 12.0;
  static const double textSizeM = 14.0;
  static const double textSizeL = 16.0;
  static const double textSizeXL = 18.0;
  static const double textSizeXXL = 20.0;

  // PADDINGS PREDEFINIDOS
  static const EdgeInsets paddingAllXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets paddingAllS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingAllM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingAllL = EdgeInsets.all(spaceL);
  static const EdgeInsets paddingAllXL = EdgeInsets.all(spaceXL);
  
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spaceS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spaceM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spaceL);
  
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spaceS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spaceM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spaceL);
}