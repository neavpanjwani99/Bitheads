import 'dart:collection';

/// Pure DSA Implementation: Sliding Window for Occupancy Trend
class OccupancyTrend {
  // A sliding window tracking total occupancy over minutes.
  // Each integer represents the percentage occupancy at a given 1-minute interval.
  final Queue<double> _window = ListQueue<double>();
  final int _windowSize;
  
  OccupancyTrend({int windowSizeMinutes = 10}) : _windowSize = windowSizeMinutes;

  void addDataPoint(double occupancyPercentage) {
    if (_window.length >= _windowSize) {
      _window.removeFirst();
    }
    _window.addLast(occupancyPercentage);
  }

  /// Returns 1 for upward trend, -1 for downward trend, 0 for stable
  int getTrend() {
    if (_window.length < 2) return 0;
    
    // Simple slope algorithm over the window
    double firstHalfAvg = 0;
    double secondHalfAvg = 0;
    
    int mid = _window.length ~/ 2;
    int i = 0;
    for (var point in _window) {
      if (i < mid) {
        firstHalfAvg += point;
      } else {
        secondHalfAvg += point;
      }
      i++;
    }
    
    firstHalfAvg /= mid;
    secondHalfAvg /= (_window.length - mid);
    
    // Threshold to prevent noise flutter
    if (secondHalfAvg - firstHalfAvg > 2.0) return 1;
    if (secondHalfAvg - firstHalfAvg < -2.0) return -1;
    return 0;
  }
}
