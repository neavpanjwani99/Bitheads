import '../../models/staff_model.dart';

/// Pure DSA Implementation: Stable Merge Sort for Staff Multiple Criteria
class StaffSorter {
  /// Sort staff by:
  /// 1. Availability (true first)
  /// 2. Response Time (lower first)
  /// 3. Assigned Patient Count (lower first)
  static void mergeSort(List<StaffModel> arr) {
    if (arr.length <= 1) return;
    
    // We need actual assignment count and response times.
    // For this generic sorter, we rely on properties inside StaffModel.
    _splitAndMerge(arr, 0, arr.length - 1);
  }

  static void _splitAndMerge(List<StaffModel> arr, int left, int right) {
    if (left < right) {
      int mid = left + (right - left) ~/ 2;
      _splitAndMerge(arr, left, mid);
      _splitAndMerge(arr, mid + 1, right);
      _merge(arr, left, mid, right);
    }
  }

  static void _merge(List<StaffModel> arr, int left, int mid, int right) {
    int n1 = mid - left + 1;
    int n2 = right - mid;

    List<StaffModel> L = List.generate(n1, (i) => arr[left + i]);
    List<StaffModel> R = List.generate(n2, (i) => arr[mid + 1 + i]);

    int i = 0, j = 0, k = left;

    while (i < n1 && j < n2) {
      if (_compareStaff(L[i], R[j]) <= 0) {
        arr[k] = L[i];
        i++;
      } else {
        arr[k] = R[j];
        j++;
      }
      k++;
    }

    while (i < n1) {
      arr[k] = L[i];
      i++;
      k++;
    }

    while (j < n2) {
      arr[k] = R[j];
      j++;
      k++;
    }
  }

  /// Returns negative if a < b, positive if a > b, 0 if equal
  static int _compareStaff(StaffModel a, StaffModel b) {
    // 1. Availability (true comes first)
    if (a.available && !b.available) return -1;
    if (!a.available && b.available) return 1;

    // 2. Response time
    if (a.averageResponseTimeSecs < b.averageResponseTimeSecs) return -1;
    if (a.averageResponseTimeSecs > b.averageResponseTimeSecs) return 1;

    // 3. Workload (assigned patients)
    if (a.patientCount < b.patientCount) return -1;
    if (a.patientCount > b.patientCount) return 1;

    // Stable tie-breaker: UID
    return a.uid.compareTo(b.uid);
  }
}
