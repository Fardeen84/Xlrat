import 'package:cloud_firestore/cloud_firestore.dart';

class SecondHandItem {
  final String? id;
  final String name;
  final String category;
  final int stock;
  final String unit;
  final int purchase;
  final int selling;
  final int minStock;
  final String sku;
  final String sourceNotes;
  final String conditionNotes;
  final DateTime createdAt;
  final String syncStatus;
  final DateTime? updatedAt;
  final bool isDeleted;

  const SecondHandItem({
    this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.unit,
    required this.purchase,
    required this.selling,
    required this.minStock,
    required this.sku,
    this.sourceNotes = '',
    this.conditionNotes = '',
    required this.createdAt,
    this.syncStatus = 'pending',
    this.updatedAt,
    this.isDeleted = false,
  });

  bool get isLowStock => stock <= minStock;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecondHandItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  SecondHandItem copyWith({
    String? id,
    String? name,
    String? category,
    int? stock,
    String? unit,
    int? purchase,
    int? selling,
    int? minStock,
    String? sku,
    String? sourceNotes,
    String? conditionNotes,
    DateTime? createdAt,
    String? syncStatus,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => SecondHandItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    stock: stock ?? this.stock,
    unit: unit ?? this.unit,
    purchase: purchase ?? this.purchase,
    selling: selling ?? this.selling,
    minStock: minStock ?? this.minStock,
    sku: sku ?? this.sku,
    sourceNotes: sourceNotes ?? this.sourceNotes,
    conditionNotes: conditionNotes ?? this.conditionNotes,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
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
    'source_notes': sourceNotes,
    'condition_notes': conditionNotes,
    'created_at': createdAt.toIso8601String(),
    'sync_status': syncStatus,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    'is_deleted': isDeleted ? 1 : 0,
    'isLowStock': isLowStock,
  };

  factory SecondHandItem.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      if (val is int) return val != 0;
      return def;
    }

    DateTime? updatedAt;
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
      } else if (map['updatedAt'] is String) {
        updatedAt = DateTime.tryParse(map['updatedAt'] as String);
      } else if (map['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int);
      }
    } else if (map['updated_at'] != null) {
      if (map['updated_at'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int);
      } else if (map['updated_at'] is String) {
        updatedAt = DateTime.tryParse(map['updated_at'] as String);
      }
    }

    return SecondHandItem(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      stock: map['stock'] as int? ?? 0,
      unit: map['unit'] as String? ?? 'pcs',
      purchase: map['purchase'] as int? ?? 0,
      selling: map['selling'] as int? ?? 0,
      minStock: map['min_stock'] as int? ?? 0,
      sku: map['sku'] as String? ?? '',
      sourceNotes: map['source_notes'] as String? ?? '',
      conditionNotes: map['condition_notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      updatedAt: updatedAt,
      isDeleted: parseBool(map['is_deleted'], false),
    );
  }

  @override
  String toString() => 'SecondHandItem(id: $id, name: $name, stock: $stock)';
}
