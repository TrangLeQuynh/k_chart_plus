import 'package:flutter/foundation.dart';

/// How the user is currently interacting with the chart.
enum InteractionMode {
  /// No active interaction is occurring
  none,

  /// User is interacting with the crosshair
  crosshair,
}

/// View port of the chart — the *model* of the interactive layer.
///
/// It owns every value that describes what the user is currently looking at:
///
///  * [scaleX] — zoom factor. It is baked into the width of a single data
///    point (`chartStyle.pointWidth * scaleX`) instead of `canvas.scale`, so
///    strokes and dots keep their intended size.
///  * [scrollX] — pan offset **in screen pixels**, `0` meaning "stuck to the
///    right edge" and [maxScrollX] meaning "stuck to the left edge".
///  * [mode] / [selectX] — the crosshair: whether it is up, and which x
///    coordinate (in local widget pixels) it points at.
///
/// Every mutation notifies listeners, which is what drives the repaint of
/// `CustomPaint` — no `setState` is involved on the interaction hot path.
class PointViewPort extends ChangeNotifier {
  PointViewPort({
    double initialScaleX = defaultScaleX,
    this.minScaleX = 0.25,
    this.maxScaleX = 2.5,
  })  : _initialScaleX = initialScaleX,
        _scaleX = initialScaleX.clamp(minScaleX, maxScaleX).toDouble(),
        _baseScaleX = initialScaleX.clamp(minScaleX, maxScaleX).toDouble();

  /// Scale a freshly created / [reset] view port starts at.
  static const double defaultScaleX = 1.0;

  /// Lower bound of [scaleX] (the most zoomed out the chart can get).
  final double minScaleX;

  /// Upper bound of [scaleX] (the most zoomed in the chart can get).
  final double maxScaleX;

  final double _initialScaleX;

  double _scaleX;
  double get scaleX => _scaleX;

  double _scrollX = 0.0;
  double get scrollX => _scrollX;

  double _maxScrollX = 0.0;

  /// Largest allowed [scrollX], recomputed by the painter on every frame from
  /// the data length and the available width.
  double get maxScrollX => _maxScrollX;

  /// [scaleX] captured when the current pinch started; the gesture reports a
  /// cumulative scale, so it is always applied on top of this.
  double _baseScaleX;

  bool _isScaling = false;
  bool get isScaling => _isScaling;

  /// True when the view port sits at the right-most (newest) edge.
  bool get isAtRightEdge => _scrollX <= 0;

  /// True when the view port sits at the left-most (oldest) edge.
  bool get isAtLeftEdge => _maxScrollX > 0 && _scrollX >= _maxScrollX;

  InteractionMode _mode = InteractionMode.none;
  InteractionMode get mode => _mode;

  double _selectX = 0.0;
  double get selectX => _selectX;

  bool get isCrosshairVisible => _mode == InteractionMode.crosshair;

  /// Rebases the pinch on the current [scaleX]. Call once per pinch, before
  /// the first [updateScale].
  void beginScale() {
    _baseScaleX = _scaleX;
    _isScaling = true;
  }

  /// Applies the cumulative [gestureScale] of the running pinch.
  void updateScale(double gestureScale) {
    zoomTo(_baseScaleX * gestureScale);
  }

  /// Ends the pinch, keeping whatever scale it settled on.
  void endScale() {
    _baseScaleX = _scaleX;
    _isScaling = false;
  }

  /// Programmatically sets the zoom, clamped to [minScaleX] / [maxScaleX].
  void zoomTo(double value) {
    final double next = value.clamp(minScaleX, maxScaleX).toDouble();
    if (next == _scaleX) return;
    _scaleX = next;
    if (!_isScaling) _baseScaleX = next;
    notifyListeners();
  }

  // ---------------------------------------------------------------- panning

  /// Pans by [dx] screen pixels (finger delta, applied 1:1).
  void panBy(double dx) => scrollTo(_scrollX + dx);

  /// Programmatically sets the pan offset, clamped to `0..maxScrollX`.
  void scrollTo(double value) {
    final double next = value.clamp(0.0, _maxScrollX).toDouble();
    if (next == _scrollX) return;
    _scrollX = next;
    notifyListeners();
  }

  // -------------------------------------------------------------- crosshair

  /// Shows the crosshair at [x], or moves it there if already visible.
  void showCrosshair(double x) {
    _mode = InteractionMode.crosshair;
    _selectX = x;
    notifyListeners();
  }

  /// Hides the crosshair, keeping the last [selectX].
  void hideCrosshair() {
    _mode = InteractionMode.none;
    notifyListeners();
  }

  /// Hides the crosshair if it is up, shows it at [x] otherwise.
  void toggleCrosshairAt(double x) {
    if (isCrosshairVisible) {
      hideCrosshair();
    } else {
      showCrosshair(x);
    }
  }

  // ------------------------------------------------------------------ frame

  /// Publishes the bounds computed during layout/paint.
  ///
  /// Deliberately silent: it runs inside `paint`, where notifying listeners
  /// would schedule another paint for the very frame being drawn.
  void updateBounds({required double maxScrollX}) {
    _maxScrollX = maxScrollX;
    _scrollX = _scrollX.clamp(0.0, _maxScrollX).toDouble();
  }

  /// Restores the defaults the view port was created with: `scaleX = 1.0`
  /// (unless another initial scale was given), no pan, no crosshair.
  void reset() {
    final double scale = _initialScaleX.clamp(minScaleX, maxScaleX).toDouble();
    final bool changed = _scaleX != scale ||
        _scrollX != 0.0 ||
        _mode != InteractionMode.none ||
        _selectX != 0.0;
    _scaleX = scale;
    _baseScaleX = scale;
    _scrollX = 0.0;
    _isScaling = false;
    _mode = InteractionMode.none;
    _selectX = 0.0;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
