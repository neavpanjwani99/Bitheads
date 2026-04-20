/// Standard FIFO (First-In, First-Out) Queue implementation.
/// Used for tracking the order of incoming patients for triage.
class PatientQueue<T> {
  final List<T> _items = [];

  /// Adds a patient to the end of the queue.
  /// O(1)
  void enqueue(T item) => _items.add(item);
  
  /// Removes and returns the first patient in the queue.
  /// O(n) due to list shifting, suitable for expected hospital queue sizes.
  T dequeue() {
    if (isEmpty) throw Exception('Queue empty');
    return _items.removeAt(0);
  }
  
  /// Returns the first patient without removing them.
  T peek() => _items.first;

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  
  /// Returns the 1-based position of a specific patient in the queue.
  int positionOf(T item) => _items.indexOf(item) + 1;
  
  /// Returns a copy of the items in the queue.
  List<T> toList() => List<T>.from(_items);

  /// Clears the queue.
  void clear() => _items.clear();

  /// Returns a read-only list of all items in the queue.
  List<T> get allItems => List.unmodifiable(_items);
}
