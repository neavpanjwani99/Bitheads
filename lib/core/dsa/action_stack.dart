import 'dart:collection';

/// Generic representation of an action that can be undone
class AdminAction {
  final String description;
  final DateTime timestamp;
  final Function undoCallback;

  AdminAction({
    required this.description, 
    required this.timestamp, 
    required this.undoCallback
  });
}

/// Pure DSA Implementation: LIFO Stack for Crisis Log & Undo
class ActionStack {
  final Queue<AdminAction> _stack = ListQueue<AdminAction>();

  void push(AdminAction action) {
    _stack.addLast(action);
  }

  AdminAction? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  AdminAction? peek() {
    if (_stack.isEmpty) return null;
    return _stack.last;
  }
  
  bool get isEmpty => _stack.isEmpty;
  
  void undoLastAction() {
    AdminAction? last = pop();
    if (last != null) {
      last.undoCallback();
    }
  }

  List<AdminAction> getHistory() {
    // Return history reversed (newest first)
    return _stack.toList().reversed.toList();
  }
}
