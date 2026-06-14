import 'package:flutter/material.dart';

/// Catalog of cosmic event categories. Each one maps to a visual icon/color
/// shown in the notification tile and a translation key in the ARB files.
enum CosmicEventType {
  eclipse, // solar
  lunarEclipse,
  meteorShower,
  planetConjunction,
  supermoon,
  comet,
  issPass,
  other,
}

extension CosmicEventTypeUi on CosmicEventType {
  IconData get icon {
    switch (this) {
      case CosmicEventType.eclipse:
        return Icons.wb_sunny;
      case CosmicEventType.lunarEclipse:
        return Icons.nightlight_round;
      case CosmicEventType.meteorShower:
        return Icons.filter_drama;
      case CosmicEventType.planetConjunction:
        return Icons.public;
      case CosmicEventType.supermoon:
        return Icons.brightness_2;
      case CosmicEventType.comet:
        return Icons.star;
      case CosmicEventType.issPass:
        return Icons.rocket_launch;
      case CosmicEventType.other:
        return Icons.auto_awesome;
    }
  }

  Color get color {
    switch (this) {
      case CosmicEventType.eclipse:
        return Colors.deepOrange;
      case CosmicEventType.lunarEclipse:
        return Colors.indigo;
      case CosmicEventType.meteorShower:
        return Colors.cyan;
      case CosmicEventType.planetConjunction:
        return Colors.teal;
      case CosmicEventType.supermoon:
        return Colors.amber;
      case CosmicEventType.comet:
        return Colors.pink;
      case CosmicEventType.issPass:
        return Colors.lightBlue;
      case CosmicEventType.other:
        return Colors.amber;
    }
  }
}

CosmicEventType cosmicTypeFromString(String? value) {
  if (value == null) return CosmicEventType.other;
  return CosmicEventType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CosmicEventType.other,
  );
}
