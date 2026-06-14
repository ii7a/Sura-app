import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/trip_model.dart';
import '../providers/reserve_provider.dart';

class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final tripsAsync = ref.watch(tripsStreamProvider);
    final trips = tripsAsync.valueOrNull ?? [];
    if (trips.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final trip = trips.firstWhere((t) => t.id == tripId, orElse: () => trips.first);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('EEEE, MMM d, yyyy', isArabic ? 'ar' : 'en');

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Header image
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: AppColors.navy,
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  actions: [
                    // Edit/delete is available to the trip's own creator and
                    // to admins. Premium users who published their own trip
                    // should be able to manage it; admins can moderate any
                    // trip as before.
                    if ((currentUser?.hasFullAccess ?? false) ||
                        (currentUser != null && trip.guideId == currentUser.id)) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.white),
                        onPressed: () => _showEditTripSheet(context, ref, trip),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteTrip(context, ref, trip),
                      ),
                    ],
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty)
                          Image.network(
                            trip.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: trip.gradientColors,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: trip.gradientColors,
                              ),
                            ),
                          ),
                          CustomPaint(painter: _StarsPainter(trip.id.hashCode)),
                        ],
                        // Bottom gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bortle badge
                        Positioned(
                          top: 100,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Bortle ${trip.bortleClass}',
                                  style: font(
                                    color: AppColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          trip.title,
                          style: font(
                            color: AppColors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Location
                        _InfoRow(
                          icon: Icons.location_on,
                          text: trip.location,
                          font: font,
                        ),
                        const SizedBox(height: 8),
                        // Date
                        _InfoRow(
                          icon: Icons.calendar_today,
                          text: dateFormat.format(trip.date),
                          font: font,
                        ),
                        const SizedBox(height: 8),
                        // Duration
                        _InfoRow(
                          icon: Icons.schedule,
                          text: l10n.durationHours(trip.durationHours),
                          font: font,
                        ),
                        const SizedBox(height: 20),
                        // Guide info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.navy,
                                ),
                                child: trip.guideAvatarUrl != null && trip.guideAvatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: SmartImage(
                                          url: trip.guideAvatarUrl!,
                                          width: 40,
                                          height: 40,
                                          fallback: Center(
                                            child: Text(
                                              trip.guideName.isNotEmpty ? trip.guideName[0] : '?',
                                              style: font(
                                                color: AppColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          trip.guideName.isNotEmpty ? trip.guideName[0] : '?',
                                          style: font(
                                            color: AppColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.guidedBy,
                                      style: font(
                                        color: AppColors.textSub(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      trip.guideName,
                                      style: font(
                                        color: AppColors.text(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.star, size: 16, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text(
                                trip.guideRating.toString(),
                                style: font(
                                  color: AppColors.text(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // About this trip
                        Text(
                          l10n.aboutTrip,
                          style: font(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trip.description,
                          style: font(
                            color: AppColors.text(context),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // What's included
                        Text(
                          l10n.whatsIncluded,
                          style: font(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...trip.included.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 18, color: AppColors.navy),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: font(
                                        color: AppColors.text(context),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                        // Stats row
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.star,
                              label: l10n.bortleClassLabel,
                              value: trip.bortleClass.toString(),
                              font: font,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              icon: Icons.group,
                              label: l10n.groupSize,
                              value: trip.maxGroupSize.toString(),
                              font: font,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              icon: Icons.event_seat,
                              label: l10n.spotsLeftLabel,
                              value: trip.spotsLeft.toString(),
                              font: font,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom booking bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${trip.price.toInt()} ',
                          style: font(
                            color: AppColors.navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/sar_symbol.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            AppColors.navy,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.perPerson,
                      style: font(
                        color: AppColors.textSub(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Builder(
                      builder: (_) {
                        final isHost = currentUser != null &&
                            trip.guideId.isNotEmpty &&
                            currentUser.id == trip.guideId;
                        final disabled = trip.isBooked || isHost;
                        return FilledButton(
                          onPressed: disabled
                              ? null
                              : () => _showBookingConfirmation(
                                  context, ref, trip, l10n, font),
                          style: FilledButton.styleFrom(
                            backgroundColor: trip.isBooked
                                ? Colors.green
                                : AppColors.navy,
                            disabledBackgroundColor:
                                trip.isBooked ? Colors.green : Colors.grey,
                            disabledForegroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            trip.isBooked
                                ? l10n.tripBooked
                                : (isHost ? l10n.youAreTheHost : l10n.bookNow),
                            style: font(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
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

  void _confirmDeleteTrip(BuildContext context, WidgetRef ref, StargazingTrip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${trip.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await deleteTripFromFirestore(trip.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip deleted'), backgroundColor: AppColors.navy),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTripSheet(BuildContext context, WidgetRef ref, StargazingTrip trip) {
    final titleController = TextEditingController(text: trip.title);
    final descController = TextEditingController(text: trip.description);
    final priceController = TextEditingController(text: trip.price.toInt().toString());
    final locationController = TextEditingController(text: trip.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (SAR)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  onPressed: () async {
                    try {
                      await updateTripInFirestore(trip.id, {
                        'title': titleController.text.trim(),
                        'location': locationController.text.trim(),
                        'price': double.tryParse(priceController.text.trim()) ?? trip.price,
                        'description': descController.text.trim(),
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip updated'), backgroundColor: AppColors.navy),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingConfirmation(
    BuildContext context,
    WidgetRef ref,
    StargazingTrip trip,
    AppLocalizations l10n,
    dynamic font,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BookingSheet(trip: trip),
    );
  }
}

/// Stateful bottom sheet for confirming a trip booking. Collects the seat
/// count (1–5, capped by spotsLeft), email (pre-filled with the user's
/// sign-in email, editable), and phone (pre-filled from the user's profile,
/// editable). Calls [bookTripInFirestore] on confirm.
class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.trip});
  final StargazingTrip trip;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  static const _maxSeatsPerBooking = 5;
  int _seats = 1;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _busy = false;
  bool _prefillDone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefillFromUser() {
    if (_prefillDone) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    _emailController.text =
        user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _prefillDone = true;
  }

  int get _maxSeats {
    final remaining = widget.trip.spotsLeft;
    final cap = remaining < _maxSeatsPerBooking ? remaining : _maxSeatsPerBooking;
    return cap < 1 ? 1 : cap;
  }

  Future<void> _confirm(AppLocalizations l10n) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;
    setState(() => _busy = true);
    try {
      await bookTripInFirestore(
        widget.trip.id,
        userId: currentUser.id,
        userName: currentUser.name,
        userUsername: currentUser.username,
        userAvatarUrl: currentUser.avatarUrl,
        userEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        userPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        seats: _seats,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tripBookedMsg),
          backgroundColor: AppColors.navy,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromUser();
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final max = _maxSeats;
    if (_seats > max) _seats = max;
    final total = widget.trip.price * _seats;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.bookNow,
                  style: font(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.trip.title,
                  textAlign: TextAlign.center,
                  style: font(color: AppColors.text(context), fontSize: 15),
                ),
              ),
              const SizedBox(height: 20),

              // Seat counter
              Text(
                'Seats',
                style: font(
                  color: AppColors.textSub(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove,
                    enabled: _seats > 1 && !_busy,
                    onTap: () => setState(() => _seats--),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_seats',
                        style: font(
                          color: AppColors.text(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add,
                    enabled: _seats < max && !_busy,
                    onTap: () => setState(() => _seats++),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Max $max per booking',
                style: font(color: AppColors.textHint, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // Email field
              Text(
                'Email',
                style: font(
                  color: AppColors.textSub(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_busy,
                style: font(color: AppColors.text(context), fontSize: 14),
                decoration: _inputDecoration(hint: 'you@example.com'),
              ),
              const SizedBox(height: 14),

              // Phone field
              Text(
                'Phone',
                style: font(
                  color: AppColors.textSub(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_busy,
                style: font(color: AppColors.text(context), fontSize: 14),
                decoration: _inputDecoration(hint: '+966 …'),
              ),
              const SizedBox(height: 20),

              // Price summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: font(
                      color: AppColors.textSub(context),
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${total.toInt()} ',
                        style: font(
                          color: AppColors.text(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/sar_symbol.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          AppColors.navy,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _busy ? null : () => _confirm(l10n),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Confirm Booking',
                          style: font(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  l10n.cancel,
                  style: font(color: AppColors.textSub(context), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: enabled ? AppColors.navy : AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.font,
  });

  final IconData icon;
  final String text;
  final TextStyle Function({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) font;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: font(color: AppColors.textSub(context), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.font,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle Function({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) font;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.navy),
            const SizedBox(height: 4),
            Text(
              value,
              style: font(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: font(
                color: AppColors.textSub(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    var hash = seed;
    for (int i = 0; i < 60; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % max(1, size.width.toInt())).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % max(1, size.height.toInt())).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final brightness = 0.3 + (hash % 70) / 100.0;
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final radius = 0.5 + (hash % 20) / 15.0;
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    for (int i = 0; i < 6; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % max(1, size.width.toInt())).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % max(1, (size.height * 0.7).toInt())).toDouble();
      paint.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
      paint.color = Colors.white.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), 6.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
