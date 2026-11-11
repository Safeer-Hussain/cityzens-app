import 'package:flutter/foundation.dart';

import '../../data/models/study_room.dart';
import '../../data/models/study_room_booking.dart';
import '../../data/repositories/study_room_repository.dart';

class StudyRoomProvider extends ChangeNotifier {
  final StudyRoomRepository repository;

  static const String currentStudentId = 'CTZ-2026-8842';
  static const String currentStudentName = 'Safeer Hussain';

  bool _isLoading = false;
  List<StudyRoomModel> _rooms = [];
  List<StudyRoomBookingModel> _bookings = [];
  int? _selectedFloor;
  int? _minCapacityFilter;
  String _searchQuery = '';
  String? _errorMessage;

  StudyRoomProvider({required this.repository});

  bool get isLoading => _isLoading;
  List<StudyRoomModel> get rooms => _rooms;
  List<StudyRoomBookingModel> get bookings => _bookings;
  int? get selectedFloor => _selectedFloor;
  int? get minCapacityFilter => _minCapacityFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  int get totalRooms => _rooms.length;
  int get availableRooms => _rooms.where((r) => r.isAvailable).length;

  List<StudyRoomModel> get filteredRooms {
    return _rooms.where((room) {
      if (_selectedFloor != null && room.floor != _selectedFloor) {
        return false;
      }
      if (_minCapacityFilter != null && room.capacity < _minCapacityFilter!) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchName = room.name.toLowerCase().contains(query);
        final matchAmenities = room.amenities.any(
          (a) => a.toLowerCase().contains(query),
        );
        if (!matchName && !matchAmenities) return false;
      }
      return true;
    }).toList();
  }

  List<StudyRoomBookingModel> get myReservations {
    return _bookings
        .where((b) => b.bookedById == currentStudentId && b.isConfirmed)
        .toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await repository.getRooms();
      _bookings = await repository.getBookings();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFloor(int? floor) {
    if (_selectedFloor == floor) return;
    _selectedFloor = floor;
    notifyListeners();
  }

  void setCapacityFilter(int? minCapacity) {
    if (_minCapacityFilter == minCapacity) return;
    _minCapacityFilter = minCapacity;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> checkCollision({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    return repository.checkTimeSlotCollision(
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
      excludeBookingId: excludeBookingId,
    );
  }

  Future<bool> bookRoom({
    required String roomId,
    required String purpose,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> attendees,
  }) async {
    _errorMessage = null;

    try {
      final newBooking = await repository.createBooking(
        roomId: roomId,
        bookedById: currentStudentId,
        bookedByName: currentStudentName,
        purpose: purpose,
        startTime: startTime,
        endTime: endTime,
        attendees: attendees,
      );

      _bookings.insert(0, newBooking);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _errorMessage = null;

    try {
      final success = await repository.cancelBooking(bookingId);
      if (success) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = _bookings[index].copyWith(status: 'cancelled');
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
