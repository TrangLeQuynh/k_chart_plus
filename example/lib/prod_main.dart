import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_chart/flutter_k_chart.dart';
import 'package:messagepack/messagepack.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Dio dioService = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    responseType: ResponseType.json,
    contentType: ContentType.json.toString(),
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

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

  bool _volHidden = false;
  MainState _mainState = MainState.MA;
  final List<SecondaryState> _secondaryStateLi = [SecondaryState.KDJ];
  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors();

  ///socket
  WebSocketChannel? wsChannel;
  StreamSubscription? _listen;
  Timer? timer;

  ///setting
  String symbol = 'btcusdt';
  String resolutionType = 'M15';
  int resolutionTime = 15;

  List<KLineEntity> _entityList = [];
  bool showLoading = true;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      wsChannel?.sink.add('pong');
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getCandleHistory();
      _initSocket();

    });
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _unsubscribeCandleTopic();
    _listen?.cancel();
    wsChannel?.sink.close();
    wsChannel = null;
    timer?.cancel();
    super.dispose();
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
              _entityList,
              chartStyle,
              chartColors,
              mBaseHeight: 360,
              isTrendLine: false,
              onSecondaryTap: () {
                print('Secondary Tap');
              },
              mainState: _mainState,
              volHidden: _volHidden,
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
          const SizedBox(height: 30),
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
          bool isActive = _secondaryStateLi.contains(e);
          return _buildButton(
            context: context,
            title: e.name,
            isActive: _secondaryStateLi.contains(e),
            onPress: () {
              if (isActive) {
                _secondaryStateLi.remove(e);
              } else {
                _secondaryStateLi.add(e);
              }
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

  ///candle history
  Future<List<KLineEntity>> _getHistoryCandle() async {
    String url = 'https://broker.bankofbit.io/api/v1/market/history-candle';
    DateTime toDate = DateTime.now();
    DateTime fromDate = toDate.subtract(Duration(minutes: resolutionTime * 1000));
    Map<String, dynamic> queryParams = {
      'pair' : symbol,
      'from' : fromDate.millisecondsSinceEpoch.toString(),
      'to' : toDate.millisecondsSinceEpoch.toString(),
      'type' : resolutionType,
    };
    try {
      final response = await dioService.get(
        url,
        queryParameters: queryParams,
      );
      List<dynamic>? data = response.data['data'];
      List<KLineEntity> dataLi = List.from(data ?? []).map((json) {
        json ??= {};
        return KLineEntity.fromCustom(
          open: (json['open'] ?? 0).toDouble(),
          close: (json['close'] ?? 0).toDouble(),
          time: json['time'],
          high: (json['high'] ?? 0).toDouble(),
          low: (json['low'] ?? 0).toDouble(),
          vol: (json['volume'] ?? 0).toDouble(),
          amount: (json['volume'] ?? 0).toDouble(),
          // ratio: json['ratio'],
          // change: json['change'],
        );
      }).toList();
      return dataLi;
    } catch (e) {
      debugPrint("History Exception: ${e.toString()}");
      return <KLineEntity>[];
    }
  }

  Future<void> _getCandleHistory() async {
    _entityList = await _getHistoryCandle();
    showLoading = false;
    setState(() { });
  }

  Future<void> _initSocket() async {
    final Uri wssUrl = Uri.parse('wss://mav.timebird.exchange/m');
    try {
      wsChannel = WebSocketChannel.connect(wssUrl);
      listenSocket();
      _subscribeCandleTopic();
    } catch(e) {
      debugPrint('WebSocketChannel Exception: ${e.toString()}');
    }
  }

  Future<void> listenSocket() async {
    ///listen socket
    _listen = wsChannel?.stream.listen((message) {
      try {
        Unpacker unpacker = Unpacker(message as Uint8List);
        int msgType = unpacker.unpackInt() ?? -1;
        switch(msgType) {
          case 0: // candle
            Map<String, dynamic> data = {
              'time' : unpacker.unpackInt() ?? 0,
              'open' : unpacker.unpackDouble(),
              'high' : unpacker.unpackDouble(),
              'low' : unpacker.unpackDouble(),
              'close' : unpacker.unpackDouble(),
              'vol' : unpacker.unpackDouble(),
              'symbol' : unpacker.unpackString(),
              'type' : unpacker.unpackString()
            };
            data['amount'] = data['vol'];
            KLineEntity entity = KLineEntity.fromJson(data);

            ///add data
            if (_entityList.isEmpty) return;
            num lastTime = _entityList.last.time ?? 0;
            num newTime = entity.time ?? 0;
            if (lastTime == newTime) {
              _entityList.last = entity;
              setState(() { });
            } else if (lastTime < newTime) {
              _entityList.add(entity);
              setState(() { });
            }
            break;
        }
      } catch(e) {
        debugPrint("Exception Unpack: $e");
      }
    },
    onDone: () {},
    onError: (e) {},
    );
  }

  ///socket
  Future<void> _subscribeCandleTopic() async {
    Map<String, dynamic> data = <String, dynamic>{
      'cmd': 'subscribe',
      'topic': 'cloud.candle.$resolutionType.$symbol',
      'type': 'candle',
    };
    wsChannel?.sink.add(jsonEncode(data));
  }

  Future<void> _unsubscribeCandleTopic() async {
    Map<String, dynamic> data = <String, dynamic>{
      'cmd': 'unsubscribe',
      'topic': 'cloud.candle.$resolutionType.$symbol',
      'type': 'candle',
    };
    wsChannel?.sink.add(jsonEncode(data));
  }
}
