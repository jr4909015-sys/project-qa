class LaboratoryModel {
  const LaboratoryModel({
    required this.id,
    required this.name,
    required this.building,
    required this.roomNumber,
    this.capacity = 1,
    this.facilities = const [],
    this.description = '',
    this.openingTime,
    this.closingTime,
  });

  final int id;
  final String name;
  final String building;
  final String roomNumber;
  final int capacity;
  final List<String> facilities;
  final String description;
  final String? openingTime;
  final String? closingTime;

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) => LaboratoryModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        building: json['building'] as String? ?? '',
        roomNumber: json['room_number'] as String? ?? '',
        capacity: json['capacity'] as int? ?? 1,
        facilities: (json['facilities'] as List<dynamic>? ?? []).cast<String>(),
        description: json['description'] as String? ?? '',
        openingTime: json['opening_time'] as String?,
        closingTime: json['closing_time'] as String?,
      );
}