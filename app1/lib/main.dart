import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DateListPage(),
    );
  }
}

class DateListPage extends StatelessWidget {
  const DateListPage({super.key});

  List<String> get februaryDates {
    // ignore: always_specify_types
    return List.generate(28, (i) {
      final int day = i + 1;
      return '2026-02-${day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _openApp2(String date) async {
    // app2://date/2026-02-01 のURLでApp2を起動
    final Uri uri = Uri(scheme: 'app2', host: 'date', path: '/$date');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dates = februaryDates;
    return Scaffold(
      appBar: AppBar(
        title: const Text('2026年2月（タップでApp2へ）'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.separated(
        itemCount: dates.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final String date = dates[index];
          return ListTile(
            title: Text(date),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _openApp2(date),
          );
        },
      ),
    );
  }
}
