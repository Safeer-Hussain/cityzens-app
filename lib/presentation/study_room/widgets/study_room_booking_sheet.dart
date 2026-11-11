import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/study_room.dart';
import '../study_room_provider.dart';

class StudyRoomBookingSheet extends StatefulWidget {
  final StudyRoomModel room;

  const StudyRoomBookingSheet({super.key, required this.room});

  static Future<bool?> show(BuildContext context, StudyRoomModel room) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StudyRoomBookingSheet(room: room),
    );
  }

  @override
  State<StudyRoomBookingSheet> createState() => _StudyRoomBookingSheetState();
}

class _StudyRoomBookingSheetState extends State<StudyRoomBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _attendeeController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  int _durationMinutes = 60;
  final List<String> _attendees = ['safeer@cityzens.edu'];

  bool _isCheckingCollision = false;
  bool _hasCollision = false;
  Timer? _collisionDebounce;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Next rounded half-hour
    final nextMin = (now.minute < 30) ? 30 : 0;
    final nextHour = (now.minute < 30) ? now.hour : (now.hour + 1) % 24;
    _startTime = TimeOfDay(hour: nextHour, minute: nextMin);

    _runCollisionCheck();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _attendeeController.dispose();
    _collisionDebounce?.cancel();
    super.dispose();
  }

  DateTime get _startDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime get _endDateTime {
    return _startDateTime.add(Duration(minutes: _durationMinutes));
  }

  void _runCollisionCheck() {
    _collisionDebounce?.cancel();
    _collisionDebounce = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      setState(() => _isCheckingCollision = true);

      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      final collision = await provider.checkCollision(
        roomId: widget.room.id,
        startTime: _startDateTime,
        endTime: _endDateTime,
      );

      if (mounted) {
        setState(() {
          _hasCollision = collision;
          _isCheckingCollision = false;
        });
      }
    });
  }

  void _addAttendee() {
    final text = _attendeeController.text.trim();
    if (text.isEmpty) return;

    if (_attendees.length >= widget.room.capacity) {
      AppFeedback.showWarning(
        context,
        'Cannot exceed maximum room capacity (${widget.room.capacity} seats).',
      );
      return;
    }

    if (_attendees.contains(text)) {
      AppFeedback.showInfo(context, 'Attendee already added to session.');
      return;
    }

    setState(() {
      _attendees.add(text);
      _attendeeController.clear();
    });
  }

  void _removeAttendee(String attendee) {
    if (_attendees.length <= 1) {
      AppFeedback.showInfo(
        context,
        'Primary reservation organizer must remain.',
      );
      return;
    }
    setState(() {
      _attendees.remove(attendee);
    });
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasCollision) {
      AppFeedback.showError(
        context,
        'Slot unavailable: Another group has reserved this room during the selected timeframe.',
      );
      return;
    }

    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final success = await provider.bookRoom(
      roomId: widget.room.id,
      purpose: _purposeController.text.trim(),
      startTime: _startDateTime,
      endTime: _endDateTime,
      attendees: _attendees,
    );

    if (mounted) {
      if (success) {
        AppFeedback.showSuccess(
          context,
          'Reserved ${widget.room.name} (${_startDateTime.hour.toString().padLeft(2, '0')}:${_startDateTime.minute.toString().padLeft(2, '0')} - ${_endDateTime.hour.toString().padLeft(2, '0')}:${_endDateTime.minute.toString().padLeft(2, '0')}).',
        );
        Navigator.of(context).pop(true);
      } else {
        AppFeedback.showError(
          context,
          provider.errorMessage ?? 'Failed to reserve study room.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.name,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Floor ${widget.room.floor} • Maximum ${widget.room.capacity} Collaborators',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Collision Radar Indicator Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _hasCollision
                        ? colors.errorContainer
                        : colors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _hasCollision
                          ? colors.error
                          : colors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasCollision
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: _hasCollision ? colors.error : colors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isCheckingCollision
                              ? 'Scanning schedule collision radar...'
                              : _hasCollision
                              ? 'Collision Detected: Slot is occupied by another session.'
                              : 'Slot Free: Room is completely available for booking.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _hasCollision
                                ? colors.onErrorContainer
                                : colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Purpose Input
                TextFormField(
                  controller: _purposeController,
                  style: TextStyle(color: colors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Study Purpose / Agenda',
                    hintText: 'e.g. Distributed Consensus Benchmark Sprint',
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 4) {
                      return 'Please describe the academic session (min 4 characters).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Time Slot Pickers
                Row(
                  children: [
                    // Start Time Picker
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (picked != null) {
                            setState(() => _startTime = picked);
                            _runCollisionCheck();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.outlineVariant),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // End Time Calculated Preview
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time (Projected)',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_endDateTime.hour.toString().padLeft(2, '0')}:${_endDateTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration Selector Chips
                Text(
                  'Reservation Duration',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [30, 60, 90, 120].map((dur) {
                    final isSel = _durationMinutes == dur;
                    return ChoiceChip(
                      label: Text('$dur Min'),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _durationMinutes = dur);
                          _runCollisionCheck();
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Attendee Tag Input Row
                Text(
                  'Invited Collaborators (${_attendees.length}/${widget.room.capacity})',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _attendeeController,
                        style: TextStyle(color: colors.onSurface, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'student@cityzens.edu',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _addAttendee(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _addAttendee,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Attendee Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _attendees.map((att) {
                    return Chip(
                      label: Text(att, style: const TextStyle(fontSize: 10)),
                      onDeleted: () => _removeAttendee(att),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colors.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasCollision
                              ? colors.error
                              : colors.primary,
                          foregroundColor: _hasCollision
                              ? colors.onError
                              : colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _hasCollision
                              ? 'Slot Occupied'
                              : 'Confirm Reservation',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: _hasCollision ? null : _submitReservation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
