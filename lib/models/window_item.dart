class WindowItem {
  final int? id;
  final int roomId;
  final int customerId;
  final String label; // e.g. "Window 1", "W1", "Balcony Sliding"
  final String windowType; // "3-Track Sliding", "2-Track Sliding", "Casement / Openable", "Fixed Glass", "Ventilator"
  final double widthInches;
  final double heightInches;
  final int quantity;
  final double ratePerSqFt; // optional custom rate if applicable

  WindowItem({
    this.id,
    required this.roomId,
    required this.customerId,
    required this.label,
    this.windowType = '3-Track Sliding',
    required this.widthInches,
    required this.heightInches,
    this.quantity = 1,
    this.ratePerSqFt = 0.0,
  });

  /// Width in feet (e.g. 48" -> 4.00 ft)
  double get widthFeet => widthInches <= 0 ? 0.0 : widthInches / 12.0;

  /// Height in feet (e.g. 60" -> 5.00 ft)
  double get heightFeet => heightInches <= 0 ? 0.0 : heightInches / 12.0;

  /// Area in Square Feet for a single window: (W" * H") / 144
  double get sqFtPerUnit {
    if (widthInches <= 0 || heightInches <= 0) return 0.0;
    return (widthInches * heightInches) / 144.0;
  }

  /// Total Area in Sq. Ft for this window line item: sqFtPerUnit * quantity
  double get totalSqFt => sqFtPerUnit * (quantity > 0 ? quantity : 1);

  /// Perimeter in running feet (2 * (W + H) in feet)
  double get perimeterFeet {
    if (widthInches <= 0 || heightInches <= 0) return 0.0;
    return 2 * (widthFeet + heightFeet) * (quantity > 0 ? quantity : 1);
  }

  /// Estimated cost if ratePerSqFt is set
  double get totalCost => totalSqFt * ratePerSqFt;

  WindowItem copyWith({
    int? id,
    int? roomId,
    int? customerId,
    String? label,
    String? windowType,
    double? widthInches,
    double? heightInches,
    int? quantity,
    double? ratePerSqFt,
  }) {
    return WindowItem(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      windowType: windowType ?? this.windowType,
      widthInches: widthInches ?? this.widthInches,
      heightInches: heightInches ?? this.heightInches,
      quantity: quantity ?? this.quantity,
      ratePerSqFt: ratePerSqFt ?? this.ratePerSqFt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'room_id': roomId,
      'customer_id': customerId,
      'label': label,
      'window_type': windowType,
      'width_inches': widthInches,
      'height_inches': heightInches,
      'quantity': quantity,
      'rate_per_sq_ft': ratePerSqFt,
    };
  }

  factory WindowItem.fromMap(Map<String, dynamic> map) {
    return WindowItem(
      id: map['id'] as int?,
      roomId: map['room_id'] as int? ?? 0,
      customerId: map['customer_id'] as int? ?? 0,
      label: map['label'] as String? ?? 'Window',
      windowType: map['window_type'] as String? ?? '3-Track Sliding',
      widthInches: (map['width_inches'] as num?)?.toDouble() ?? 0.0,
      heightInches: (map['height_inches'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      ratePerSqFt: (map['rate_per_sq_ft'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
