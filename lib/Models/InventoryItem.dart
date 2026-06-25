class InventoryItem {
  final int id;
  final String name;
  final String category;
  final int stock;
  final String unit;
  final int purchase;
  final int selling;
  final int minStock;
  final String sku;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    required this.purchase,
    required this.selling,
    required this.minStock,
    required this.sku,
  });

  bool get isLowStock => stock <= minStock;
}