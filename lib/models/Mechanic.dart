class Mechanic {
  final String? id;
  final String name;
  final String initials;
  final String phone;
  final String specialization;
  final bool isActive;
  final DateTime createdAt;
  final String syncStatus;
  final int updatedAt;
  final bool isDeleted;

  const Mechanic({
    this.id,
    required this.name,
    this.initials = '',
    this.phone = '',
    this.specialization = '',
    this.isActive = true,
    required this.createdAt,
    this.syncStatus = 'pending',
    this.updatedAt = 0,
    this.isDeleted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mechanic &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Mechanic copyWith({
    String? id,
    String? name,
    String? initials,
    String? phone,
    String? specialization,
    bool? isActive,
    DateTime? createdAt,
    String? syncStatus,
    int? updatedAt,
    bool? isDeleted,
  }) {
    return Mechanic(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'initials': initials,
        'phone': phone,
        'specialization': specialization,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'sync_status': syncStatus,
        'updated_at': updatedAt,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Mechanic.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      if (val is int) return val != 0;
      return def;
    }

    return Mechanic(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      initials: map['initials'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      specialization: map['specialization'] as String? ?? '',
      isActive: parseBool(map['is_active'], true),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      updatedAt: map['updated_at'] as int? ?? 0,
      isDeleted: parseBool(map['is_deleted'], false),
    );
  }

  @override
  String toString() => 'Mechanic(id: $id, name: $name, phone: $phone)';
}
