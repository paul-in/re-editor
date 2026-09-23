part of re_editor;


/// A fast Binary Indexed Tree (Fenwick Tree) cache to maintain variable line heights
/// in a highly virtualized environment.
/// Instead of absolute heights, it only stores the `delta` (difference) from the
/// default `preferredLineHeight`. This allows the Controller to manage the cache
/// array size/shifts without knowing the physical font metrics of the RenderBox.
class LineHeightCache {
  List<double> _tree;
  List<double> _deltas;

  LineHeightCache(int size)
      : _tree = List.filled(size + 1, 0.0),
        _deltas = List.filled(size, 0.0);

  int get length => _deltas.length;

  /// Shift the cache array when lines are added or removed.
  void replaceRange(int index, int removeCount, int insertCount) {
    if (removeCount == insertCount) {
      for(int i = 0; i < removeCount; i++) {
        final currentDelta = _deltas[index + i];
        if (currentDelta != 0.0) {
          _updateDelta(index + i, -currentDelta);
          _deltas[index + i] = 0.0;
        }
      }
      return;
    }

    final newSize = _deltas.length - removeCount + insertCount;
    final newDeltas = List.filled(newSize, 0.0);
    
    for (int i = 0; i < index && i < _deltas.length; i++) {
      newDeltas[i] = _deltas[i];
    }
    for (int i = index + removeCount; i < _deltas.length; i++) {
      int newI = i - removeCount + insertCount;
      if (newI < newSize) {
        newDeltas[newI] = _deltas[i];
      }
    }
    
    _deltas = newDeltas;
    _tree = List.filled(newSize + 1, 0.0);
    for (int i = 0; i < _deltas.length; i++) {
      if (_deltas[i] != 0.0) {
        _updateDelta(i, _deltas[i]);
      }
    }
  }

  /// Updates the delta for a specific line index.
  void updateLineDelta(int index, double newDelta) {
    if (index < 0 || index >= _deltas.length) return;
    
    final double oldDelta = _deltas[index];
    if (oldDelta == newDelta) return;
    
    _deltas[index] = newDelta;
    _updateDelta(index, newDelta - oldDelta);
  }

  void _updateDelta(int index, double diff) {
    for (int i = index + 1; i < _tree.length; i += i & -i) {
      _tree[i] += diff;
    }
  }

  /// Returns the sum of all deltas up to the given index (exclusive).
  double getSumDeltas(int index) {
    if (index <= 0) return 0.0;
    if (index > _deltas.length) index = _deltas.length;
    
    double sum = 0.0;
    for (int i = index; i > 0; i -= i & -i) {
      sum += _tree[i];
    }
    return sum;
  }
}
