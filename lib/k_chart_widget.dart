import 'dart:async';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'renderer/base_dimension.dart';

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

typedef WidgetDetailBuilder = Widget Function(KLineEntity entity);

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final List<MainIndicator> mainIndicators; ///warning only using MA, BOLL, SAR
  final bool volHidden;
  final List<SecondaryIndicator> secondaryIndicators; ///SecondaryState { MACD, KDJ, RSI, WR, CCI }
  // final Function()? onSecondaryTap;
  final bool isLine;
  final bool hideGrid;
  final bool showNowPrice;
  final List<String> timeFormat;
  final double mBaseHeight;
  final double? mSecondaryHeight;

  // It will be called when the screen scrolls to the end.
  // If true, it will be scrolled to the end of the right side of the screen.
  // If it is false, it will be scrolled to the end of the left side of the screen.
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final KChartColors chartColors;
  final KChartStyle chartStyle;
  final double xFrontPadding;
  final WidgetDetailBuilder? detailBuilder;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    this.detailBuilder,
    this.xFrontPadding = 100,
    this.mainIndicators = const [],
    this.secondaryIndicators = const [],
    this.volHidden = false,
    this.isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.mBaseHeight = 360,
    this.mSecondaryHeight,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget> with TickerProviderStateMixin {
  final StreamController<InfoWindowEntity?> _mInfoWindowStream = StreamController<InfoWindowEntity?>();
  double _mScaleX = 1.0, _mScrollX = 0.0, _mSelectX = 0.0;
  AnimationController? _controller;
  Animation<double>? _aniX;

  double getMinScrollX() {
    return _mScaleX;
  }

  InteractionMode _interactionMode = InteractionMode.none;
  double _lastScale = 1.0;
  bool _isScale = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _mInfoWindowStream.sink.close();
    _mInfoWindowStream.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      _mScrollX = _mSelectX = 0.0;
      _mScaleX = 1.0;
      _lastScale = 1.0;
    }
    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      mSecondaryHeight: widget.mSecondaryHeight ?? widget.mBaseHeight * .2,
      volHidden: widget.volHidden,
      secondaryIndicators: widget.secondaryIndicators,
      mainIndicators: widget.mainIndicators,
    );
    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      baseDimension: baseDimension,
      sink: _mInfoWindowStream.sink,
      xFrontPadding: widget.xFrontPadding,
      datas: widget.datas,
      scaleX: _mScaleX,
      scrollX: _mScrollX,
      selectX: _mSelectX,
      interactionMode: _interactionMode,
      mainIndicators: widget.mainIndicators,
      volHidden: widget.volHidden,
      secondaryIndicators: widget.secondaryIndicators,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      fixedLength: widget.fixedLength,
    );

    return GestureDetector(
      onTapUp: (details) {
        if (_interactionMode == InteractionMode.crosshair) {
          // Dismiss the crosshair when tapping again.
          _interactionMode = InteractionMode.none;
          notifyChanged();
          return;
        }
        // Show the crosshair when tapping first
        _interactionMode = InteractionMode.crosshair;
        if (_mSelectX != details.localPosition.dx) {
          _mSelectX = details.localPosition.dx;
          notifyChanged();
        }
      },
      onScaleStart: (details) {
        _interactionMode = InteractionMode.none;
        _stopAnimation();
        _onDragChanged(true);
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          _interactionMode = InteractionMode.none;
          _isScale = true;
          _mScaleX = (_lastScale * details.scale).clamp(0.25, 2.5);
          notifyChanged();
        } else if (!_isScale) {
          _interactionMode = InteractionMode.none;
          // scrollX is in screen pixels now (zoom lives in the point width),
          // so the finger delta is applied 1:1.
          _mScrollX = (details.focalPointDelta.dx + _mScrollX)
              .clamp(0.0, ChartPainter.maxScrollX)
              .toDouble();
          notifyChanged();
        }
      },
      onScaleEnd: (details) {
        if (_isScale) {
          _lastScale = _mScaleX;
          _isScale = false;
        } else {
          _onFling(details.velocity.pixelsPerSecond.dx);
        }
        _onDragChanged(false);
      },
      onLongPressStart: (details) {
        _interactionMode = InteractionMode.crosshair;
        if (_mSelectX != details.localPosition.dx) {
          _mSelectX = details.localPosition.dx;
          notifyChanged();
        }
      },
      onLongPressMoveUpdate: (details) {
        if (_mSelectX != details.localPosition.dx) {
          _mSelectX = details.localPosition.dx;
          notifyChanged();
        }
      },
      onLongPressEnd: (details) {},
      child: Stack(
        children: <Widget>[
          CustomPaint(
            size: Size(double.infinity, baseDimension.mDisplayHeight),
            painter: _painter,
          ),
          if (widget.detailBuilder != null) _buildInfoDialog()
        ],
      ),
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    // isDrag = isOnDrag;
    // if (widget.isOnDrag != null) {
    //   widget.isOnDrag!(isDrag);
    // }
  }

  void _onFling(double x) {
    _controller = AnimationController(duration: Duration(milliseconds: widget.flingTime), vsync: this);
    _aniX = null;
    _aniX = Tween<double>(begin: _mScrollX, end: x * widget.flingRatio + _mScrollX).animate(
      CurvedAnimation(parent: _controller!.view, curve: widget.flingCurve),
    );
    _aniX!.addListener(() {
      _mScrollX = _aniX!.value;
      if (_mScrollX <= 0) {
        _mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (_mScrollX >= ChartPainter.maxScrollX) {
        _mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    _aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: _mInfoWindowStream.stream,
      builder: (context, snapshot) {
        if (_interactionMode == InteractionMode.none ||
          widget.isLine == true ||
          !snapshot.hasData ||
          snapshot.data?.kLineEntity == null
        ) {
          return const SizedBox();
        }
        KLineEntity entity = snapshot.data!.kLineEntity;
        if (snapshot.data!.isLeft) {
          return Positioned(
            left: 10.0,
            child: widget.detailBuilder!.call(entity),
          );
        }
        return Positioned(
          right: 10.0,
          child: widget.detailBuilder!.call(entity),
        );
      },
    );
  }
}
