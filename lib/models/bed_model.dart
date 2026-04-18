class BedModel {
  final String id;
  final String type; // ICU, General, Emergency
  final String status; // Available, Occupied, Reserved

  BedModel({
    required this.id,
    required this.type,
    required this.status,
  });

  BedModel copyWith({
    String? id,
    String? type,
    String? status,
  }) {
    return BedModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}
