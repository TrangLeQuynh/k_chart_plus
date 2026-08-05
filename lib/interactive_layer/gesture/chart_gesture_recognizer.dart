import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/gestures.dart';

/// What the recognizer has decided the current pointer sequence is.
enum _ChartGesture {
  /// No pointer is down.
  ready,

  /// A pointer is down but the gesture is still ambiguous (tap? pan? press?).
  possible,

  /// Single finger dragging — only the horizontal part pans the chart.
  pan,

  /// Single finger held down — drives the crosshair.
  longPress,

  /// Two or more fingers — pinch zoom.
  scale,

  /// Decided and delivered; waiting for the remaining pointers to lift.
  finished,
}

typedef ChartPositionCallback = void Function(Offset localPosition);
typedef ChartPanUpdateCallback = void Function(Offset delta);
typedef ChartPanEndCallback = void Function(double velocityX);
typedef ChartScaleUpdateCallback = void Function(double scale);

/// One recognizer for every chart gesture: tap, long press (+ slide),
/// one-finger pan, two-finger pinch.
///
/// It is written by hand rather than composed from `TapGestureRecognizer` +
/// `LongPressGestureRecognizer` + `ScaleGestureRecognizer` because those three
/// fight each other in the arena: the scale recognizer claims the pointer as
/// soon as it moves, which makes "long press then slide the crosshair"
/// impossible to express. Owning the state machine keeps the transitions
/// explicit — and, importantly, keeps them resettable between sequences.
///
/// It only reports: pan, zoom and crosshair state lives in the `PointViewPort`
/// that `InteractiveLayerController` drives.
class ChartGestureRecognizer extends OneSequenceGestureRecognizer {
  ChartGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    this.longPressDuration = kLongPressTimeout,
  });

  /// How long a motionless pointer must stay down to become a long press.
  final Duration longPressDuration;

  /// A quick press and release, without crossing the touch slop.
  ChartPositionCallback? onTap;

  /// The pointer stayed down long enough to become a long press.
  ChartPositionCallback? onLongPressStart;

  /// The pointer moved while the long press is held.
  ChartPositionCallback? onLongPressUpdate;

  /// The long press was released (or cancelled).
  VoidCallback? onLongPressEnd;

  /// A single-finger drag started (the touch slop has just been crossed).
  ChartPositionCallback? onPanStart;

  /// Incremental drag movement, in local pixels.
  ChartPanUpdateCallback? onPanUpdate;

  /// The drag was released, with the horizontal fling velocity in px/s.
  ChartPanEndCallback? onPanEnd;

  /// A second finger went down: a pinch started.
  VoidCallback? onScaleStart;

  /// Cumulative pinch scale, relative to the start of the pinch.
  ChartScaleUpdateCallback? onScaleUpdate;

  /// The pinch dropped below two fingers.
  VoidCallback? onScaleEnd;

  final Map<int, Offset> _pointers = <int, Offset>{};
  _ChartGesture _state = _ChartGesture.ready;
  int? _primaryPointer;
  Offset _initialPosition = Offset.zero;
  Offset _lastPrimaryPosition = Offset.zero;
  Timer? _longPressTimer;
  VelocityTracker? _velocityTracker;
  double _initialSpan = 0.0;
  bool _accepted = false;

  @override
  String get debugDescription => 'chart';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointers[event.pointer] = event.localPosition;

    if (_state == _ChartGesture.ready) {
      _state = _ChartGesture.possible;
      _primaryPointer = event.pointer;
      _initialPosition = event.localPosition;
      _lastPrimaryPosition = event.localPosition;
      _velocityTracker = VelocityTracker.withKind(event.kind)
        ..addPosition(event.timeStamp, event.localPosition);
      _startLongPressTimer();
    }

    // A second finger always wins over whatever the first one was doing.
    if (_pointers.length >= 2) {
      _beginScale();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _pointers[event.pointer] = event.localPosition;
      _handleMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handleUp(event);
    }
  }

  void _handleMove(PointerMoveEvent event) {
    final bool isPrimary = event.pointer == _primaryPointer;
    if (isPrimary) {
      _lastPrimaryPosition = event.localPosition;
    }

    switch (_state) {
      case _ChartGesture.possible:
        if (!isPrimary) return;
        _velocityTracker?.addPosition(event.timeStamp, event.localPosition);
        final double slop = computeHitSlop(event.kind, gestureSettings);
        if ((event.localPosition - _initialPosition).distance > slop) {
          _beginPan(event.localPosition);
          // The move that crossed the slop still carries real finger travel;
          // forwarding it keeps a single large move event (as sent by tests
          // and by low frequency devices) from being swallowed.
          onPanUpdate?.call(event.localDelta);
        }
      case _ChartGesture.pan:
        if (!isPrimary) return;
        _velocityTracker?.addPosition(event.timeStamp, event.localPosition);
        onPanUpdate?.call(event.localDelta);
      case _ChartGesture.longPress:
        if (!isPrimary) return;
        onLongPressUpdate?.call(event.localPosition);
      case _ChartGesture.scale:
        if (_initialSpan <= 0) return;
        onScaleUpdate?.call(_computeSpan() / _initialSpan);
      case _ChartGesture.ready:
      case _ChartGesture.finished:
        break;
    }
  }

  void _handleUp(PointerEvent event) {
    final bool isPrimary = event.pointer == _primaryPointer;
    final bool cancelled = event is PointerCancelEvent;
    _pointers.remove(event.pointer);

    switch (_state) {
      case _ChartGesture.possible:
        if (isPrimary) {
          _cancelLongPressTimer();
          if (!cancelled) {
            _acceptGesture();
            onTap?.call(_lastPrimaryPosition);
          }
          _state = _ChartGesture.finished;
        }
      case _ChartGesture.pan:
        if (isPrimary) {
          final Velocity velocity =
              _velocityTracker?.getVelocity() ?? Velocity.zero;
          onPanEnd?.call(cancelled ? 0.0 : velocity.pixelsPerSecond.dx);
          _state = _ChartGesture.finished;
        }
      case _ChartGesture.longPress:
        if (isPrimary) {
          onLongPressEnd?.call();
          _state = _ChartGesture.finished;
        }
      case _ChartGesture.scale:
        if (_pointers.length < 2) {
          onScaleEnd?.call();
          // Deliberately not falling back to panning with the finger that is
          // still down: it would jump the chart under the user.
          _state = _ChartGesture.finished;
        } else {
          // Still pinching with the remaining fingers — rebase so the scale
          // does not jump.
          _restartScale();
        }
      case _ChartGesture.ready:
      case _ChartGesture.finished:
        break;
    }

    // Once the last pointer is released this triggers didStopTrackingLastPointer
    // and the state machine goes back to `ready`.
    stopTrackingPointer(event.pointer);
  }

  // --------------------------------------------------------------- decisions

  void _beginPan(Offset position) {
    _cancelLongPressTimer();
    _state = _ChartGesture.pan;
    _acceptGesture();
    onPanStart?.call(position);
  }

  void _beginScale() {
    _cancelLongPressTimer();
    switch (_state) {
      case _ChartGesture.pan:
        onPanEnd?.call(0.0);
      case _ChartGesture.longPress:
        onLongPressEnd?.call();
      case _ChartGesture.ready:
      case _ChartGesture.possible:
      case _ChartGesture.scale:
      case _ChartGesture.finished:
        break;
    }
    _state = _ChartGesture.scale;
    _initialSpan = _computeSpan();
    _acceptGesture();
    onScaleStart?.call();
  }

  /// Rebases the running pinch on the fingers that are still down.
  void _restartScale() {
    _initialSpan = _computeSpan();
    onScaleStart?.call();
  }

  void _startLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(longPressDuration, _handleLongPressTimeout);
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _handleLongPressTimeout() {
    _longPressTimer = null;
    if (_state != _ChartGesture.possible) return;
    _state = _ChartGesture.longPress;
    _acceptGesture();
    onLongPressStart?.call(_lastPrimaryPosition);
  }

  void _acceptGesture() {
    if (_accepted) return;
    _accepted = true;
    resolve(GestureDisposition.accepted);
  }

  /// Mean distance of the active pointers from their focal point — the same
  /// definition `ScaleGestureRecognizer` uses, so pinch feels identical.
  double _computeSpan() {
    if (_pointers.length < 2) return 0.0;
    Offset focalPoint = Offset.zero;
    for (final Offset position in _pointers.values) {
      focalPoint += position;
    }
    focalPoint = focalPoint / _pointers.length.toDouble();

    double totalDeviation = 0.0;
    for (final Offset position in _pointers.values) {
      totalDeviation += (position - focalPoint).distance;
    }
    return totalDeviation / _pointers.length;
  }

  // ------------------------------------------------------------------ arena

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _primaryPointer && !_accepted) {
      _cancelLongPressTimer();
      _state = _ChartGesture.finished;
    }
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_accepted) {
      // Never claimed the sequence (e.g. a tap that lost the arena): leave it
      // to whoever else was competing.
      resolve(GestureDisposition.rejected);
    }
    _reset();
  }

  void _reset() {
    _cancelLongPressTimer();
    _pointers.clear();
    _state = _ChartGesture.ready;
    _primaryPointer = null;
    _initialPosition = Offset.zero;
    _lastPrimaryPosition = Offset.zero;
    _velocityTracker = null;
    _initialSpan = 0.0;
    _accepted = false;
  }

  @override
  void dispose() {
    _cancelLongPressTimer();
    super.dispose();
  }
}
