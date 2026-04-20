import '../../models/bed_model.dart';

/// Performance-focused search utility for hospital beds.
class BedSearch {
  
  /// Sorts beds by Bed ID to prepare for binary search.
  /// O(n log n)
  static List<BedModel> sortById(List<BedModel> beds) {
    final sorted = List<BedModel>.from(beds);
    sorted.sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }

  /// Performs a Binary Search for a specific Bed ID.
  /// Requires the list to be sorted by [bedId].
  /// Time Complexity: O(log n)
  static BedModel? binarySearch(List<BedModel> sortedBeds, String id) {
    int low = 0;
    int high = sortedBeds.length - 1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      int cmp = sortedBeds[mid].id.compareTo(id);

      if (cmp == 0) {
        return sortedBeds[mid];
      } else if (cmp < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  /// Linear filter by status.
  /// O(n)
  static List<BedModel> filterByStatus(List<BedModel> beds, String status) {
    return beds.where((b) => b.status == status).toList();
  }
}
