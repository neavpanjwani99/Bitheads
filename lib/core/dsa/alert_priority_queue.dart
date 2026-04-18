import '../../models/alert_model.dart';

/// Pure DSA Implementation: Min-Heap for Alert Priorities
class AlertPriorityQueue {
  final List<AlertModel> _heap = [];

  // Weights: CRITICAL=0, URGENT=1, STABLE=2
  int _weight(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL': return 0;
      case 'URGENT': return 1;
      case 'STABLE': return 2;
      default: return 3;
    }
  }

  bool _compare(AlertModel a, AlertModel b) {
    int wA = _weight(a.severity);
    int wB = _weight(b.severity);
    if (wA != wB) {
      return wA < wB; // Lower weight comes first
    }
    // If equal severity, older timestamp comes first (FIFO for same priority)
    return a.createdAt.isBefore(b.createdAt);
  }

  void insert(AlertModel alert) {
    _heap.add(alert);
    _siftUp(_heap.length - 1);
  }

  AlertModel? extract() {
    if (_heap.isEmpty) return null;
    if (_heap.length == 1) return _heap.removeLast();

    AlertModel root = _heap[0];
    _heap[0] = _heap.removeLast();
    _siftDown(0);
    return root;
  }

  AlertModel? peek() => _heap.isNotEmpty ? _heap.first : null;

  void removeById(String id) {
    int index = _heap.indexWhere((element) => element.id == id);
    if (index == -1) return;

    if (index == _heap.length - 1) {
      _heap.removeLast();
      return;
    }

    _heap[index] = _heap.removeLast();
    _siftUp(index);
    _siftDown(index);
  }
  
  List<AlertModel> toList() {
    // Return a sorted snapshot without mutating heap
    // Warning: Sorting output here is O(N log N), but technically 
    // real usage would pop out elements. For flutter UI binding, 
    // we do an isolated cloned heap destructive drain to display natively correctly.
    AlertPriorityQueue clone = AlertPriorityQueue();
    clone._heap.addAll(_heap);
    
    List<AlertModel> sortedList = [];
    while (clone._heap.isNotEmpty) {
      sortedList.add(clone.extract()!);
    }
    return sortedList;
  }

  void _siftUp(int k) {
    while (k > 0) {
      int parent = (k - 1) ~/ 2;
      if (_compare(_heap[k], _heap[parent])) {
        _swap(k, parent);
        k = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int k) {
    int n = _heap.length;
    while (true) {
      int left = 2 * k + 1;
      int right = 2 * k + 2;
      int smallest = k;

      if (left < n && _compare(_heap[left], _heap[smallest])) {
        smallest = left;
      }
      if (right < n && _compare(_heap[right], _heap[smallest])) {
        smallest = right;
      }
      if (smallest != k) {
        _swap(k, smallest);
        k = smallest;
      } else {
        break;
      }
    }
  }

  void _swap(int i, int j) {
    AlertModel temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
  
  void clear() => _heap.clear();
}
