class MoonData {
  const MoonData({
    required this.phaseName,
    required this.illumination,
    required this.age,
    required this.phaseAngle,
  });

  final String phaseName;
  final double illumination; // 0.0 to 1.0
  final double age; // days into cycle (0-29.53)
  final double phaseAngle;

  int get illuminationPercent => (illumination * 100).round();

  String get impact {
    if (illumination < 0.1) return 'Minimal';
    if (illumination < 0.3) return 'Low';
    if (illumination < 0.6) return 'Moderate';
    if (illumination < 0.8) return 'High';
    return 'Severe';
  }

  String get impactDescription {
    if (illumination < 0.1) return 'Excellent for stargazing';
    if (illumination < 0.3) return 'Good conditions';
    if (illumination < 0.6) return 'Some sky brightness';
    if (illumination < 0.8) return 'Faint objects washed out';
    return 'Bright moonlight limits visibility';
  }
}
