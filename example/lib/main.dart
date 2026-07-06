import 'package:example/examples/depth_example.dart';
import 'package:example/examples/kline_example.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
        // appBarTheme: const AppBarThemeData(
        //   surfaceTintColor: Colors.transparent,
        //   backgroundColor: Colors.white,
        //   iconTheme: IconThemeData(
        //     size: 22,
        //   ),
        // ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Examples'),),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
        children: [
          _buildExampleItem(
            icon: 'assets/icons/candle.svg',
            title: 'KLine chart',
            onPressed: () async {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => const KlineExample()),
              );
            },
          ),
          _buildExampleItem(
            icon: 'assets/icons/depth.svg',
            title: 'Depth chart',
            onPressed: () async {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => DepthExample()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem({
    required String icon,
    required String title,
    required AsyncCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCDCDC), width: 1.0),
        ),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16.0,
          children: [
            SvgPicture.asset(
              icon,
              height: 30,
            ),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          ],
        ),
      ),
    );
  }
}
