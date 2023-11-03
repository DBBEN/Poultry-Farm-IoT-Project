import 'package:flutter/material.dart';

const MaterialColor primary = MaterialColor(_primaryPrimaryValue, <int, Color>{
  50: Color(0xFFE2EDE9),
  100: Color(0xFFB6D3C7),
  200: Color(0xFF86B5A2),
  300: Color(0xFF56977D),
  400: Color(0xFF318161),
  500: Color(_primaryPrimaryValue),
  600: Color(0xFF0B633E),
  700: Color(0xFF095836),
  800: Color(0xFF074E2E),
  900: Color(0xFF033C1F),
});
const int _primaryPrimaryValue = 0xFF0D6B45;

const MaterialColor primaryAccent = MaterialColor(_primaryAccentValue, <int, Color>{
  100: Color(0xFF72FFAC),
  200: Color(_primaryAccentValue),
  400: Color(0xFF0CFF6F),
  700: Color(0xFF00F163),
});
const int _primaryAccentValue = 0xFF3FFF8D;