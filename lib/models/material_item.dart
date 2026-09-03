class MaterialItem {
  final int? id;
  final int? customerId; // null = master catalog template; non-null = customer specific
  final String name;
  final String category; // 'Channel', 'Glass', 'Hardware', 'Labor', 'Accessories'
  final String unit; // 'Sq. Ft', 'Per Window', 'Fixed', 'R. Ft'
  final double unitPrice;
  final String calculationType; // 'per_sq_ft', 'per_window', 'fixed'
  final double multiplier; // e.g. 1.0
  final double manualQuantity; // for fixed or overridden quantity
  final bool isEnabled;

  MaterialItem({
    this.id,
    this.customerId,
    required this.name,
    this.category = 'Channel',
    this.unit = 'Sq. Ft',
    required this.unitPrice,
    this.calculationType = 'per_sq_ft',
    this.multiplier = 1.0,
    this.manualQuantity = 1.0,
    this.isEnabled = true,
  });

  /// Computes effective quantity based on customer's total Sq. Ft, Window count, Channel width in feet, or Wire in meters (sq ft * 2.7)
  double getEffectiveQuantity({
    required double totalSqFt,
    required int totalWindows,
    double totalChannelWidthFt = 0.0,
  }) {
    if (!isEnabled) return 0.0;
    switch (calculationType) {
      case 'per_channel_chokdi':
        final channelsCount = totalChannelWidthFt > 0 ? (totalChannelWidthFt / 10.0).ceil() : 0;
        return (channelsCount * 60 * multiplier).toDouble();
      case 'per_channel_bolts':
        final channelsCount = totalChannelWidthFt > 0 ? (totalChannelWidthFt / 10.0).ceil() : 0;
        return (channelsCount * 12 * multiplier).toDouble();
      case 'per_wire_meter':
        return totalSqFt * 2.7 * multiplier;
      case 'per_ft':
        return totalChannelWidthFt * multiplier;
      case 'per_sq_ft':
        return totalSqFt * multiplier;
      case 'per_window':
        return totalWindows * multiplier;
      case 'fixed':
      default:
        return manualQuantity;
    }
  }

  /// Computes total cost for this material
  double getTotalCost({
    required double totalSqFt,
    required int totalWindows,
    double totalChannelWidthFt = 0.0,
  }) {
    if (!isEnabled) return 0.0;
    final qty = getEffectiveQuantity(
      totalSqFt: totalSqFt,
      totalWindows: totalWindows,
      totalChannelWidthFt: totalChannelWidthFt,
    );
    return qty * unitPrice;
  }

  MaterialItem copyWith({
    int? id,
    bool clearId = false,
    int? customerId,
    String? name,
    String? category,
    String? unit,
    double? unitPrice,
    String? calculationType,
    double? multiplier,
    double? manualQuantity,
    bool? isEnabled,
  }) {
    return MaterialItem(
      id: clearId ? null : (id ?? this.id),
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      calculationType: calculationType ?? this.calculationType,
      multiplier: multiplier ?? this.multiplier,
      manualQuantity: manualQuantity ?? this.manualQuantity,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'name': name,
      'category': category,
      'unit': unit,
      'unit_price': unitPrice,
      'calculation_type': calculationType,
      'multiplier': multiplier,
      'manual_quantity': manualQuantity,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      unit: map['unit'] as String? ?? 'Sq. Ft',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      calculationType: map['calculation_type'] as String? ?? 'per_sq_ft',
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1.0,
      manualQuantity: (map['manual_quantity'] as num?)?.toDouble() ?? 1.0,
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
    );
  }
}
