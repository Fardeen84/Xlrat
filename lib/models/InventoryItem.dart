class InventoryItem {
  final int? id;
  final String name;
  final String category;
  final int stock;
  final String unit;
  final int purchase;
  final int selling;
  final int minStock;
  final String sku;
  final DateTime createdAt;

  const InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    required this.purchase,
    required this.selling,
    required this.minStock,
    required this.sku,
    required this.createdAt,
  });

  bool get isLowStock => stock <= minStock;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  InventoryItem copyWith({
    int? id,
    String? name,
    String? category,
    int? stock,
    String? unit,
    int? purchase,
    int? selling,
    int? minStock,
    String? sku,
    DateTime? createdAt,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        stock: stock ?? this.stock,
        unit: unit ?? this.unit,
        purchase: purchase ?? this.purchase,
        selling: selling ?? this.selling,
        minStock: minStock ?? this.minStock,
        sku: sku ?? this.sku,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'stock': stock,
    'unit': unit,
    'purchase': purchase,
    'selling': selling,
    'min_stock': minStock,
    'sku': sku,
    'created_at': createdAt.toIso8601String(),
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
    id: map['id'] as int?,
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? '',
    stock: map['stock'] as int? ?? 0,
    unit: map['unit'] as String? ?? 'pcs',
    purchase: map['purchase'] as int? ?? 0,
    selling: map['selling'] as int? ?? 0,
    minStock: map['min_stock'] as int? ?? 0,
    sku: map['sku'] as String? ?? '',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  @override
  String toString() => 'InventoryItem(id: $id, name: $name, stock: $stock)';
}