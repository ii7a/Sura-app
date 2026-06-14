import '../../l10n/app_localizations.dart';
import '../constants/bortle_scale.dart';
import '../models/moon_data.dart';
import '../models/planet_data.dart';
import '../../features/analysis/models/analysis_result.dart';

/// Localized names/descriptions for BortleClass
extension BortleClassL10n on BortleClass {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case BortleClass.class1: return l10n.bortleClass1Name;
      case BortleClass.class2: return l10n.bortleClass2Name;
      case BortleClass.class3: return l10n.bortleClass3Name;
      case BortleClass.class4: return l10n.bortleClass4Name;
      case BortleClass.class5: return l10n.bortleClass5Name;
      case BortleClass.class6: return l10n.bortleClass6Name;
      case BortleClass.class7: return l10n.bortleClass7Name;
      case BortleClass.class8: return l10n.bortleClass8Name;
      case BortleClass.class9: return l10n.bortleClass9Name;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case BortleClass.class1: return l10n.bortleClass1Desc;
      case BortleClass.class2: return l10n.bortleClass2Desc;
      case BortleClass.class3: return l10n.bortleClass3Desc;
      case BortleClass.class4: return l10n.bortleClass4Desc;
      case BortleClass.class5: return l10n.bortleClass5Desc;
      case BortleClass.class6: return l10n.bortleClass6Desc;
      case BortleClass.class7: return l10n.bortleClass7Desc;
      case BortleClass.class8: return l10n.bortleClass8Desc;
      case BortleClass.class9: return l10n.bortleClass9Desc;
    }
  }
}

/// Localized quality labels for AnalysisResult
extension AnalysisResultL10n on AnalysisResult {
  String localizedQualityLabel(AppLocalizations l10n) {
    if (isCloudy && skyQuality < 25) return l10n.cloudyOvercast;
    if (skyQuality >= 90) return l10n.pristineDarkSky;
    if (skyQuality >= 75) return l10n.darkSky;
    if (skyQuality >= 60) return l10n.ruralSky;
    if (skyQuality >= 45) return l10n.suburbanSky;
    if (skyQuality >= 30) return l10n.brightSuburban;
    if (skyQuality >= 15) return l10n.urbanSky;
    return l10n.innerCitySky;
  }

  String localizedStargazingVerdict(AppLocalizations l10n) {
    if (skyQuality >= 80) return l10n.verdictExcellent;
    if (skyQuality >= 60) return l10n.verdictGood;
    if (skyQuality >= 45) return l10n.verdictDecent;
    if (skyQuality >= 30) return l10n.verdictPoor;
    if (skyQuality >= 15) return l10n.verdictVeryPoor;
    if (isCloudy) return l10n.verdictCloudy;
    return l10n.verdictNotSuitable;
  }
}

/// Localized impact labels for MoonData
extension MoonDataL10n on MoonData {
  String localizedImpact(AppLocalizations l10n) {
    if (illumination < 0.1) return l10n.impactMinimal;
    if (illumination < 0.3) return l10n.impactLow;
    if (illumination < 0.6) return l10n.impactModerate;
    if (illumination < 0.8) return l10n.impactHigh;
    return l10n.impactSevere;
  }

  String localizedImpactDescription(AppLocalizations l10n) {
    if (illumination < 0.1) return l10n.impactDescExcellent;
    if (illumination < 0.3) return l10n.impactDescGood;
    if (illumination < 0.6) return l10n.impactDescSome;
    if (illumination < 0.8) return l10n.impactDescFaint;
    return l10n.impactDescBright;
  }
}

/// Localized brightness labels for PlanetVisibility
extension PlanetVisibilityL10n on PlanetVisibility {
  String localizedBrightnessLabel(AppLocalizations l10n) {
    if (magnitude < -3) return l10n.veryBright;
    if (magnitude < -1) return l10n.brightLabel;
    if (magnitude < 1) return l10n.moderate;
    if (magnitude < 3) return l10n.dim;
    return l10n.faint;
  }
}
