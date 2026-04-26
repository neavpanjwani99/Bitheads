class InventoryItemModel {
  final String id;
  final String itemName;
  final String category; // Medical Gas, Blood, Equipment, PPE
  final double currentStock;
  final double minThreshold;
  final double hourlyConsumptionRatePerPatient;
  final String unit;

  InventoryItemModel({
    required this.id,
    required this.itemName,
    required this.category,
    required this.currentStock,
    required this.minThreshold,
    this.hourlyConsumptionRatePerPatient = 0.05,
    required this.unit,
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItemModel(
      id: id,
      itemName: map['itemName'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      currentStock: (map['currentStock'] as num? ?? 0).toDouble(),
      minThreshold: (map['minThreshold'] as num? ?? 0).toDouble(),
      hourlyConsumptionRatePerPatient: (map['hourlyConsumptionRatePerPatient'] as num? ?? 0.05).toDouble(),
      unit: map['unit'] as String? ?? 'units',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'currentStock': currentStock,
      'minThreshold': minThreshold,
      'hourlyConsumptionRatePerPatient': hourlyConsumptionRatePerPatient,
      'unit': unit,
    };
  }

  double calculateSurvivalHours(int patientCount) {
    if (patientCount == 0) return currentStock * 100; // Effectively infinite
    double consumptionPerHour = patientCount * hourlyConsumptionRatePerPatient;
    return currentStock / consumptionPerHour;
  }
}
