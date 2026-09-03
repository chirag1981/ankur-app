class Room {
  final int? id;
  final int customerId;
  final String name; // e.g. "Living Room", "Master Bedroom", "Kitchen", etc.
  final String notes;

  Room({
    this.id,
    required this.customerId,
    required this.name,
    this.notes = '',
  });

  Room copyWith({
    int? id,
    int? customerId,
    String? name,
    String? notes,
  }) {
    return Room(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'name': name,
      'notes': notes,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Room',
      notes: map['notes'] as String? ?? '',
    );
  }
}
