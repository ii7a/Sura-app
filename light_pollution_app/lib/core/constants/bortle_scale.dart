import 'package:flutter/material.dart';

enum BortleClass {
  class1(1, 'Excellent Dark Sky', Color(0xFF000000), 'The Milky Way casts shadows. Zodiacal light, gegenschein visible.'),
  class2(2, 'Typical Dark Sky', Color(0xFF1A1A2E), 'Milky Way highly structured. Zodiacal light bright.'),
  class3(3, 'Rural Sky', Color(0xFF16213E), 'Milky Way still appears complex. Some light pollution on horizon.'),
  class4(4, 'Rural/Suburban Transition', Color(0xFF0F3460), 'Milky Way visible but lacks detail. Light domes visible.'),
  class5(5, 'Suburban Sky', Color(0xFF533483), 'Milky Way weak or invisible near horizon. Light domes prominent.'),
  class6(6, 'Bright Suburban Sky', Color(0xFFE94560), 'Milky Way only visible near zenith. Sky glow across entire horizon.'),
  class7(7, 'Suburban/Urban Transition', Color(0xFFFF6B35), 'Milky Way invisible. Sky has vague grayish-white hue.'),
  class8(8, 'City Sky', Color(0xFFFF9F1C), 'Sky glows white or orange. Only bright constellations visible.'),
  class9(9, 'Inner City Sky', Color(0xFFFFFFFF), 'Only Moon, planets, and a few bright stars visible.');

  const BortleClass(this.value, this.name, this.color, this.description);

  final int value;
  final String name;
  final Color color;
  final String description;

  static BortleClass fromValue(int value) {
    return BortleClass.values.firstWhere((b) => b.value == value);
  }
}
