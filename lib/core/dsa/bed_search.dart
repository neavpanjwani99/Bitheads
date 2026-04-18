import '../../models/bed_model.dart';

/// Pure DSA Implementation: Binary Search for Beds
class BedSearch {
  /// Assumes `sortedBeds` is pre-sorted by Bed ID.
  /// Throws if list is not sorted, though we expect caller to maintain order.
  static BedModel? binarySearch(List<BedModel> sortedBeds, String targetId) {
    int left = 0;
    int right = sortedBeds.length - 1;

    while (left <= right) {
      int mid = left + ((right - left) ~/ 2);
      int comparison = sortedBeds[mid].id.compareTo(targetId);

      if (comparison == 0) {
        return sortedBeds[mid];
      } else if (comparison < 0) {
        // target is greater
        left = mid + 1;
      } else {
        // target is smaller
        right = mid - 1;
      }
    }
    
    return null; // Not found
  }
}
