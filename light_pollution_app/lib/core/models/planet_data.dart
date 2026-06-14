class PlanetVisibility {
  const PlanetVisibility({
    required this.name,
    required this.isVisible,
    required this.magnitude,
    this.riseTime,
    this.setTime,
    this.constellation,
  });

  final String name;
  final bool isVisible;
  final double magnitude;
  final String? riseTime;
  final String? setTime;
  final String? constellation;

  String get brightnessLabel {
    if (magnitude < -3) return 'Very bright';
    if (magnitude < -1) return 'Bright';
    if (magnitude < 1) return 'Moderate';
    if (magnitude < 3) return 'Dim';
    return 'Faint';
  }

  String get icon {
    switch (name) {
      case 'Mercury':
        return '☿';
      case 'Venus':
        return '♀';
      case 'Mars':
        return '♂';
      case 'Jupiter':
        return '♃';
      case 'Saturn':
        return '♄';
      default:
        return '●';
    }
  }
}
