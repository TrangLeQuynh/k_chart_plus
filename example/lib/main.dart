import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:k_chart/flutter_k_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<KLineEntity>? datas;
  bool showLoading = true;
  bool _volHidden = false;
  MainState _mainState = MainState.MA;
  SecondaryState _secondaryState = SecondaryState.MACD;
  // final Set<SecondaryState> _secondaryStateLi = <SecondaryState>{};
  List<DepthEntity>? _bids, _asks;

  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors();

  @override
  void initState() {
    super.initState();
    getData('1day');
    rootBundle.loadString('assets/depth.json').then((result) {
      final parseJson = json.decode(result);
      final tick = parseJson['tick'] as Map<String, dynamic>;
      final List<DepthEntity> bids = (tick['bids'] as List<dynamic>)
          .map<DepthEntity>((item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      final List<DepthEntity> asks = (tick['asks'] as List<dynamic>)
          .map<DepthEntity>((item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      initDepth(bids, asks);
    });
  }

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;
    _bids = [];
    _asks = [];
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    bids.reversed.forEach((item) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    });

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    asks.forEach((item) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          const SafeArea(bottom: false, child: SizedBox(height: 10)),
          Stack(children: <Widget>[
            KChartWidget(
              datas,
              chartStyle,
              chartColors,
              mBaseHeight: 360,
              isTrendLine: false,
              onSecondaryTap: () {
                print('Secondary Tap');
              },
              mainState: _mainState,
              volHidden: _volHidden,
              // secondaryStateLi: _secondaryStateLi.toSet(),
              secondaryState: SecondaryState.MACD,
              fixedLength: 2,
              timeFormat: TimeFormat.YEAR_MONTH_DAY,
            ),
            if (showLoading) Container(
              width: double.infinity,
              height: 450,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ]),
          _buildTitle(context, 'VOL'),
          buildVolButton(),
          _buildTitle(context, 'Main State'),
          buildMainButtons(),
          _buildTitle(context, 'Secondary State'),
          buildSecondButtons(),
          // const SizedBox(height: 30),
          // if (_bids != null && _asks != null)
          //   Container(
          //     color: Colors.white,
          //     height: 300,
          //     width: double.infinity,
          //     child: DepthChart(_bids!, _asks!, chartColors),
          //   )
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 15),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          // color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildVolButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildButton(
            context: context,
            title: 'VOL',
            isActive: !_volHidden,
            onPress: () {
              _volHidden = !_volHidden;
              setState(() {});
            }
        ),
      ),
    );
  }

  Widget buildMainButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        children: MainState.values.map((e) {
          return _buildButton(
            context: context,
            title: e.name,
            isActive: _mainState == e,
            onPress: () => _mainState = e,
          );
        }).toList(),
      ),
    );
  }

  Widget buildSecondButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 5,
        children: SecondaryState.values.map((e) {
          if (e == SecondaryState.NONE) return SizedBox();
          bool isActive = _secondaryState == e;
          return _buildButton(
            context: context,
            title: e.name,
            isActive: isActive,
            onPress: () {
              if (isActive) {
                _secondaryState = SecondaryState.NONE;
              } else {
                _secondaryState = e;
              }
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String title,
    required isActive,
    required Function onPress,
  }) {
    late Color? bgColor, txtColor;
    if (isActive) {
      bgColor = Theme.of(context).primaryColor.withOpacity(.15);
      txtColor = Theme.of(context).primaryColor;
    } else {
      bgColor = Colors.transparent;
      txtColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.75);
    }
    return InkWell(
      onTap: () {
        onPress();
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: txtColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void getData(String period) {
    final Future<String> future = getChatDataFromInternet(period);
    //final Future<String> future = getChatDataFromJson();
    future.then((String result) {
      solveChatData(result);
    }).catchError((_) {
      showLoading = false;
      setState(() {});
      print('### datas error $_');
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
      print('Failed getting IP address');
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
    DataUtil.calculate(datas!);
    showLoading = false;
    setState(() {});
  }
}
