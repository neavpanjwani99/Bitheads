import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResourceItem {
  final String id;
  final String name;
  final int count;
  final int threshold; // Below this => Critical

  ResourceItem({
    required this.id,
    required this.name,
    required this.count,
    required this.threshold,
  });

  bool get isCritical => count < threshold;

  ResourceItem copyWith({int? count}) {
    return ResourceItem(
      id: id,
      name: name,
      count: count ?? this.count,
      threshold: threshold,
    );
  }
}

class ResourcesNotifier extends Notifier<List<ResourceItem>> {
  @override
  List<ResourceItem> build() {
    return [
      // Blood
      ResourceItem(id: 'B-A', name: 'A+ Blood', count: 4, threshold: 5),
      ResourceItem(id: 'B-B', name: 'B+ Blood', count: 2, threshold: 5),
      ResourceItem(id: 'B-O', name: 'O+ Blood', count: 14, threshold: 5),
      ResourceItem(id: 'B-AB', name: 'AB+ Blood', count: 7, threshold: 5),
      // Equip
      ResourceItem(id: 'E-V', name: 'Ventilators', count: 2, threshold: 3),
      ResourceItem(id: 'E-D', name: 'Defibrillators', count: 5, threshold: 3),
      ResourceItem(id: 'E-O', name: 'Oxygen Cylinders', count: 1, threshold: 3),
    ];
  }

  void updateCount(String id, int count) {
    state = state.map((r) {
      if (r.id == id) return r.copyWith(count: count);
      return r;
    }).toList();
  }
}

final resourcesProvider = NotifierProvider<ResourcesNotifier, List<ResourceItem>>(ResourcesNotifier.new);
