# Deep Link 追加手順メモ

## 前提

### アプリA: `flutter_lifetime_log2`（送信側）

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="flutter_lifetime_log2"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### アプリB: `flutter_temple6`（受信側）

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="flutter_temple6"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon"
        android:enableOnBackInvokedCallback="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

## やること

### 1. アプリA にパッケージを追加

`url_launcher` を追加する。

### 2. アプリB にパッケージを追加

`app_links` を追加する。

### 3. アプリA の AndroidManifest を修正

既存の `<queries>` ブロックの中に追記する（新しいブロックは作らない）。

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <!-- ↓追加 -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="flutter-temple6"/>
    </intent>
</queries>
```

### 4. アプリB の AndroidManifest を修正

既存の `<activity android:name=".MainActivity">` の中に追記する（新しい activity は作らない）。

```xml
<activity android:name=".MainActivity" ...>
    <!-- 既存のLAUNCHER intent-filter -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    <!-- ↓追加 -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="flutter-temple6" android:host="date"/>
    </intent-filter>
</activity>
```

### 5. アプリA のコードに追加

```dart
final Uri uri = Uri(scheme: 'flutter-temple6', host: 'date', path: '/$date');
if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  debugPrint('Could not launch $uri');
}
```

### 6. アプリB のコードに追加

```dart
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
  _linkSub = _appLinks.uriLinkStream.listen((Uri uri) {
    if (uri.toString() == initialUri?.toString()) {
      return; // 二重処理を防ぐ
    }
    _handleUri(uri);
  });
}

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
```

---

## 注意点

- schemeにアンダースコア（`_`）は使用不可（RFC 3986）。`flutter-temple6` のようにハイフンを使う。
- `<queries>` ブロックは既存のものに追記する（重複させない）。
- `<intent-filter>` は既存の `<activity>` タグの中に追記する。
- `_initDeepLink()` では `getInitialLink()`（終了状態からの起動）と `uriLinkStream`（起動中の受信）の両方を処理する必要がある。

---

## 添削内容

### 指摘1: Step 3 — `<queries>` ブロックを重複させてはいけない

**誤り:** 新しい `<queries>` ブロックを追加しようとしていた。

**正しくは:** AndroidManifest には既に `<queries>` ブロックが存在するため、新しいブロックを作るのではなく、**既存のブロックの中に `<intent>` を追記する**。

---

### 指摘2: Step 4 — 既存の `<activity>` への追記であることを明記する

**誤り:** `<activity ... >` の記述が曖昧で、新しい `<activity>` を追加するように読める可能性があった。

**正しくは:** Deep Link用の `<intent-filter>` は、**既存の `<activity android:name=".MainActivity">` タグの内側**に追記する。新しい `<activity>` は作らない。

---

### 指摘3: Step 6 — 閉じカッコ漏れ＋stream listener の記述漏れ

**誤り（1）:** `_initDeepLink()` の閉じカッコ `}` が1つ足りなかった。また、`_handleUri` が `_initDeepLink` の内側にあるように見えていた。

**誤り（2）:** **アプリが起動中（フォアグラウンド・バックグラウンド）にDeep Linkを受信するケース**が抜けていた。

**正しくは:** `getInitialLink()`（終了状態からの起動）だけでなく、`uriLinkStream.listen()`（起動中の受信）も必ず実装する。また、同じURIが両方に流れてくる場合の二重処理防止も必要。

```dart
// 起動中の受信ケース（これが抜けていた）
_linkSub = _appLinks.uriLinkStream.listen((Uri uri) {
  if (uri.toString() == initialUri?.toString()) {
    return; // 二重処理を防ぐ
  }
  _handleUri(uri);
});
```

---

### 指摘4: schemeにアンダースコアは使用不可（RFC 3986）

**誤り:** scheme名に `flutter_temple6`（アンダースコア）を使おうとしていた。

**正しくは:** URIスキームで使用できる文字は英数字・`+`・`-`・`.` のみ（RFC 3986）。アンダースコア `_` は仕様外。

```
NG: flutter_temple6
OK: flutter-temple6
```

---

### 添削まとめ

| # | 内容 | 評価 |
|---|------|------|
| Step 1, 2 | パッケージの追加先（url_launcher / app_links） | 正しい |
| Step 3 | `<queries>` の追記 | 既存ブロックへの追記と明記が必要だった |
| Step 4 | `<intent-filter>` の追記 | 既存 activity への追記と明記が必要だった |
| Step 5 | App A の URL生成・起動コード | 正しい |
| Step 6 | App B の Deep Link処理 | 閉じカッコ漏れ・stream listener が抜けていた |
| scheme名 | `flutter_temple6` | アンダースコアは URI スキームで使用不可 |
