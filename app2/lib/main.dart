import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App2',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
      home: const DateListPage(),
    );
  }
}

class DateListPage extends StatefulWidget {
  const DateListPage({super.key});

  @override
  State<DateListPage> createState() => _DateListPageState();
}

class _DateListPageState extends State<DateListPage> {
  final AppLinks _appLinks = AppLinks();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Uri>? _linkSub;
  bool _launchedFromDeepLink = false;

  // itemExtent を固定することでインデックスからオフセットを正確に計算できる
  static const double _itemExtent = 57.0; // ListTile(56) + Divider(1)

  late final List<String> _dates;

  @override
  void initState() {
    super.initState();
    _dates = _buildAllDates();
    _initDeepLink();
  }

  /// 2026年全日付（1/1〜12/31）を生成する
  List<String> _buildAllDates() {
    final List<String> dates = <String>[];
    DateTime date = DateTime(2026);
    final DateTime end = DateTime(2026, 12, 31);
    while (!date.isAfter(end)) {
      dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      date = date.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _initDeepLink() async {
    // アプリが終了状態からDeep Linkで起動された場合
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      // Widgetのビルドが完了してからスクロール・ダイアログを表示する
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUri(initialUri);
      });
    } else {
      // 個別起動時は本日の日付までスクロール
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToToday();
      });
    }

    // アプリが起動中にDeep Linkを受信した場合
    // getInitialLink() と同じURIがStreamにも流れてきた場合は二重処理を防ぐ
    _linkSub = _appLinks.uriLinkStream.listen((Uri uri) {
      if (uri.toString() == initialUri?.toString()) {
        return;
      }
      _handleUri(uri);
    });
  }

  /// app2://date/{date} からパスの最初のセグメントを取り出す
  void _handleUri(Uri uri) {
    final List<String> segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      setState(() {
        _launchedFromDeepLink = true;
      });
      final String date = segments.first;
      _scrollToDate(date);
      _showDateDialog(date);
    }
  }

  /// 本日の日付までスクロールする（個別起動時）
  void _scrollToToday() {
    final DateTime now = DateTime.now();
    final String today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _scrollToDate(today);
  }

  /// 指定した日付の位置までリストをスクロールする
  void _scrollToDate(String date) {
    final int index = _dates.indexOf(date);
    if (index < 0) {
      return;
    }
    _scrollController.animateTo(
      index * _itemExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// 日付ダイアログを表示する（通常タップ・Deep Link共通）
  void _showDateDialog(String date) {
    // ignore: inference_failure_on_function_invocation
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('選択された日付'),
        content: Text(date, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる'))],
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App2 - 2026年'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          if (_launchedFromDeepLink)
            IconButton(icon: const Icon(Icons.close), tooltip: 'App1に戻る', onPressed: () => SystemNavigator.pop()),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _dates.length,
        itemExtent: _itemExtent,
        itemBuilder: (BuildContext context, int index) {
          final String date = _dates[index];
          return DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1F000000))),
            ),
            child: ListTile(title: Text(date), onTap: () => _showDateDialog(date)),
          );
        },
      ),
    );
  }
}
