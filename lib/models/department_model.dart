class DepartmentModel {
  final String id;
  final String name;
  final String headOfDept;
  final int totalBeds;
  final int occupiedBeds;
  final bool isDrillActive; // Command Center: Drill Mode
  final String status; // Normal, Critical, Drill

  DepartmentModel({
    required this.id,
    required this.name,
    required this.headOfDept,
    required this.totalBeds,
    this.occupiedBeds = 0,
    this.isDrillActive = false,
    this.status = 'Normal',
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      name: map['name'] as String? ?? '',
      headOfDept: map['headOfDept'] as String? ?? '',
      totalBeds: map['totalBeds'] as int? ?? 0,
      occupiedBeds: map['occupiedBeds'] as int? ?? 0,
      isDrillActive: map['isDrillActive'] as bool? ?? false,
      status: map['status'] as String? ?? 'Normal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'headOfDept': headOfDept,
      'totalBeds': totalBeds,
      'occupiedBeds': occupiedBeds,
      'isDrillActive': isDrillActive,
      'status': status,
    };
  }

  double get occupancyRate => totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0;
}
