import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  final String? id;
  final String name;
  final String category;
  final int price;
  final String description;
  final DateTime createdAt;
  final String syncStatus;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ServiceItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    required this.createdAt,
    this.syncStatus = 'pending',
    this.updatedAt,
    this.isDeleted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  ServiceItem copyWith({
    String? id,
    String? name,
    String? category,
    int? price,
    String? description,
    DateTime? createdAt,
    String? syncStatus,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => ServiceItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'name_lower': name.toLowerCase(),
    'category': category,
    'price': price,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'sync_status': syncStatus,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    'is_deleted': isDeleted ? 1 : 0,
  };

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
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

    return ServiceItem(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: map['price'] as int? ?? 0,
      description: map['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      updatedAt: updatedAt,
      isDeleted: parseBool(map['is_deleted'], false),
    );
  }

  @override
  String toString() => 'ServiceItem(id: $id, name: $name, price: $price)';
}
