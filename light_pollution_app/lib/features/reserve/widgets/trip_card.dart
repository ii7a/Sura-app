import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../models/trip_model.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.onTap});

  final StargazingTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('MMM d, yyyy', isArabic ? 'ar' : 'en');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with cover image or gradient + stars
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
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
                  // Bortle class badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Bortle ${trip.bortleClass}',
                            style: font(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Booked badge
                  if (trip.isBooked)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Booked',
                              style: font(
                                color: AppColors.white,
                                fontSize: 12,
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
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: font(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          style: font(color: AppColors.textSub(context), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(trip.date),
                        style: font(color: AppColors.textSub(context), fontSize: 13),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  // Bottom row: Guide + Price
                  Row(
                    children: [
                      // Guide info
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.navy,
                              ),
                              child: trip.guideAvatarUrl != null && trip.guideAvatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: SmartImage(
                                        url: trip.guideAvatarUrl!,
                                        width: 24,
                                        height: 24,
                                        fallback: Center(
                                          child: Text(
                                            trip.guideName.isNotEmpty ? trip.guideName[0] : '?',
                                            style: font(
                                              color: AppColors.white,
                                              fontSize: 11,
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                trip.guideName,
                                overflow: TextOverflow.ellipsis,
                                style: font(
                                  color: AppColors.text(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.star, size: 13, color: Colors.amber[700]),
                            const SizedBox(width: 2),
                            Text(
                              trip.guideRating.toString(),
                              style: font(
                                color: AppColors.textSub(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price + book chip
                      Row(
                        children: [
                          Text(
                            '${trip.price.toInt()} ',
                            style: font(
                              color: AppColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/sar_symbol.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              AppColors.navy,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
    for (int i = 0; i < 50; i++) {
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
    for (int i = 0; i < 4; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % max(1, size.width.toInt())).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % max(1, (size.height * 0.6).toInt())).toDouble();
      paint.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
      paint.color = Colors.white.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), 5.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
