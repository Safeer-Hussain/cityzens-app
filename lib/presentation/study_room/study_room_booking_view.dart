import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/study_room.dart';
import '../../data/models/study_room_booking.dart';
import 'study_room_provider.dart';
import 'widgets/study_room_card.dart';
import 'widgets/study_room_booking_sheet.dart';

class StudyRoomBookingView extends StatefulWidget {
  const StudyRoomBookingView({super.key});

  @override
  State<StudyRoomBookingView> createState() => _StudyRoomBookingViewState();
}

class _StudyRoomBookingViewState extends State<StudyRoomBookingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  StudyRoomModel? _selectedRoomForDetail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      provider.loadData().then((_) {
        if (mounted && provider.rooms.isNotEmpty) {
          setState(() => _selectedRoomForDetail = provider.rooms.first);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final provider = Provider.of<StudyRoomProvider>(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
        child: AppBar(
          toolbarHeight: isLandscape ? 36.0 : 48.0,
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: isLandscape ? 18 : 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Peer Study Room Booking Engine',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: isLandscape ? 13 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_study_room_booking',
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Quick Reserve',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          if (provider.filteredRooms.isNotEmpty) {
            StudyRoomBookingSheet.show(context, provider.filteredRooms.first);
          } else {
            AppFeedback.showInfo(
              context,
              'No available rooms found for current filter.',
            );
          }
        },
      ),
      body: isLandscape
          ? _buildLandscapeMasterDetail(context, provider, colors)
          : _buildPortraitLayout(context, provider, colors),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    return Column(
      children: [
        // Top Tab Header
        Container(
          color: colors.surfaceContainer,
          child: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              const Tab(
                text: 'Available Pods',
                icon: Icon(Icons.meeting_room_outlined, size: 18),
              ),
              Tab(
                text: 'My Reservations',
                icon: const Icon(Icons.bookmark_added_outlined, size: 18),
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableRoomsPane(
                context,
                provider,
                colors,
                isMaster: false,
              ),
              _buildMyReservationsPane(context, provider, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeMasterDetail(
    BuildContext context,
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Left Pane: Room List & Filters with Independent ScrollController
        Expanded(
          flex: 5,
          child: _buildAvailableRoomsPane(
            context,
            provider,
            colors,
            isMaster: true,
            scrollController: _leftScrollController,
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: colors.outlineVariant),
        // Right Pane: Detail View or Reservations with Independent ScrollController
        Expanded(
          flex: 4,
          child: Container(
            color: colors.surfaceContainerLow,
            child: SingleChildScrollView(
              controller: _rightScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRightPaneHeader(colors),
                  const SizedBox(height: 10),
                  if (_selectedRoomForDetail != null) ...[
                    _buildSelectedRoomDetailCard(
                      _selectedRoomForDetail!,
                      colors,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildReservationsSummaryCard(provider, colors),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableRoomsPane(
    BuildContext context,
    StudyRoomProvider provider,
    ColorScheme colors, {
    required bool isMaster,
    ScrollController? scrollController,
  }) {
    final filtered = provider.filteredRooms;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Header
          _buildSearchAndFilters(provider, colors),
          const SizedBox(height: 10),

          // Floor Selector Chips
          _buildFloorSelectorChips(provider, colors),
          const SizedBox(height: 8),

          // Capacity Filter Chips
          _buildCapacityFilterChips(provider, colors),
          const SizedBox(height: 12),

          // Room Results Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAMPUS PODS (${filtered.length})',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${provider.availableRooms} Available Now',
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Room Cards
          if (filtered.isEmpty)
            _buildEmptyState(
              'No study rooms match the selected floor or capacity criteria.',
              colors,
            )
          else
            ...filtered.map((room) {
              final isSelected =
                  isMaster && _selectedRoomForDetail?.id == room.id;
              return GestureDetector(
                onTap: isMaster
                    ? () => setState(() => _selectedRoomForDetail = room)
                    : null,
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.primary, width: 2),
                        )
                      : null,
                  child: StudyRoomCard(
                    room: room,
                    onBooked: () {
                      provider.loadData();
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMyReservationsPane(
    BuildContext context,
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    final myBookings = provider.myReservations;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'CONFIRMED SESSIONS (${myBookings.length})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${StudyRoomProvider.currentStudentId}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (myBookings.isEmpty)
            _buildEmptyState(
              'You currently have no active study room reservations.',
              colors,
            )
          else
            ...myBookings.map((b) => _buildBookingCard(b, provider, colors)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: colors.onSurface, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search pod name, whiteboard, 4K display...',
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: colors.onSurfaceVariant,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
      onChanged: (val) => provider.setSearchQuery(val),
    );
  }

  Widget _buildFloorSelectorChips(
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    final floors = [
      {'label': 'All Floors', 'value': null},
      {'label': 'Floor 1 (Innovation)', 'value': 1},
      {'label': 'Floor 2 (Software)', 'value': 2},
      {'label': 'Floor 3 (Architecture)', 'value': 3},
      {'label': 'Floor 4 (Executive)', 'value': 4},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: floors.map((f) {
          final isSelected = provider.selectedFloor == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.setFloor(f['value'] as int?),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCapacityFilterChips(
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    final capacities = [
      {'label': 'All Seats', 'value': null},
      {'label': '4+ Seats', 'value': 4},
      {'label': '6+ Seats', 'value': 6},
      {'label': '8+ Seats', 'value': 8},
      {'label': '10+ Seats', 'value': 10},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: capacities.map((c) {
          final isSelected = provider.minCapacityFilter == c['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                c['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.setCapacityFilter(c['value'] as int?),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingCard(
    StudyRoomBookingModel booking,
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.roomName,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Floor ${booking.floor} • ${booking.formattedDate}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.formattedTimeRange,
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.purpose,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Attendees badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: booking.attendees.map((att) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  att,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Cancellation action
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.error,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 14),
              label: const Text(
                'Cancel Reservation',
                style: TextStyle(fontSize: 11),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel Reservation?'),
                    content: Text(
                      'Are you sure you want to release ${booking.roomName} for ${booking.formattedTimeRange}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Keep'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.error,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Release Pod',
                          style: TextStyle(color: colors.onError),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final cancelled = await provider.cancelBooking(booking.id);
                  if (mounted && cancelled) {
                    AppFeedback.showSuccess(
                      context,
                      'Reservation cancelled. ${booking.roomName} released.',
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPaneHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Master-Detail Room Inspector',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomDetailCard(StudyRoomModel room, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            'Floor ${room.floor} • Capacity: ${room.capacity} Collaborators',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Text(
            'Installed Infrastructure',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: room.amenities.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  a,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text(
              'Open Booking Modal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              StudyRoomBookingSheet.show(context, room);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsSummaryCard(
    StudyRoomProvider provider,
    ColorScheme colors,
  ) {
    final myBookings = provider.myReservations;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Active Sessions (${myBookings.length})',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (myBookings.isEmpty)
            Text(
              'No reservations scheduled.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            )
          else
            ...myBookings.take(3).map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.roomName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      b.formattedTimeRange,
                      style: TextStyle(
                        color: colors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
