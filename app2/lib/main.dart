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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
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
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  bool _launchedFromDeepLink = false;

  List<String> get februaryDates {
    return List.generate(28, (i) {
      final day = i + 1;
      return '2026-02-${day.toString().padLeft(2, '0')}';
    });
  }

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  Future<void> _initDeepLink() async {
    // アプリが終了状態からDeep Linkで起動された場合
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      // Widgetのビルドが完了してからダイアログを表示する
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUri(initialUri);
      });
    }

    // アプリが起動中にDeep Linkを受信した場合
    // getInitialLink() と同じURIがStreamにも流れてきた場合は二重処理を防ぐ
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.toString() == initialUri?.toString()) return;
      _handleUri(uri);
    });
  }

  /// app2://date/{date} からパスの最初のセグメントを取り出す
  void _handleUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      setState(() {
        _launchedFromDeepLink = true;
      });
      _showDateDialog(segments.first);
    }
  }

  /// 日付ダイアログを表示する（通常タップ・Deep Link共通）
  void _showDateDialog(String date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('選択された日付'),
        content: Text(
          date,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dates = februaryDates;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App2 - 2026年2月'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_launchedFromDeepLink)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'App1に戻る',
              onPressed: () => SystemNavigator.pop(),
            ),
        ],
      ),
      body: ListView.separated(
        itemCount: dates.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final date = dates[index];
          return ListTile(
            title: Text(date),
            onTap: () => _showDateDialog(date),
          );
        },
      ),
    );
  }
}
