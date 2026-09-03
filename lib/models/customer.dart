class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final DateTime createdAt;
  final String status; // 'quotation', 'invoiced', 'completed'
  final String discountType; // 'flat' (₹) or 'percentage' (%)
  final double discountValue;
  final double advanceAmount;
  final double taxRate; // e.g. 0.0 or 18.0

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.notes = '',
    DateTime? createdAt,
    this.status = 'quotation',
    this.discountType = 'flat',
    this.discountValue = 0.0,
    this.advanceAmount = 0.0,
    this.taxRate = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    DateTime? createdAt,
    String? status,
    String? discountType,
    double? discountValue,
    double? advanceAmount,
    double? taxRate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'discount_type': discountType,
      'discount_value': discountValue,
      'advance_amount': advanceAmount,
      'tax_rate': taxRate,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] as String? ?? 'quotation',
      discountType: map['discount_type'] as String? ?? 'flat',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (map['advance_amount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
