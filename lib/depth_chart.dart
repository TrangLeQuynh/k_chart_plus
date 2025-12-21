import 'dart:math';
import 'package:flutter/material.dart';
import 'package:k_chart_plus/chart_translations.dart';
import 'package:k_chart_plus/extension/canvas_extension.dart';
import 'package:k_chart_plus/styles/depth_chart_style.dart';
import 'package:k_chart_plus/utils/number_util.dart';
import 'entity/depth_entity.dart';

class DepthChart extends StatefulWidget {
  final List<DepthEntity> bids, asks;
  final int baseUnit;
  final int quoteUnit;
  final Offset offset;
  final DepthChartColors chartColors;
  final DepthChartStyle chartStyle;
  final DepthChartTranslations chartTranslations;

  DepthChart(
    this.bids,
    this.asks,
    this.chartColors, {
    this.baseUnit = 2,
    this.quoteUnit = 6,
    this.offset = const Offset(8, 0),
    this.chartTranslations = const DepthChartTranslations(),
    this.chartStyle = const DepthChartStyle(),
  });

  @override
  _DepthChartState createState() => _DepthChartState();
}

class _DepthChartState extends State<DepthChart> {
  Offset? pressOffset;
  bool isLongPress = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        pressOffset = details.localPosition;
        isLongPress = true;
        setState(() {});
      },
      onLongPressMoveUpdate: (details) {
        pressOffset = details.localPosition;
        isLongPress = true;
        setState(() {});
      },
      onLongPressEnd: (details) {
        pressOffset = null;
        isLongPress = false;
        setState(() {});
      },
      child: CustomPaint(
        size: Size(double.infinity, double.infinity),
        painter: DepthChartPainter(
          widget.bids,
          widget.asks,
          pressOffset,
          isLongPress,
          widget.baseUnit,
          widget.quoteUnit,
          widget.chartColors,
          widget.chartStyle,
          widget.offset,
          widget.chartTranslations,
        ),
      ),
    );
  }
}

class DepthChartPainter extends CustomPainter {
  //Buy//Sell
  List<DepthEntity>? mBuyData, mSellData;
  Offset? pressOffset;
  bool isLongPress;
  int baseUnit;
  int quoteUnit;
  DepthChartColors chartColors;
  DepthChartStyle chartStyle;

  double mPaddingBottom = 32.0;
  double mWidth = 0.0, mDrawHeight = 0.0, mDrawWidth = 0.0;
  double? mBuyPointWidth, mSellPointWidth;

  Offset offset;
  DepthChartTranslations chartTranslations;

  //最大的委托量
  //Maximum commission amount
  double? mMaxVolume, mMultiple;

  //右侧绘制个数
  int mLineCount = 4;

  Path? mBuyPath, mSellPath;

  //买卖出区域边线绘制画笔  //买卖出取悦绘制画笔
  Paint? mBuyLinePaint,
    mSellLinePaint,
    mBuyPathPaint,
    mSellPathPaint,
    mBarrierPathPaint,
    selectPaint,
    selectBorderPaint,
    crossPaint;

  DepthChartPainter(
    this.mBuyData,
    this.mSellData,
    this.pressOffset,
    this.isLongPress,
    this.baseUnit,
    this.quoteUnit,
    this.chartColors,
    this.chartStyle,
    this.offset,
    this.chartTranslations,
  ) {
    mBuyLinePaint ??= Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.upColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = chartStyle.lineWidth;
    mSellLinePaint ??= Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.dnColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = chartStyle.lineWidth;

    mBuyPathPaint ??= Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.upFillPathColor;
    mSellPathPaint ??= Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.dnFillPathColor;
    mBarrierPathPaint ??= Paint()
      ..isAntiAlias = true
      ..color = this.chartColors.barrierColor;
    crossPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = this.chartStyle.crossWidth
      ..color = this.chartColors.crossColor;

    mBuyPath ??= Path();
    mSellPath ??= Path();
    init();
  }

  void init() {
    if (mBuyData == null ||
      mSellData == null ||
      mBuyData!.isEmpty ||
      mSellData!.isEmpty) return;
    mMaxVolume = max(mBuyData!.first.vol, mSellData!.last.vol);
    mMaxVolume = mMaxVolume! * 1.08;
    mMultiple = mMaxVolume! / mLineCount;

    selectPaint = Paint()
      ..isAntiAlias = true
      ..color = chartColors.selectFillColor;
    selectBorderPaint = Paint()
      ..isAntiAlias = true
      ..color = chartColors.selectBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = chartStyle.strokeWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (mBuyData == null ||
        mSellData == null ||
        mBuyData!.isEmpty ||
        mSellData!.isEmpty) return;
    mWidth = size.width;
    mDrawWidth = mWidth / 2;
    mDrawHeight = size.height - mPaddingBottom;
    // canvas.drawColor(Colors.green, BlendMode.srcATop);
    canvas.save();
    //绘制买入区域
    drawBuy(canvas);
    //绘制卖出区域
    drawSell(canvas);

    //绘制界面相关文案
    drawText(canvas);
    canvas.restore();
  }

  void drawBuy(Canvas canvas) {
    mBuyPointWidth = (mDrawWidth / (mBuyData!.length - 1 == 0 ? 1 : mBuyData!.length - 1));
    mBuyPath!.reset();
    double x;
    double y;
    for (int i = 0; i < mBuyData!.length; i++) {
      if (i == 0) {
        mBuyPath!.moveTo(0, getY(mBuyData![0].vol));
      }
      x = mBuyPointWidth! * i;
      y = getY(mBuyData![i].vol);
      if (i >= 1) {
        canvas.drawLine(
          Offset(mBuyPointWidth! * (i - 1), getY(mBuyData![i - 1].vol)),
          Offset(x, y),
          mBuyLinePaint!,
        );
      }
      if (i != mBuyData!.length - 1) {
        mBuyPath!.quadraticBezierTo(x, y, mBuyPointWidth! * (i + 1), getY(mBuyData![i + 1].vol));
      } else {
        if (i == 0) {
          mBuyPath!.lineTo(mDrawWidth, y);
          mBuyPath!.lineTo(mDrawWidth, mDrawHeight);
          mBuyPath!.lineTo(0, mDrawHeight);
        } else {
          mBuyPath!.quadraticBezierTo(x, y, x, mDrawHeight);
          mBuyPath!.quadraticBezierTo(x, mDrawHeight, 0, mDrawHeight);
        }
        mBuyPath!.close();
      }
    }
    canvas.drawPath(mBuyPath!, mBuyPathPaint!);
  }

  void drawSell(Canvas canvas) {
    mSellPointWidth = (mDrawWidth / (mSellData!.length - 1 == 0 ? 1 : mSellData!.length - 1));
    mSellPath!.reset();
    double x;
    double y;
    for (int i = 0; i < mSellData!.length; i++) {
      if (i == 0) {
        mSellPath!.moveTo(mDrawWidth, getY(mSellData![0].vol));
      }
      x = (mSellPointWidth! * i) + mDrawWidth;
      y = getY(mSellData![i].vol);
      if (i >= 1) {
        canvas.drawLine(
          Offset((mSellPointWidth! * (i - 1)) + mDrawWidth, getY(mSellData![i - 1].vol)),
          Offset(x, y),
          mSellLinePaint!,
        );
      }
      if (i != mSellData!.length - 1) {
        mSellPath!.quadraticBezierTo(
          x,
          y,
          (mSellPointWidth! * (i + 1)) + mDrawWidth,
          getY(mSellData![i + 1].vol),
        );
      } else {
        if (i == 0) {
          mSellPath!.lineTo(mWidth, y);
          mSellPath!.lineTo(mWidth, mDrawHeight);
          mSellPath!.lineTo(mDrawWidth, mDrawHeight);
        } else {
          mSellPath!.quadraticBezierTo(mWidth, y, x, mDrawHeight);
          mSellPath!.quadraticBezierTo(x, mDrawHeight, mDrawWidth, mDrawHeight);
        }
        mSellPath!.close();
      }
    }
    canvas.drawPath(mSellPath!, mSellPathPaint!);
  }

  // int? mLastPosition;

  void drawText(Canvas canvas) {
    double value;
    String str;
    for (int j = 0; j < mLineCount; j++) {
      value = mMaxVolume! - mMultiple! * j;
      str = NumberUtil.formatCompact(value, baseUnit);
      var tp = getTextPainter(str);
      tp.layout();
      tp.paint(
        canvas,
        Offset(mWidth - tp.width, mDrawHeight / mLineCount * j + tp.height / 2),
      );
    }

    var startText = NumberUtil.formatFixed(mBuyData!.first.price, quoteUnit) ?? '';
    TextPainter startTP = getTextPainter(startText);
    startTP.layout();
    startTP.paint(canvas, Offset(0, getBottomTextY(startTP.height)));

    double centerPrice = (mBuyData!.last.price + mSellData!.first.price) / 2;

    var center = NumberUtil.formatFixed(centerPrice, quoteUnit) ?? '';
    TextPainter centerTP = getTextPainter(center);
    centerTP.layout();
    centerTP.paint(
      canvas,
      Offset(mDrawWidth - centerTP.width / 2, getBottomTextY(centerTP.height)),
    );

    var endText = NumberUtil.formatFixed(mSellData!.last.price, quoteUnit) ?? '';
    TextPainter endTP = getTextPainter(endText);
    endTP.layout();
    endTP.paint(
      canvas,
      Offset(mWidth - endTP.width, getBottomTextY(endTP.height)),
    );

    var leftHalfText = NumberUtil.formatFixed((mBuyData!.first.price + centerPrice) / 2, quoteUnit) ?? '';
    TextPainter leftHalfTP = getTextPainter(leftHalfText);
    leftHalfTP.layout();
    leftHalfTP.paint(
      canvas,
      Offset((mDrawWidth - leftHalfTP.width) / 2, getBottomTextY(leftHalfTP.height)),
    );

    var rightHalfText = NumberUtil.formatFixed((mSellData!.last.price + centerPrice) / 2, quoteUnit) ?? '';
    TextPainter rightHalfTP = getTextPainter(rightHalfText);
    rightHalfTP.layout();
    rightHalfTP.paint(
      canvas,
      Offset((mDrawWidth + mWidth - rightHalfTP.width) / 2, getBottomTextY(rightHalfTP.height)),
    );

    if (isLongPress == true) {
      if (pressOffset!.dx <= mDrawWidth) {
        int index = _indexOfTranslateX(
          pressOffset!.dx,
          0,
          mBuyData!.length - 1,
          getBuyX,
        );
        drawLeftSelectView(canvas, index); // buy

        int indexRight = mBuyData!.length - index - 1;
        if (indexRight < mSellData!.length) {
          drawRightSelectView(canvas, indexRight);
        }
      } else {
        int index = _indexOfTranslateX(
          pressOffset!.dx,
          0,
          mSellData!.length - 1,
          getSellX,
        );
        drawRightSelectView(canvas, index); // sell
        int indexLeft = mBuyData!.length - index - 1;
        if (indexLeft >= 0 && indexLeft < mBuyData!.length) {
          drawLeftSelectView(canvas, indexLeft);
        }
      }
    }
  }

  void drawLeftSelectView(Canvas canvas, int index) {
    DepthEntity entity = mBuyData![index];
    double dx = getBuyX(index);
    double dy = getY(entity.vol);

    // draw overlay barrier model
    canvas.drawRect(
      Rect.fromLTRB(0, 0, dx, mDrawHeight),
      mBarrierPathPaint!,
    );

    /// draw cross line
    canvas.drawDashLine(
      Offset(dx, 0),
      Offset(dx, mDrawHeight),
      crossPaint ?? Paint(),
    );

    /// draw dot
    canvas.drawCircle(
      Offset(dx, dy),
      chartStyle.dotRadius * .6,
      mBuyLinePaint!
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(dx, dy),
      chartStyle.dotRadius,
      mBuyLinePaint!
        ..style = PaintingStyle.stroke,
    );

    ///draw popup info
    ///
    _PopupPainter popupPainter = _PopupPainter(
      translations: this.chartTranslations,
      chartColors: this.chartColors,
      chartStyle: this.chartStyle,
      price: NumberUtil.format(entity.price, quoteUnit) ?? '',
      amount: NumberUtil.formatCompact(entity.vol, baseUnit),
    );

    dx = dx < mWidth * 0.25 ? dx + offset.dx : dx - offset.dx - popupPainter.width;
    // dy = dy < mDrawHeight / 2
    //   ? dy + offset.dy
    //   : dy - offset.dy - popupPainter.height;
    dy = (dy - popupPainter.height / 2).clamp(offset.dy, mDrawHeight - popupPainter.height - offset.dy);

    Rect rect = Rect.fromLTWH(dx, dy, popupPainter.width, popupPainter.height);
    RRect boxRect = RRect.fromRectAndRadius(rect, Radius.circular(chartStyle.radius));

    canvas.drawRRect(boxRect, selectPaint!);
    canvas.drawRRect(boxRect, selectBorderPaint!);
    popupPainter.paint(canvas, rect.topLeft);
  }

  void drawRightSelectView(Canvas canvas, int index) {
    DepthEntity entity = mSellData![index];
    double dx = getSellX(index);
    double dy = getY(entity.vol);

    /// draw overlay barrier model
    canvas.drawRect(
      Rect.fromLTRB(dx, 0, mWidth, mDrawHeight),
      mBarrierPathPaint!,
    );

    /// draw cross line
    canvas.drawDashLine(
      Offset(dx, 0),
      Offset(dx, mDrawHeight),
      crossPaint ?? Paint(),
    );

    /// draw dot
    canvas.drawCircle(
      Offset(dx, dy),
      chartStyle.dotRadius * .6,
      mSellLinePaint!..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(dx, dy), chartStyle.dotRadius,
      mSellLinePaint!..style = PaintingStyle.stroke,
    );

    ///draw popup info
    ///
    _PopupPainter popupPainter = _PopupPainter(
      translations: this.chartTranslations,
      chartColors: this.chartColors,
      chartStyle: this.chartStyle,
      price: NumberUtil.format(entity.price, quoteUnit) ?? '',
      amount: NumberUtil.formatCompact(entity.vol, baseUnit),
    );

    dx = dx < mWidth * 0.75 ? dx + offset.dx : dx - offset.dx - popupPainter.width;
    // dx = dx + offset.dx;
    // dy = dy < mDrawHeight / 2
    //   ? dy + offset.dy
    //   : dy - offset.dy - popupPainter.height;
    dy = (dy - popupPainter.height / 2).clamp(offset.dy, mDrawHeight - popupPainter.height - offset.dy);

    Rect rect = Rect.fromLTWH(dx, dy, popupPainter.width, popupPainter.height);
    RRect boxRect = RRect.fromRectAndRadius(rect, Radius.circular(chartStyle.radius));

    canvas.drawRRect(boxRect, selectPaint!);
    canvas.drawRRect(boxRect, selectBorderPaint!);
    popupPainter.paint(canvas, rect.topLeft);
  }

  ///Binary search for current value: index
  int _indexOfTranslateX(double translateX, int start, int end, Function getX) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
        ? start
        : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid, getX);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end, getX);
    } else {
      return mid;
    }
  }

  double getBuyX(int position) => position * mBuyPointWidth!;

  double getSellX(int position) => position * mSellPointWidth! + mDrawWidth;

  getTextPainter(String text) => TextPainter(
    text: TextSpan(
      text: "$text",
      style: TextStyle(color: chartColors.defaultTextColor, fontSize: 10),
    ),
    textDirection: TextDirection.ltr,
  );

  double getBottomTextY(double textHeight) => (mPaddingBottom - textHeight) / 2 + mDrawHeight;

  double getY(double volume) => mDrawHeight - (mDrawHeight) * volume / mMaxVolume!;

  @override
  bool shouldRepaint(DepthChartPainter oldDelegate) {
//    return oldDelegate.mBuyData != mBuyData ||
//        oldDelegate.mSellData != mSellData ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.pressOffset != pressOffset;
    return true;
  }
}

class _PopupPainter {
  final DepthChartColors chartColors;
  final DepthChartStyle chartStyle;

  late final TextPainter annotationsPaint;
  late final TextPainter pricePaint;
  late final TextPainter amountPaint;

  ///getter
  double get width => max(pricePaint.width, amountPaint.width) + 2 * chartStyle.padding;
  double get height => pricePaint.height + amountPaint.height + chartStyle.space + 2 * chartStyle.padding;

  _PopupPainter({
    required DepthChartTranslations translations,
    required this.chartColors,
    required this.chartStyle,
    required String price,
    required String amount,
  }) {
    this.pricePaint = _getTextPainter(translations.price, price);
    this.amountPaint = _getTextPainter(translations.amount, amount);
    this.pricePaint.layout();
    this.amountPaint.layout();
  }

  void paint(Canvas canvas, Offset offset) {
    pricePaint.paint(
      canvas,
      offset + Offset(chartStyle.padding, chartStyle.padding),
    );
    amountPaint.paint(
      canvas,
      offset + Offset(chartStyle.padding, pricePaint.height + chartStyle.space + chartStyle.padding),
    );
  }

  TextPainter _getTextPainter(String label, String content) {
    return TextPainter(
      text: TextSpan(
        text: '$label $content',
        style: TextStyle(
          color: this.chartColors.annotationColor,
          fontSize: 9,
        ),
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
    );
  }
}
