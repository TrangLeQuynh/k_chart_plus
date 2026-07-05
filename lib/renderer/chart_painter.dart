import 'dart:async' show StreamSink;
import 'package:flutter/material.dart';
import 'package:k_chart_plus/extension/canvas_extension.dart';
import 'package:k_chart_plus/utils/number_util.dart';
import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'base_dimension.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer;
  Set<BaseChartRenderer> mSecondaryRendererList = {};
  StreamSink<InfoWindowEntity?> sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  final KChartColors chartColors;
  late Paint paintCross, selectPointPaint, selectorBorderPaint;
  late Paint nowPriceSelectorPaint, nowPriceSelectorBorderPaint, nowPriceLinePaint;
  final KChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  final BaseDimension baseDimension;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required this.sink,
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    required this.baseDimension,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainIndicators,
    volHidden,
    secondaryIndicators,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            baseDimension: baseDimension,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainIndicators: mainIndicators,
            volHidden: volHidden,
            secondaryIndicators: secondaryIndicators,
            xFrontPadding: xFrontPadding,
            isLine: isLine) {
    paintCross = Paint()
      ..color = this.chartColors.crossColor
      ..strokeWidth = this.chartStyle.crossWidth
      ..isAntiAlias = true;
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = this.chartStyle.borderWidth
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;

    nowPriceSelectorPaint = Paint()
      ..color = this.chartColors.bgColor
      ..isAntiAlias = true;
    nowPriceSelectorBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = this.chartStyle.borderWidth
      ..isAntiAlias = true;
    nowPriceLinePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    // if (datas != null && datas!.isNotEmpty) {
    //   var t = datas![0];
    //   fixedLength = NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    // }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainIndicators,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      mBottomPadding,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(
        mVolRect!,
        mVolMaxValue,
        mVolMinValue,
        mChildPadding,
        fixedLength,
        this.chartStyle,
        this.chartColors,
        scaleX: this.scaleX,
      );
    }
    mSecondaryRendererList.clear();
    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      mSecondaryRendererList.add(SecondaryRenderer(
        mSecondaryRectList[i].mRect,
        mSecondaryRectList[i].mMaxValue,
        mSecondaryRectList[i].mMinValue,
        mChildPadding,
        secondaryIndicators[i],
        fixedLength,
        chartStyle,
        chartColors,
        scaleX: scaleX,
      ));
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint()..color = chartColors.bgColor;
    Rect mainRect = Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(mainRect, mBgPaint);

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
        0,
        mVolRect!.top - mChildPadding,
        mVolRect!.width,
        mVolRect!.bottom,
      );
      canvas.drawRect(volRect, mBgPaint);
    }

    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      Rect? mSecondaryRect = mSecondaryRectList[i].mRect;
      Rect secondaryRect = Rect.fromLTRB(
        0,
        mSecondaryRect.top - mChildPadding,
        mSecondaryRect.width,
        mSecondaryRect.bottom,
      );
      canvas.drawRect(secondaryRect, mBgPaint);
    }
    canvas.drawRect(mDateRect, mBgPaint);
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRendererList.forEach((element) {
        element.drawGrid(canvas, mGridRows, mGridColumns);
      });
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    // Zoom is baked into the x math (mPointWidth is already scaled), so the
    // canvas only pans. Nothing drawn below gets stretched horizontally.
    canvas.translate(mTranslateX, 0.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);
      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRendererList.forEach((element) {
        element.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      });
    }

    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) && isTrendLine == false) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRendererList.forEach((element) {
      element.drawVerticalText(canvas, textStyle, mGridRows);
    });
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = mDateRect.top + (mBottomPadding - tp.height) / 2;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  /// draw the cross line. when user focus
  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(
      NumberUtil.formatFixed(point.close, fixedLength),
      chartColors.crossTextColor,
    );
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    double space = 4.0;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = space;
      RRect rect = RRect.fromLTRBR(
        x,
        y - r,
        x + textWidth + 2 * w1,
        y + r,
        Radius.circular(2.0),
      );
      canvas.drawRRect(rect, selectPointPaint);
      canvas.drawRRect(rect, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 2 * w1 - space;
      RRect rect = RRect.fromLTRBR(
        x,
        y - r,
        mWidth - space,
        y + r,
        Radius.circular(2.0),
      );
      canvas.drawRRect(rect, selectPointPaint);
      canvas.drawRRect(rect, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    }

    TextPainter dateTp = getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = mDateRect.top;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }

    RRect rectBox =  RRect.fromLTRBR(
      x - textWidth / 2 - w1,
      y,
      x + textWidth / 2 + w1,
      mDateRect.bottom,
      Radius.circular(2.0),
    );

    // double baseLine = textHeight / 2;
    canvas.drawRRect(
      rectBox,
      selectPointPaint,
    );
    canvas.drawRRect(
      rectBox,
      selectorBorderPaint,
    );

    dateTp.paint(
      canvas,
      Offset(
        x - textWidth / 2,
        mDateRect.top + (mDateRect.height - dateTp.height) / 2,
      ),
    );

    //Long press to display the details of this data
    sink.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //Long press to display the data in the press
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //Release to display the last data
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRendererList.forEach((element) {
      element.drawText(canvas, data, x);
    });
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //plot maxima and minima
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //draw right
      TextPainter tp = getTextPainter(
        "── " + (NumberUtil.formatFixed(mMainLowMinValue, fixedLength) ?? ''),
        chartColors.minColor,
      );
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
        (NumberUtil.formatFixed(mMainLowMinValue, fixedLength) ?? '') + " ──",
        chartColors.minColor,
      );
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //draw right
      TextPainter tp = getTextPainter(
        "── " + (NumberUtil.formatFixed(mMainHighMaxValue, fixedLength) ?? ''),
        chartColors.maxColor,
      );
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
        (NumberUtil.formatFixed(mMainHighMaxValue, fixedLength) ?? '') + " ──",
        chartColors.maxColor,
      );
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //view display area boundary value drawing
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    Color priceColor = value >= datas!.last.open
        ? this.chartColors.nowPriceUpColor
        : this.chartColors.nowPriceDnColor;

    nowPriceSelectorBorderPaint.color = priceColor;
    nowPriceLinePaint.color = priceColor;

    //first draw the horizontal line
    // Drawn outside the pan transform: plain screen coordinates.
    canvas.drawDashLine(
      Offset(0, y),
      Offset(-mTranslateX + mWidth, y),
      nowPriceLinePaint,
    );

    //repaint the background and text
    TextPainter tp = getTextPainter(
      NumberUtil.formatFixed(value, fixedLength) ?? '',
      priceColor,
    );

    double paddingX = 3, paddingY = 1.5;
    double space = 5.0;
    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        // offsetX = paddingX;
        offsetX = space;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width - paddingX * 2 - space;
        break;
    }

    double top = y - tp.height / 2;
    RRect rect = RRect.fromLTRBR(
      offsetX,
      top - paddingY,
      offsetX + tp.width + paddingX * 2,
      top + tp.height + paddingY * 2,
      Radius.circular(2.0),
    );
    canvas.drawRRect(
      rect,
      nowPriceSelectorPaint,
    );
    canvas.drawRRect(
      rect,
      nowPriceSelectorBorderPaint,
    );
    tp.paint(
      canvas,
      Offset(offsetX + paddingX, top),
    );
  }

  //For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    // Stored in data units (independent of the current zoom) so lines placed
    // at one zoom level keep tracking their candle after re-scaling.
    trendLineX = x / scaleX;

    double y = selectY;
    // getMainY(point.close);

    // K-line chart vertical line
    canvas.drawLine(
      Offset(x, mTopPadding),
      Offset(x, size.height),
      paintY,
    );
    Paint paintX = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-mTranslateX, y),
      Offset(-mTranslateX + mWidth, y),
      paintX,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 15.0, width: 15.0),
      paint,
    );
    if (lines.isNotEmpty) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        // p*.dx is stored in data units — scale to the current zoom.
        var p1 = Offset(element.p1.dx * scaleX, a);
        var p2 = Offset(element.p2.dx * scaleX, b);
        canvas.drawLine(
          p1,
          element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
          Paint()
            ..color = Colors.yellow
            ..strokeWidth = 2);
      });
    }
  }

  ///draw cross lines
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    double x = getX(index);
    double y = getMainY(point.close);

    // K-line chart vertical line
    canvas.drawDashLine(
      Offset(x, 0),
      Offset(x, size.height),
      paintCross,
    );

    // K-line chart horizontal line
    canvas.drawDashLine(
      Offset(-mTranslateX, y),
      Offset(-mTranslateX + mWidth, y),
      paintCross,
    );

    // The canvas is no longer scaled, so a plain circle stays a circle at
    // any zoom level.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), height: 4.0, width: 4.0),
      paintCross,
    );
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
    DateTime.fromMillisecondsSinceEpoch(date ?? DateTime.now().millisecondsSinceEpoch),
    mFormats,
  );

  double getMainY(double y) => mMainRenderer.getY(y);

  /// Whether the point is in the SecondaryRect
  // bool isInSecondaryRect(Offset point) {
  //   // return mSecondaryRect.contains(point) == true);
  //   return false;
  // }

  /// Whether the point is in MainRect
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}
