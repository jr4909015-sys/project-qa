class EquipmentModel {
  const EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.assetTag,
    this.location = '',
    this.quantity = 1,
    this.availableQuantity,
    this.condition = 'good',
    this.description = '',
    this.image,
  });

  final int id;
  final String name;
  final String category;
  final String assetTag;
  final String location;
  final int quantity;
  final int? availableQuantity;
  final String condition;
  final String description;
  final String? image;

  factory EquipmentModel.fromJson(Map<String, dynamic> json) => EquipmentModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        assetTag: json['asset_tag'] as String? ?? '',
        location: json['location'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        availableQuantity: json['available_quantity'] as int?,
        condition: json['condition'] as String? ?? 'good',
        description: json['description'] as String? ?? '',
        image: json['image'] as String?,
      );
}