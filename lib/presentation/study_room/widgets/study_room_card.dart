import 'package:flutter/material.dart';

import '../../../data/models/study_room.dart';
import 'study_room_booking_sheet.dart';

class StudyRoomCard extends StatelessWidget {
  final StudyRoomModel room;
  final VoidCallback? onBooked;

  const StudyRoomCard({super.key, required this.room, this.onBooked});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Title & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.meeting_room_rounded,
                  size: 22,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Floor ${room.floor}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 12,
                                color: colors.secondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${room.capacity} Seats',
                                style: TextStyle(
                                  color: colors.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: room.isAvailable
                      ? colors.secondaryContainer.withValues(alpha: 0.5)
                      : colors.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: room.isAvailable
                            ? colors.secondary
                            : colors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      room.isAvailable ? 'Available' : 'In Session',
                      style: TextStyle(
                        color: room.isAvailable
                            ? colors.secondary
                            : colors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amenities Wrap
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: room.amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAmenityIcon(amenity),
                      size: 11,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        amenity,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 14),
              label: const Text(
                'Reserve Pod',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                final booked = await StudyRoomBookingSheet.show(context, room);
                if (booked == true && onBooked != null) {
                  onBooked!();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('display') ||
        lower.contains('monitor') ||
        lower.contains('screen')) {
      return Icons.tv_rounded;
    }
    if (lower.contains('whiteboard')) {
      return Icons.draw_outlined;
    }
    if (lower.contains('conference') || lower.contains('polycom')) {
      return Icons.video_call_outlined;
    }
    if (lower.contains('charging') || lower.contains('power')) {
      return Icons.bolt_outlined;
    }
    if (lower.contains('chair') || lower.contains('reclin')) {
      return Icons.chair_outlined;
    }
    if (lower.contains('ethernet') || lower.contains('workstation')) {
      return Icons.lan_outlined;
    }
    if (lower.contains('view') || lower.contains('soundproof')) {
      return Icons.volume_off_outlined;
    }
    return Icons.check_circle_outline;
  }
}
