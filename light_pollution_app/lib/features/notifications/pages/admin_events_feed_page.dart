import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cosmic_event.dart';
import '../models/cosmic_event_types.dart';
import '../services/nasa_events_service.dart';

/// Admin-only feed of upcoming cosmic events. Merges NASA's live feeds
/// with our static 2026+ dataset and lets the admin push any row to
/// all users as a notification with one tap.
class AdminEventsFeedPage extends ConsumerStatefulWidget {
  const AdminEventsFeedPage({super.key});

  @override
  ConsumerState<AdminEventsFeedPage> createState() => _AdminEventsFeedPageState();
}

class _AdminEventsFeedPageState extends ConsumerState<AdminEventsFeedPage> {
  late Future<List<CosmicEvent>> _future;
  final _service = NasaEventsService();
  // Remember which event rows are currently broadcasting so the UI can show
  // a spinner per-row instead of a single global one.
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.fetchAll());
    await _future;
  }

  Future<void> _sendEvent(CosmicEvent e) async {
    final l10n = AppLocalizations.of(context)!;
    final admin = await ref.read(currentUserProvider.future);
    if (admin == null) return;

    setState(() => _sending.add(e.sourceId));
    try {
      final count = await ref
          .read(firestoreServiceProvider)
          .broadcastCosmicNotification(
            admin: admin,
            cosmicType: e.type.name,
            // Always store both languages so recipients see the event in
            // their own locale, regardless of what the admin's app is set to.
            title: e.titleAr,
            description: e.descriptionAr,
            titleEn: e.titleEn,
            descriptionEn: e.descriptionEn,
            eventDate: e.date,
            imageUrl: e.imageUrl,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminNotifSentCount(count))),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending.remove(e.sourceId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminUpcomingEvents)),
        body: Center(child: Text(l10n.adminOnly)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminUpcomingEvents,
          style: font(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<CosmicEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}'),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.adminNoUpcomingEvents,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.div(context)),
              itemBuilder: (_, i) {
                final e = items[i];
                final sending = _sending.contains(e.sourceId);
                return _EventRow(
                  event: e,
                  sending: sending,
                  onSend: () => _sendEvent(e),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.sending,
    required this.onSend,
  });

  final CosmicEvent event;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Show the row in the admin's current locale (pure preview — the
    // broadcast still carries both languages).
    final locale = Localizations.localeOf(context).languageCode;
    final title = event.title(locale);
    final description = event.description(locale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: event.type.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(event.type.icon, color: event.type.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(event.date),
                  style: TextStyle(
                    color: event.type.color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: sending ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 14),
                    label: Text(l10n.adminSendBroadcast),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$year/$month/$day  $hh:$mm';
  }
}
