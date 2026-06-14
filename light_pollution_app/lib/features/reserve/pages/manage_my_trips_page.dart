import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/models/chat_models.dart';
import '../../chat/pages/chat_detail_page.dart';
import '../../community/models/community_models.dart';
import '../models/trip_model.dart';
import '../providers/reserve_provider.dart';

/// Private management page for trip creators: lists only the trips the
/// current user created, and lets them expand each trip to see the people
/// who booked it (name, username, avatar, phone, email, booked-at time, and
/// a "Message" button that opens a direct conversation).
class ManageMyTripsPage extends ConsumerWidget {
  const ManageMyTripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = AppFonts.style(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final tripsAsync = ref.watch(tripsStreamProvider);

    final allTrips = tripsAsync.valueOrNull ?? const <StargazingTrip>[];
    final myTrips = currentUser == null
        ? const <StargazingTrip>[]
        : allTrips.where((t) => t.guideId == currentUser.id).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Created Trips',
          style: font(
            color: AppColors.text(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: currentUser == null
          ? Center(
              child: Text(
                'Sign in to see your trips',
                style: font(color: AppColors.textSub(context), fontSize: 14),
              ),
            )
          : myTrips.isEmpty
              ? _EmptyState(font: font)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: myTrips.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    return _TripManagementCard(trip: myTrips[index]);
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.font});
  final TextStyle Function({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) font;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              "You haven't created any trips yet",
              style: font(
                color: AppColors.textSub(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button in Reserve to publish a trip.',
              textAlign: TextAlign.center,
              style: font(color: AppColors.textHint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// One card per trip — collapsed shows the trip header and a "booked count"
/// pill. Tapping expands the card to load the bookings subcollection and
/// list each registrant inline.
class _TripManagementCard extends StatefulWidget {
  const _TripManagementCard({required this.trip});
  final StargazingTrip trip;

  @override
  State<_TripManagementCard> createState() => _TripManagementCardState();
}

class _TripManagementCardState extends State<_TripManagementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final trip = widget.trip;
    final booked = trip.maxGroupSize - trip.spotsLeft;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: font(
                            color: AppColors.text(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 13, color: AppColors.textSub(context)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                trip.location,
                                overflow: TextOverflow.ellipsis,
                                style: font(
                                  color: AppColors.textSub(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: AppColors.textSub(context)),
                            const SizedBox(width: 3),
                            Text(
                              dateFormat.format(trip.date),
                              style: font(
                                color: AppColors.textSub(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$booked / ${trip.maxGroupSize}',
                      style: font(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSub(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            _BookingsList(tripId: trip.id),
        ],
      ),
    );
  }
}

/// Loads and displays the bookings subcollection for one trip. Uses a
/// StreamBuilder so new bookings appear live.
class _BookingsList extends StatelessWidget {
  const _BookingsList({required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('bookings')
          .orderBy('bookedAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load bookings: ${snap.error}',
              style: font(color: Colors.redAccent, fontSize: 12),
            ),
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              'No registrations yet.',
              style: font(color: AppColors.textSub(context), fontSize: 13),
            ),
          );
        }
        return Column(
          children: [
            const Divider(height: 1, indent: 14, endIndent: 14),
            for (final doc in docs) _BookingRow(bookingData: doc.data()),
          ],
        );
      },
    );
  }
}

class _BookingRow extends ConsumerWidget {
  const _BookingRow({required this.bookingData});
  final Map<String, dynamic> bookingData;

  String _formatBookedAt(dynamic raw) {
    if (raw is Timestamp) {
      return DateFormat('MMM d, h:mm a').format(raw.toDate());
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = AppFonts.style(context);
    final userId = bookingData['userId'] as String? ?? '';
    final name = bookingData['userName'] as String? ?? 'Unknown';
    final username = bookingData['userUsername'] as String? ?? '';
    final avatarUrl = bookingData['userAvatarUrl'] as String?;
    final email = bookingData['userEmail'] as String?;
    final phone = bookingData['userPhone'] as String?;
    final seats = bookingData['seats'] as int? ?? 1;
    final bookedAtText = _formatBookedAt(bookingData['bookedAt']);
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.navy,
                child: avatarUrl != null
                    ? ClipOval(
                        child: SmartImage(
                          url: avatarUrl,
                          width: 44,
                          height: 44,
                          fallback: Text(
                            initials,
                            style: font(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        initials,
                        style: font(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: font(
                              color: AppColors.text(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$seats ${seats == 1 ? 'seat' : 'seats'}',
                            style: font(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (username.isNotEmpty)
                      Text(
                        username,
                        style: font(
                          color: AppColors.textSub(context),
                          fontSize: 12,
                        ),
                      ),
                    if (bookedAtText.isNotEmpty)
                      Text(
                        'Booked $bookedAtText',
                        style: font(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Message',
                icon: Icon(Icons.mail_outline, color: AppColors.navy),
                onPressed: () => _openDM(
                  context,
                  ref,
                  userId: userId,
                  name: name,
                  username: username,
                  avatarUrl: avatarUrl,
                ),
              ),
            ],
          ),
          if ((email != null && email.isNotEmpty) ||
              (phone != null && phone.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(left: 54, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (email != null && email.isNotEmpty)
                    _ContactRow(
                      icon: Icons.email_outlined,
                      value: email,
                      font: font,
                    ),
                  if (phone != null && phone.isNotEmpty)
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      value: phone,
                      font: font,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openDM(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String name,
    required String username,
    String? avatarUrl,
  }) async {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    final firestore = FirestoreService();
    try {
      final convId = await firestore.getOrCreateConversation(me.id, userId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversation: Conversation(
              id: convId,
              otherUser: MockUser(
                id: userId,
                name: name,
                username: username,
                avatarInitials: name.isEmpty
                    ? '?'
                    : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase(),
                bio: '',
                avatarUrl: avatarUrl,
              ),
              messages: const [],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: $e')),
        );
      }
    }
  }
}

/// One row of contact info (email or phone). Tapping copies the value to
/// the clipboard so the trip owner can quickly reach out.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.value,
    required this.font,
  });

  final IconData icon;
  final String value;
  final TextStyle Function({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) font;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSub(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: font(
                  color: AppColors.textSub(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

