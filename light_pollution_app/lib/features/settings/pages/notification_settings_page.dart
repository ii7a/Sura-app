import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/cosmic_event_types.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/models/notification_preferences.dart';
import '../../notifications/providers/notifications_provider.dart';

/// Per-user notification settings. Everything lives on a single scrollable
/// page so the user can see and toggle all their preferences at once.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  Future<void> _save(WidgetRef ref, NotificationPreferences prefs) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(firestoreServiceProvider)
        .setNotificationPreferences(uid, prefs);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationSettings,
          style: font(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (prefs) => _SettingsBody(
          prefs: prefs,
          onChanged: (next) => _save(ref, next),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.prefs, required this.onChanged});

  final NotificationPreferences prefs;
  final ValueChanged<NotificationPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    // When the master switch is off we still render the sections but grey
    // them out — matches how iOS Settings behaves for the same pattern.
    final disabled = !prefs.enabled;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SwitchListTile(
          title: Text(
            l10n.notifSettingsEnableAll,
            style: font(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(l10n.notifSettingsEnableAllHelp),
          value: prefs.enabled,
          onChanged: (v) => onChanged(prefs.copyWith(enabled: v)),
        ),
        const Divider(height: 24),
        _SectionHeader(title: l10n.notifSettingsCitySection),
        _CityPicker(
          current: prefs.city,
          disabled: disabled,
          onChanged: (v) => onChanged(prefs.copyWith(city: v)),
        ),
        const Divider(height: 24),
        _SectionHeader(title: l10n.notifSettingsInteractionSection),
        _InteractionToggles(
          prefs: prefs,
          disabled: disabled,
          onChanged: onChanged,
        ),
        const Divider(height: 24),
        _SectionHeader(title: l10n.notifSettingsCosmicSection),
        _CosmicToggles(
          prefs: prefs,
          disabled: disabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.current,
    required this.disabled,
    required this.onChanged,
  });

  final String current;
  final bool disabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      enabled: !disabled,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(l10n.notifSettingsCity),
      trailing: DropdownButton<String>(
        value: current,
        onChanged: disabled ? null : (v) => v == null ? null : onChanged(v),
        items: SupportedCities.ids
            .map((id) => DropdownMenuItem(
                  value: id,
                  child: Text(_cityLabel(l10n, id)),
                ))
            .toList(),
      ),
    );
  }

  String _cityLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case '':
        return l10n.cityAll;
      case 'riyadh':
        return l10n.cityRiyadh;
      case 'jeddah':
        return l10n.cityJeddah;
      case 'makkah':
        return l10n.cityMakkah;
      case 'madinah':
        return l10n.cityMadinah;
      case 'dammam':
        return l10n.cityDammam;
      case 'abha':
        return l10n.cityAbha;
      case 'tabuk':
        return l10n.cityTabuk;
      case 'taif':
        return l10n.cityTaif;
      case 'khobar':
        return l10n.cityKhobar;
      case 'najran':
        return l10n.cityNajran;
      case 'hail':
        return l10n.cityHail;
      case 'jazan':
        return l10n.cityJazan;
    }
    return id;
  }
}

class _InteractionToggles extends StatelessWidget {
  const _InteractionToggles({
    required this.prefs,
    required this.disabled,
    required this.onChanged,
  });

  final NotificationPreferences prefs;
  final bool disabled;
  final ValueChanged<NotificationPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const types = [
      NotificationType.like,
      NotificationType.repost,
      NotificationType.quote,
      NotificationType.comment,
      NotificationType.follow,
    ];
    return Column(
      children: types.map((t) {
        final on = prefs.showsInteraction(t);
        return SwitchListTile(
          title: Text(_label(l10n, t)),
          value: on,
          onChanged: disabled
              ? null
              : (v) {
                  final muted = Set<String>.from(prefs.mutedInteraction);
                  if (v) {
                    muted.remove(t.name);
                  } else {
                    muted.add(t.name);
                  }
                  onChanged(prefs.copyWith(mutedInteraction: muted));
                },
        );
      }).toList(),
    );
  }

  String _label(AppLocalizations l10n, NotificationType t) {
    switch (t) {
      case NotificationType.like:
        return l10n.notifTypeLike;
      case NotificationType.repost:
        return l10n.notifTypeRepost;
      case NotificationType.quote:
        return l10n.notifTypeQuote;
      case NotificationType.comment:
        return l10n.notifTypeComment;
      case NotificationType.follow:
        return l10n.notifTypeFollow;
      case NotificationType.cosmic:
        return '';
    }
  }
}

class _CosmicToggles extends StatelessWidget {
  const _CosmicToggles({
    required this.prefs,
    required this.disabled,
    required this.onChanged,
  });

  final NotificationPreferences prefs;
  final bool disabled;
  final ValueChanged<NotificationPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: CosmicEventType.values.map((t) {
        final on = prefs.showsCosmic(t.name);
        return SwitchListTile(
          secondary: Icon(t.icon, color: t.color),
          title: Text(_label(l10n, t)),
          value: on,
          onChanged: disabled
              ? null
              : (v) {
                  final muted = Set<String>.from(prefs.mutedCosmic);
                  if (v) {
                    muted.remove(t.name);
                  } else {
                    muted.add(t.name);
                  }
                  onChanged(prefs.copyWith(mutedCosmic: muted));
                },
        );
      }).toList(),
    );
  }

  String _label(AppLocalizations l10n, CosmicEventType t) {
    switch (t) {
      case CosmicEventType.eclipse:
        return l10n.cosmicEclipse;
      case CosmicEventType.lunarEclipse:
        return l10n.cosmicLunarEclipse;
      case CosmicEventType.meteorShower:
        return l10n.cosmicMeteorShower;
      case CosmicEventType.planetConjunction:
        return l10n.cosmicPlanetConjunction;
      case CosmicEventType.supermoon:
        return l10n.cosmicSupermoon;
      case CosmicEventType.comet:
        return l10n.cosmicComet;
      case CosmicEventType.issPass:
        return l10n.cosmicIssPass;
      case CosmicEventType.other:
        return l10n.cosmicOther;
    }
  }
}
