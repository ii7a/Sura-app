import 'dart:math';
import '../models/moon_data.dart';

class MoonService {
  /// Calculates moon phase algorithmically (no API needed).
  /// Uses a simplified version of the synodic month calculation.
  MoonData getMoonPhase([DateTime? date]) {
    final now = date ?? DateTime.now().toUtc();

    // Known new moon reference: Jan 6, 2000 18:14 UTC
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    const synodicMonth = 29.53058770576;

    final daysSinceRef = now.difference(reference).inSeconds / 86400.0;
    final age = daysSinceRef % synodicMonth;
    final normalizedAge = age < 0 ? age + synodicMonth : age;

    // Phase angle (0-360)
    final phaseAngle = (normalizedAge / synodicMonth) * 360.0;

    // Illumination (approximation using cosine)
    final illumination = (1 - cos(phaseAngle * pi / 180)) / 2;

    // Phase name
    final phaseName = _getPhaseName(normalizedAge, synodicMonth);

    return MoonData(
      phaseName: phaseName,
      illumination: illumination,
      age: normalizedAge,
      phaseAngle: phaseAngle,
    );
  }

  String _getPhaseName(double age, double synodicMonth) {
    final phase = age / synodicMonth;
    if (phase < 0.0338) return 'New Moon';
    if (phase < 0.2162) return 'Waxing Crescent';
    if (phase < 0.2838) return 'First Quarter';
    if (phase < 0.4662) return 'Waxing Gibbous';
    if (phase < 0.5338) return 'Full Moon';
    if (phase < 0.7162) return 'Waning Gibbous';
    if (phase < 0.7838) return 'Last Quarter';
    if (phase < 0.9662) return 'Waning Crescent';
    return 'New Moon';
  }
}
