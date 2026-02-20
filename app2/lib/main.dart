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
      home: const DeepLinkPage(),
    );
  }
}

class DeepLinkPage extends StatefulWidget {
  const DeepLinkPage({super.key});

  @override
  State<DeepLinkPage> createState() => _DeepLinkPageState();
}

class _DeepLinkPageState extends State<DeepLinkPage> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  // 受信した日付を保持
  String? _receivedDate;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  Future<void> _initDeepLink() async {
    // アプリが終了状態から起動された場合の初期リンク取得
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // アプリが起動中にDeep Linkを受信した場合
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  /// app2://date/{date} からパスの最初のセグメントを取り出す
  void _handleUri(Uri uri) {
    // パス: /2026-02-01 → pathSegments[0] = '2026-02-01'
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      setState(() {
        _receivedDate = segments.first;
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App2（Deep Link受信）'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // 右上のXボタン：タップするとApp2を閉じてApp1に戻る
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'App1に戻る',
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      body: Center(
        child: _receivedDate == null
            ? const Text(
                'Deep Linkを待機中...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('受信した日付', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    _receivedDate!,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
