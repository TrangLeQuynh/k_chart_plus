import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:http/http.dart' as http;
import '../widgets/popup_info_view.dart';

class KlineExample extends StatefulWidget {
  const KlineExample({super.key});

  @override
  State<KlineExample> createState() => _KlineExampleState();
}

class _KlineExampleState extends State<KlineExample> {
  List<KLineEntity>? datas;
  bool showLoading = true;
  bool _volHidden = false;
  final List<MainIndicator> _defaultMainIndicators = [
    MAIndicator(),
    EMAIndicator(),
    BOLLIndicator(),
    SARIndicator(),
  ];
  final List<SecondaryIndicator> _defaultSecondaryIndicators = [
    MACDIndicator(),
    KDJIndicator(),
    RSIIndicator(),
    WRIndicator(),
    CCIIndicator(),
  ];

  final List<MainIndicator> _mainIndicators = [];
  final List<SecondaryIndicator> _secondaryIndicators = [];

  KChartStyle chartStyle = const KChartStyle();
  KChartColors chartColors = const KChartColors();

  @override
  void initState() {
    super.initState();
    getData('1day');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kline chart')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildChart(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildIndicatorSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {

    return LayoutBuilder(
      builder: (c, constraint) {
        // scale secondary height when full screen
        double mSecondaryHeight = min(80, constraint.maxHeight/ (6 + _secondaryIndicators.length));
        return Stack(children: <Widget>[
          KChartWidget(
            datas,
            chartStyle,
            chartColors,
            mBaseHeight: constraint.maxHeight,
            mSecondaryHeight: mSecondaryHeight,
            isTrendLine: false,
            mainIndicators: _mainIndicators,
            volHidden: _volHidden,
            secondaryIndicators: _secondaryIndicators,
            fixedLength: 6,
            timeFormat: TimeFormat.YEAR_MONTH_DAY,
            detailBuilder: (entity) {
              return PopupInfoView(
                entity: entity,
                chartColors: chartColors,
                fixedLength: 2,
              );
            },
          ),
          if (showLoading)
            Container(
              width: double.infinity,
              height: 450,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ]);
      },
    );
  }

  Widget _buildIndicatorSettings() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12.0,
        children: [
          _buildItem(
            title: 'VOL',
            isActive: !_volHidden,
            onPressed: () async {
              _volHidden = !_volHidden;
              setState(() {});
            },
          ),
          ..._defaultMainIndicators.map((e) {
            bool isActive = _mainIndicators.contains(e);
            return _buildItem(
              title: e.shortName,
              isActive: isActive,
              onPressed: () async {
                if (isActive) {
                  _mainIndicators.remove(e);
                } else {
                  _mainIndicators.add(e);
                }
                setState(() {});
              },
            );
          }).toList(),
          const SizedBox(
            height: 12,
            child: VerticalDivider(),
          ),
          ..._defaultSecondaryIndicators.map((e) {
            bool isActive = _secondaryIndicators.contains(e);
            return _buildItem(
              title: e.shortName,
              isActive: isActive,
              onPressed: () async {
                if (isActive) {
                  _secondaryIndicators.remove(e);
                } else {
                  _secondaryIndicators.add(e);
                }
                setState(() {});
              },
            );
          }).toList(),

        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required bool isActive,
    required AsyncCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isActive ? null : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }

  void getData(String period) {
    // final Future<String> future = getChatDataFromInternet(period);
    final Future<String> future = getChatDataFromJson();
    future.then((String result) {
      solveChatData(result);
    }).catchError((_) {
      showLoading = false;
      setState(() {});
      debugPrint('### datas error $_');
    });
  }

  Future<String> getChatDataFromInternet(String? period) async {
    var url =
        'https://api.huobi.br.com/market/history/kline?period=${period ?? '1day'}&size=300&symbol=btcusdt';
    late String result;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      result = response.body;
    } else {
      debugPrint('Failed getting IP address');
    }
    return result;
  }

  Future<String> getChatDataFromJson() async {
    return rootBundle.loadString('assets/chatData.json');
  }

  void solveChatData(String result) {
    final Map parseJson = json.decode(result) as Map<dynamic, dynamic>;
    final list = parseJson['data'] as List<dynamic>;
    datas = list
        .map((item) => KLineEntity.fromJson(item as Map<String, dynamic>))
        .toList()
        .reversed
        .toList()
        .cast<KLineEntity>();
    DataUtil.calculateAll(
      datas!,
      _defaultMainIndicators,
      _defaultSecondaryIndicators,
    );
    showLoading = false;
    setState(() {});
  }
}
