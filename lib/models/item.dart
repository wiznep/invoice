/// Item model for reusable products/services
class Item {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String unit; // e.g., "hour", "piece", "day"
  final double taxRate; // percentage, e.g., 13.0 for 13%
  final DateTime createdAt;

  Item({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.unit = 'unit',
    this.taxRate = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'taxRate': taxRate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'unit',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    double? taxRate,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Item(id: $id, name: $name, price: $price)';
}
