import '../../mock/mock_data.dart';
import '../../models/staff_model.dart';
import 'staff_graph.dart';

/// Stability-preserving sorting logic for hospital staff.
/// Uses Merge Sort to ensure O(n log n) efficiency and stable results.
class StaffSorter {
  
  /// Performs a stable Merge Sort on the provided list.
  /// Time Complexity: O(n log n)
  /// Space Complexity: O(n)
  static List<StaffModel> mergeSort(
      List<StaffModel> list,
      int Function(StaffModel, StaffModel) compare) {
    if (list.length <= 1) return list;

    int mid = list.length ~/ 2;
    final left = mergeSort(list.sublist(0, mid), compare);
    final right = mergeSort(list.sublist(mid), compare);

    return _merge(left, right, compare);
  }

  static List<StaffModel> _merge(
      List<StaffModel> left,
      List<StaffModel> right,
      int Function(StaffModel, StaffModel) compare) {
    List<StaffModel> result = [];
    int i = 0;
    int j = 0;

    while (i < left.length && j < right.length) {
      if (compare(left[i], right[j]) <= 0) {
        result.add(left[i++]);
      } else {
        result.add(right[j++]);
      }
    }

    result.addAll(left.sublist(i));
    result.addAll(right.sublist(j));
    return result;
  }

  /// Sorts staff by availability (Online first).
  static List<StaffModel> byAvailability(List<StaffModel> staff) {
    return mergeSort(staff, (a, b) {
      if (a.available && !b.available) return -1;
      if (!a.available && b.available) return 1;
      return 0;
    });
  }

  /// Sorts staff by current workload (Least loaded first).
  static List<StaffModel> byWorkload(List<StaffModel> staff, StaffGraph graph) {
    return mergeSort(staff, (a, b) =>
        graph.getWorkload(a.uid).compareTo(graph.getWorkload(b.uid)));
  }
}
