import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'viewport/point_view_port.dart';

/// Which edge of the data the chart ran into.
typedef LoadMoreCallback = void Function(bool isRightEdge);

/// The *controller* of the interactive layer.
///
/// It translates the raw gestures reported by `ChartGestureRecognizer` into
/// direct calls on the [pointViewPort] model and owns the fling animation. It
/// never rebuilds anything: the view port notifies, and `CustomPaint`
/// repaints from [repaint].
///
/// A controller can be handed to `KChartWidget` to drive the chart from the
/// outside — `zoomTo`, `scrollTo` and especially [reset] (back to
/// `scaleX = 1.0`, no pan, no crosshair).
class InteractiveLayerController {
  InteractiveLayerController({
    double initialScaleX = PointViewPort.defaultScaleX,
    double minScaleX = 0.25,
    double maxScaleX = 2.5,
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
  })  : pointViewPort = PointViewPort(
    initialScaleX: initialScaleX,
    minScaleX: minScaleX,
    maxScaleX: maxScaleX,
  );

  /// Zoom, pan and crosshair state.
  final PointViewPort pointViewPort;

  /// Duration of the fling animation that follows a pan.
  int flingTime;

  /// Fraction of the release velocity turned into extra scrolling.
  double flingRatio;

  /// Easing of the fling animation.
  Curve flingCurve;

  /// Called when a fling runs into either end of the data.
  LoadMoreCallback? onLoadMore;

  /// The [Listenable] the chart painter repaints on: any change in the view
  /// port, no `setState` involved.
  Listenable get repaint => pointViewPort;

  AnimationController? _flingController;
  Animation<double>? _flingAnimation;
  TickerProvider? _vsync;
  // bool _isDragging = false;

  /// Provides the ticker used by the fling animation. Called by the widget
  /// when the controller is mounted.
  void attach(TickerProvider vsync) {
    if (identical(_vsync, vsync)) return;
    _disposeFling();
    _vsync = vsync;
  }

  /// Releases the ticker; the view port keeps its state.
  void detach() {
    _disposeFling();
    _vsync = null;
  }

  // --------------------------------------------------------------- gestures

  /// Tap toggles the crosshair: first tap shows it, next one dismisses it.
  void handleTap(Offset position) {
    _stopFling();
    pointViewPort.toggleCrosshairAt(position.dx);
  }

  void handleLongPressStart(Offset position) {
    _stopFling();
    pointViewPort.showCrosshair(position.dx);
  }

  void handleLongPressUpdate(Offset position) {
    pointViewPort.showCrosshair(position.dx);
  }

  /// Releasing a long press keeps the crosshair up; only a tap dismisses it.
  void handleLongPressEnd() {}

  void handlePanStart(Offset position) {
    _stopFling();
    pointViewPort.hideCrosshair();
    // _setDragging(true);
  }

  void handlePanUpdate(Offset delta) {
    // scrollX is in screen pixels (zoom lives in the point width), so the
    // finger delta is applied 1:1.
    pointViewPort.panBy(delta.dx);
  }

  void handlePanEnd(double velocityX) {
    // _setDragging(false);
    _startFling(velocityX);
  }

  void handleScaleStart() {
    _stopFling();
    pointViewPort.hideCrosshair();
    pointViewPort.beginScale();
    // _setDragging(true);
  }

  void handleScaleUpdate(double scale) {
    pointViewPort.updateScale(scale);
  }

  void handleScaleEnd() {
    pointViewPort.endScale();
    // _setDragging(false);
  }

  /// Zooms to an absolute scale, clamped by the view port bounds.
  void zoomTo(double scaleX) {
    _stopFling();
    pointViewPort.zoomTo(scaleX);
  }

  /// Pans to an absolute offset in screen pixels (`0` = newest candle).
  void scrollTo(double scrollX) {
    _stopFling();
    pointViewPort.scrollTo(scrollX);
  }

  /// Restores every default: `scaleX = 1.0`, `scrollX = 0.0`, crosshair off.
  void reset() {
    _stopFling();
    // _setDragging(false);
    pointViewPort.reset();
  }

  void dispose() {
    _disposeFling();
    _vsync = null;
    pointViewPort.dispose();
  }

  void _startFling(double velocityX) {
    final TickerProvider? vsync = _vsync;
    if (vsync == null || velocityX == 0.0) return;

    _disposeFling();
    final AnimationController controller = AnimationController(
      duration: Duration(milliseconds: flingTime),
      vsync: vsync,
    );
    _flingController = controller;
    _flingAnimation = Tween<double>(
      begin: pointViewPort.scrollX,
      end: velocityX * flingRatio + pointViewPort.scrollX,
    ).animate(CurvedAnimation(parent: controller.view, curve: flingCurve))
      ..addListener(_handleFlingTick)
      ..addStatusListener(_handleFlingStatus);
    // _setDragging(true);
    controller.forward();
  }

  void _handleFlingTick() {
    final double value = _flingAnimation?.value ?? 0.0;
    if (value <= 0) {
      pointViewPort.scrollTo(0);
      onLoadMore?.call(true);
      _stopFling();
      return;
    }
    if (value >= pointViewPort.maxScrollX) {
      pointViewPort.scrollTo(pointViewPort.maxScrollX);
      onLoadMore?.call(false);
      _stopFling();
      return;
    }
    pointViewPort.scrollTo(value);
  }

  void _handleFlingStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      // _setDragging(false);
    }
  }

  void _stopFling() {
    final AnimationController? controller = _flingController;
    if (controller == null) return;
    if (controller.isAnimating) {
      controller.stop();
      // _setDragging(false);
    }
  }

  void _disposeFling() {
    _flingAnimation
      ?..removeListener(_handleFlingTick)
      ..removeStatusListener(_handleFlingStatus);
    _flingAnimation = null;
    _flingController?.dispose();
    _flingController = null;
  }

  // void _setDragging(bool value) {
  //   if (_isDragging == value) return;
  //   _isDragging = value;
  // }
}
