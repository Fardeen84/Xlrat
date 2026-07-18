

class BillingCustomer {
  final String? id;
  final String name;
  final String mobile;
  final String email;
  final String address;
  final DateTime createdAt;

  const BillingCustomer({
    this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    this.address = '',
    required this.createdAt,
  });

  // ── Equality by id ─────────────────────────────────────────────────────────
  // DropdownButton value match ke liye zaroori hai
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BillingCustomer &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ── copyWith ───────────────────────────────────────────────────────────────
  BillingCustomer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? address,
    DateTime? createdAt,
  }) =>
      BillingCustomer(
        id: id ?? this.id,
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );

  // ── DB helpers — apne column names ke hisaab se adjust karo ───────────────
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'mobile': mobile,
    'email': email,
    'address': address,
    'created_at': createdAt.toIso8601String(),
  };

  factory BillingCustomer.fromMap(Map<String, dynamic> map) => BillingCustomer(
    id: map['id']?.toString(),
    name: map['name'] as String? ?? '',
    mobile: map['mobile'] as String? ?? '',
    email: map['email'] as String? ?? '',
    address: map['address'] as String? ?? '',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
        DateTime.now(),
  );

  @override
  String toString() => 'BillingCustomer(id: $id, name: $name, mobile: $mobile)';
}