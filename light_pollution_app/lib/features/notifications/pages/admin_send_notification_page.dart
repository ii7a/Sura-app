import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cosmic_event_types.dart';
import '../models/notification_preferences.dart';

/// Admin-only composer for cosmic-event notifications. The route is only
/// exposed in the drawer when [isAdminProvider] is true, but we also
/// re-check on this page so a deep-link won't bypass the gate.
class AdminSendNotificationPage extends ConsumerStatefulWidget {
  const AdminSendNotificationPage({super.key});

  @override
  ConsumerState<AdminSendNotificationPage> createState() =>
      _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState
    extends ConsumerState<AdminSendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  CosmicEventType _type = CosmicEventType.eclipse;
  /// Selected target city id (empty string = broadcast to everyone).
  String _city = '';
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    final admin = await ref.read(currentUserProvider.future);
    if (admin == null) return;

    setState(() => _submitting = true);
    try {
      final count = await ref
          .read(firestoreServiceProvider)
          .broadcastCosmicNotification(
            admin: admin,
            cosmicType: _type.name,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            eventDate: _when,
            city: _city.isEmpty ? null : _city,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminNotifSentCount(count))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminSendNotification)),
        body: Center(
          child: Text(
            l10n.adminOnly,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminSendNotification,
          style: font(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.adminEventType,
              style: font(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CosmicEventType.values.map((t) {
                final selected = t == _type;
                return ChoiceChip(
                  avatar: Icon(t.icon, size: 18, color: t.color),
                  label: Text(_labelFor(l10n, t)),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.adminEventDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _formatDateTime(_when),
                  style: font(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // City dropdown — mirrors the user-facing selector in
            // notification settings so admin and user speak the same
            // vocabulary. Empty string = broadcast to everyone.
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.adminCityOptional,
                helperText: l10n.adminCityHelper,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _city,
                  isExpanded: true,
                  onChanged: (v) => setState(() => _city = v ?? ''),
                  items: SupportedCities.ids
                      .map((id) => DropdownMenuItem(
                            value: id,
                            child: Text(_cityLabel(l10n, id)),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.adminSendBroadcast,
                      style: font(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, CosmicEventType t) {
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

  String _cityLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case '': return l10n.cityAll;
      case 'riyadh': return l10n.cityRiyadh;
      case 'jeddah': return l10n.cityJeddah;
      case 'makkah': return l10n.cityMakkah;
      case 'madinah': return l10n.cityMadinah;
      case 'dammam': return l10n.cityDammam;
      case 'abha': return l10n.cityAbha;
      case 'tabuk': return l10n.cityTabuk;
      case 'taif': return l10n.cityTaif;
      case 'khobar': return l10n.cityKhobar;
      case 'najran': return l10n.cityNajran;
      case 'hail': return l10n.cityHail;
      case 'jazan': return l10n.cityJazan;
    }
    return id;
  }

  String _formatDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day  $hh:$mm';
  }
}
