import '../../models/alert_model.dart';

/// Min-Heap based priority queue for hospital alerts.
/// This implementation ensures O(log n) insertion and O(log n) extraction.
/// Priorities: CRITICAL (0), URGENT (1), STABLE (2).
class AlertPriorityQueue {
  final List<AlertModel> _heap = [];

  /// Inserts an alert into the heap and maintains heap property (bubble up).
  /// Time Complexity: O(log n)
  void insert(AlertModel alert) {
    _heap.add(alert);
    _bubbleUp(_heap.length - 1);
  }

  /// Extracts the highest priority alert (min value).
  /// Time Complexity: O(log n)
  AlertModel extractMin() {
    if (_heap.isEmpty) throw Exception('Empty queue');
    final min = _heap[0];
    
    if (_heap.length == 1) {
      _heap.removeLast();
    } else {
      _heap[0] = _heap.last;
      _heap.removeLast();
      _siftDown(0);
    }
    return min;
  }

  AlertModel peek() => _heap[0];
  bool get isEmpty => _heap.isEmpty;
  int get length => _heap.length;

  /// Returns a sorted list of alerts based on priority.
  /// Uses a copy to avoid destroying the heap structure.
  /// Time Complexity: O(n log n)
  List<AlertModel> get sorted {
    // Standard sort for display, utilizing the priority logic
    final copy = List<AlertModel>.from(_heap);
    copy.sort((a, b) => _priority(a).compareTo(_priority(b)));
    return copy;
  }

  /// Maps alert severity to numeric priority.
  /// CRITICAL (0) is high priority (min in our min-heap).
  int _priority(AlertModel a) {
    if (a.severity == 'CRITICAL') return 0;
    if (a.severity == 'URGENT') return 1;
    return 2;
  }

  /// Restores heap property by moving a node up the tree.
  void _bubbleUp(int i) {
    while (i > 0) {
      int parent = (i - 1) ~/ 2;
      if (_priority(_heap[parent]) > _priority(_heap[i])) {
        final tmp = _heap[parent];
        _heap[parent] = _heap[i];
        _heap[i] = tmp;
        i = parent;
      } else {
        break;
      }
    }
  }

  void clear() => _heap.clear();

  List<AlertModel> toList() => sorted;

  /// Restores heap property by moving a node down the tree.
  void _siftDown(int i) {
    int smallest = i;
    int left = 2 * i + 1;
    int right = 2 * i + 2;

    if (left < _heap.length && _priority(_heap[left]) < _priority(_heap[smallest])) {
      smallest = left;
    }
    if (right < _heap.length && _priority(_heap[right]) < _priority(_heap[smallest])) {
      smallest = right;
    }

    if (smallest != i) {
      final tmp = _heap[smallest];
      _heap[smallest] = _heap[i];
      _heap[i] = tmp;
      _siftDown(smallest);
    }
  }
}
