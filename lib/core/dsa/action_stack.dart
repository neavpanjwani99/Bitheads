import 'package:flutter/foundation.dart';

/// Entry in the action stack tracking what happened and how to revert it.
class ActionEntry {
  final String description;
  final DateTime timestamp;
  final VoidCallback undoAction;

  ActionEntry({
    required this.description,
    required this.timestamp,
    required this.undoAction,
  });
}

/// LIFO (Last-In, First-Out) Stack implementation for 'Undo' functionality.
/// Maintains a maximum size of 10 to manage memory.
class ActionStack {
  final List<ActionEntry> _stack = [];
  static const int maxSize = 10;

  /// Pushes a new action onto the stack.
  /// O(1)
  void push(ActionEntry entry) {
    _stack.add(entry);
    if (_stack.length > maxSize) {
      _stack.removeAt(0);
    }
  }

  /// Returns and removes the last action performed.
  /// O(1)
  ActionEntry? pop() => _stack.isEmpty ? null : _stack.removeLast();

  ActionEntry? peek() => _stack.isEmpty ? null : _stack.last;

  /// Returns the most recent 5 actions for display in the Crisis Log.
  List<ActionEntry> get last5 => _stack.reversed.take(5).toList();

  bool get isEmpty => _stack.isEmpty;
  int get length => _stack.length;
}
