// lib/billing/models/invoice_item.dart

/// A single line item on an invoice.
///
/// [productId] is intentionally nullable: when null the item is a manual
/// free-text entry. Once the Inventory module is built, a productId can
/// point to the inventory product without any DB migration (column already
/// exists in the schema).
class InvoiceItem {
  final String? id;
  final String? invoiceId; // null while drafting, set after invoice is saved
  final String? productId; // null → manual item; non-null → inventory product
  final String itemName;
  final double quantity;
  final String unit;
  final double price;
  final double total; // quantity × price  (always computed, stored for speed)
  final DateTime createdAt;
  final String productSource; // 'inventory' or 'secondhand'

  const InvoiceItem({
    this.id,
    this.invoiceId,
    this.productId,
    required this.itemName,
    required this.quantity,
    this.unit = 'pcs',
    required this.price,
    required this.total,
    required this.createdAt,
    this.productSource = 'inventory',
  });

  /// Convenience factory for UI — computes [total] automatically.
  factory InvoiceItem.create({
    String? id,
    String? invoiceId,
    String? productId,
    required String itemName,
    required double quantity,
    String unit = 'pcs',
    required double price,
    DateTime? createdAt,
    String productSource = 'inventory',
  }) {
    return InvoiceItem(
      id: id,
      invoiceId: invoiceId,
      productId: productId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      price: price,
      total: quantity * price,
      createdAt: createdAt ?? DateTime.now(),
      productSource: productSource,
    );
  }

  // ─── DB Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    if (invoiceId != null) 'invoice_id': invoiceId,
    'product_id': productId, // null is valid SQL
    'item_name': itemName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'total': total,
    'created_at': createdAt.toIso8601String(),
    'product_source': productSource,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    id: map['id']?.toString(),
    invoiceId: map['invoice_id']?.toString(),
    productId: map['product_id']?.toString(),
    itemName: map['item_name'] as String,
    quantity: (map['quantity'] as num).toDouble(),
    unit: (map['unit'] as String?) ?? 'pcs',
    price: (map['price'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
    productSource: map['product_source'] as String? ?? 'inventory',
  );

  // ─── CopyWith ─────────────────────────────────────────────────────────────

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? itemName,
    double? quantity,
    String? unit,
    double? price,
    double? total,
    DateTime? createdAt,
    String? productSource,
  }) {
    final newQty = quantity ?? this.quantity;
    final newPrice = price ?? this.price;
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      quantity: newQty,
      unit: unit ?? this.unit,
      price: newPrice,
      total: total ?? (newQty * newPrice),
      createdAt: createdAt ?? this.createdAt,
      productSource: productSource ?? this.productSource,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is InvoiceItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
