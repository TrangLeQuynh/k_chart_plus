import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:k_chart_plus/utils/number_util.dart';

class PopupInfoView extends StatelessWidget {
  final KLineEntity entity;
  final ChartColors chartColors;
  final int fixedLength;

  const PopupInfoView({
    Key? key,
    required this.entity,
    required this.chartColors,
    required this.fixedLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chartColors.selectFillColor,
        border: Border.all(color: chartColors.selectBorderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    double upDown = entity.change ?? entity.close - entity.open;
    double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
    final double? entityAmount = entity.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem('Date', getDate(entity.time)),
        _buildItem(
          'Open',
          NumberUtil.formatNumber(entity.open, fixedLength) ?? '--',
        ),
        _buildItem(
          'High',
          NumberUtil.formatNumber(entity.high, fixedLength) ?? '--',
        ),
        _buildItem(
          'Low',
          NumberUtil.formatNumber(entity.low, fixedLength) ?? '--',
        ),
        _buildItem(
          'Close',
          NumberUtil.formatNumber(entity.close, fixedLength) ?? '--',
        ),
        _buildColorItem(
          'Change',
          NumberUtil.formatNumber(upDown, fixedLength) ?? '--',
          upDown > 0,
        ),
        _buildColorItem(
          'Change%',
          '${upDownPercent.toStringAsFixed(2)}%',
          upDownPercent > 0,
        ),
        _buildItem(
          'Volume',
          NumberUtil.format(entity.vol),
        ),
        if (entityAmount != null) _buildItem(
          'Amount',
          entityAmount.toInt().toString(),
        ),
      ],
    );
  }

  Widget _buildColorItem(String label, String info, bool isUp) {
    if (isUp) {
      return _buildItem(label, '+$info',
          textColor: chartColors.infoWindowUpColor);
    }
    return _buildItem(label, info, textColor: chartColors.infoWindowDnColor);
  }

  Widget _buildItem(String label, String info, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: chartColors.infoWindowTitleColor,
              fontSize: 10.0,
            ),
          ),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                  color: textColor ?? chartColors.infoWindowNormalColor,
                  fontSize: 10.0),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String getDate(int? date) => dateFormat(
    DateTime.fromMillisecondsSinceEpoch(date ?? DateTime.now().millisecondsSinceEpoch),
    TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
  );
}
