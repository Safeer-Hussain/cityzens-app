import 'dart:convert';

class StudyRoomModel {
  final String id;
  final String name;
  final int floor;
  final int capacity;
  final List<String> amenities;
  final bool isAvailable;
  final String photoAsset;

  const StudyRoomModel({
    required this.id,
    required this.name,
    required this.floor,
    required this.capacity,
    required this.amenities,
    required this.isAvailable,
    required this.photoAsset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'floor': floor,
      'capacity': capacity,
      'amenities': jsonEncode(amenities),
      'is_available': isAvailable ? 1 : 0,
      'photo_asset': photoAsset,
    };
  }

  factory StudyRoomModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedAmenities = [];
    final rawAmenities = map['amenities'];
    if (rawAmenities is String) {
      try {
        parsedAmenities = List<String>.from(jsonDecode(rawAmenities) as List);
      } catch (_) {
        parsedAmenities = [];
      }
    } else if (rawAmenities is List) {
      parsedAmenities = List<String>.from(rawAmenities);
    }

    return StudyRoomModel(
      id: map['id'] as String,
      name: map['name'] as String,
      floor: (map['floor'] as num).toInt(),
      capacity: (map['capacity'] as num).toInt(),
      amenities: parsedAmenities,
      isAvailable: (map['is_available'] as num?)?.toInt() == 1,
      photoAsset:
          (map['photo_asset'] as String?) ??
          'assets/images/study_room_default.png',
    );
  }

  StudyRoomModel copyWith({
    String? id,
    String? name,
    int? floor,
    int? capacity,
    List<String>? amenities,
    bool? isAvailable,
    String? photoAsset,
  }) {
    return StudyRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      isAvailable: isAvailable ?? this.isAvailable,
      photoAsset: photoAsset ?? this.photoAsset,
    );
  }
}
