
class BillingCustomer {
  final int? id; // null before first save
  final String name;
  final String mobile;
  final String email;
  final String address;
  final String gstNumber;
  final DateTime createdAt;

  const BillingCustomer({
    this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    this.address = '',
    this.gstNumber = '',
    required this.createdAt,
  });

  // ─── DB Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'mobile': mobile,
    'email': email,
    'address': address,
    'gst_number': gstNumber,
    'created_at': createdAt.toIso8601String(),
  };

  factory BillingCustomer.fromMap(Map<String, dynamic> map) => BillingCustomer(
    id: map['id'] as int?,
    name: map['name'] as String,
    mobile: map['mobile'] as String,
    email: (map['email'] as String?) ?? '',
    address: (map['address'] as String?) ?? '',
    gstNumber: (map['gst_number'] as String?) ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  // ─── CopyWith ─────────────────────────────────────────────────────────────

  BillingCustomer copyWith({
    int? id,
    String? name,
    String? mobile,
    String? email,
    String? address,
    String? gstNumber,
    DateTime? createdAt,
  }) =>
      BillingCustomer(
        id: id ?? this.id,
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        address: address ?? this.address,
        gstNumber: gstNumber ?? this.gstNumber,
        createdAt: createdAt ?? this.createdAt,
      );

  // ─── Display helpers ──────────────────────────────────────────────────────

  /// Two-letter initials for avatar widgets.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  @override
  String toString() => 'BillingCustomer(id: $id, name: $name, mobile: $mobile)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BillingCustomer && other.id == id && other.mobile == mobile;

  @override
  int get hashCode => Object.hash(id, mobile);
}
