# Prompts

## 1. App1・App2の作成と日付リスト表示

**プロンプト:**
> FlutterのDeep Linkの学習がしたいです。
> このディレクトリに、App1とApp2というディレクトリを作成して、
> App1には暫定的に、今月の日付のリストを「2026-02-01」「2026-02-02」みたいに表示してください。

**対応内容:** App1・App2のFlutterプロジェクト作成。App1に2026年2月の日付リストを表示するUIを実装。

## 2. Deep Linkによるアプリ間連携（App1 → App2）

**プロンプト:**
> では次に、app2を作成してください。
> こちらは受信側です。
> app1の日付をタップしたら、app2が起動して、引数として受け取った日付を呼び出せるようにしてください。

**対応内容:** カスタムURLスキーム（`app2://date/{date}`）を使いApp1からApp2をDeep Linkで起動。App2はapp_linksパッケージで受信し日付を画面表示。

## 3. Deep Linkのエラー対応とテスト方法の確認

**プロンプト:**
> MissingPluginExceptionエラーが出た。androidエミュレータで実行中。app2はバックグラウンドで実行している。実機でapp1の日付をタップしたときにapp2は起動していないが大丈夫か？

**対応内容:** MissingPluginExceptionはプラグイン追加後のフルリビルド不足が原因。`flutter run` で再起動すると解消。実機でApp2が起動しないのは正常（App2が未インストールのため）。Deep Linkのテストには同一デバイスへの両アプリのインストールが必要。`flutter run` はインストール目的で一度実行しCtrl+Cで止める使い方が有効。

## 4. App2からApp1に戻るXボタンの実装

**プロンプト:**
> app2からapp1に戻る処理を作ってください。app2を閉じるだけでいいんですかね？app2の右上にバツボタンを設置して、タップしたら、app2が落ちるようにしたらいいんですかね？

**対応内容:** App2のAppBar右上にXボタン（`Icons.close`）を追加。`SystemNavigator.pop()` でApp2を終了。AndroidではタスクバックスタックによりApp1が自動的に前面に戻る。iOSはURLスキーム起動時はバックスタック非共有のため自動復帰しない。

## 5. ホットリロード後の再起動でXボタンが消える問題

**プロンプト:**
> app2でリロードしたらバツボタンは出たので、それを使ってapp2を閉じたのですが、app1の他の日付をタップしたら、バツボタンのないapp2が開きました。キャッシュみたいなのが残っているということですよね？

**対応内容:** ホットリロードは実行中プロセス内のDartコードのみ更新し、インストール済みAPKは更新されない。App2終了後に再起動すると古いAPKから起動するためXボタンが消える。`flutter run` でフルリビルド＆再インストールすることで解消。

---

## このサンプルのポイントまとめ

**プロンプト:**
> prompts.mdに追記する形で、今回のサンプルのポイントを記述してください。AndroidManifest.xmlを触っていたのがポイントになりますか？あと、app1かapp2のどちらかに、パッケージ追加もしましたっけ？

### 追加パッケージ

| アプリ | パッケージ | 役割 |
|---|---|---|
| App1 | `url_launcher` | URLスキームで他アプリを起動する（送信側） |
| App2 | `app_links` | Deep LinkのURIを受け取る（受信側） |

### ネイティブ設定ファイルの変更

**AndroidManifest.xml（Android）**

| アプリ | 変更内容 | 理由 |
|---|---|---|
| App1 | `<queries>` に `app2` スキームを追加 | Android 11以降、呼び出し先スキームを事前申告しないと `launchUrl` が失敗する |
| App2 | `<intent-filter>` に `app2://date/` を登録 | OSに「このアプリが `app2://` を処理する」と宣言する |

**Info.plist（iOS）**

| アプリ | 変更内容 |
|---|---|
| App2のみ | `CFBundleURLTypes` に `app2` スキームを登録 |

### Deep Linkの全体構造

```
App1（送信）
  url_launcher で app2://date/2026-02-15 を開く
  AndroidManifest: <queries> で app2 スキームを申告

  ↓ OSがスキームを解決

App2（受信）
  AndroidManifest: <intent-filter> でapp2スキームを宣言
  Info.plist: CFBundleURLTypes でiOS側に宣言
  app_links で起動時・フォアグラウンド時のURIを両方ハンドル
  pathSegments[0] から日付を取り出して画面表示
```

### 学習で気づいたこと

- **パッケージ追加後は `flutter run` でフルリビルドが必要**（ホットリロード不可）
- **Deep Linkのテストは同一デバイスへの両アプリインストールが前提**
- **Androidはバックスタックで自動的に呼び出し元に戻るが、iOSは自動復帰しない**
- **ホットリロードはAPKを更新しないため、アプリ再起動後は古いコードで動く**

## 6. App2を独立したアプリに改修・Deep Linkでダイアログを開く

**プロンプト:**
> app2も「2026-02-01」「2026-02-02」みたいなリストになっていて、日付の列をタップするとapp2の中でダイアログが開いて、その中に選択された日付が表示されるようになっているとします。このダイアログが開いた状態をapp1からの呼び出し起動で実現したいと思います。

**対応内容:** App2を受信専用から独立したアプリに改修。日付リストを表示し、タップ時にダイアログを表示。Deep Link受信時も同じ `_showDateDialog()` を呼ぶことで、App1からの起動でも同一のダイアログが開く。コールドスタート（終了状態からの起動）時は `addPostFrameCallback` でWidgetビルド完了後にダイアログを表示。

## 7. バツボタンをDeep Link起動時のみ表示

**プロンプト:**
> app2を個別のアプリとして起動した場合にもヘッダーにバツボタンが表示されているが、バツボタンはdeep linkで開いた時だけに出るようにしてください。

**対応内容:** `_launchedFromDeepLink` フラグを追加。Deep Link受信時（`_handleUri`）に `true` にセットし、AppBarの `actions` を `if (_launchedFromDeepLink)` で条件分岐。個別起動時はXボタンが非表示になる。

## 8. ダイアログの二重表示バグ修正

**プロンプト:**
> app2のダイアログが二重で開かれています。おかしいので直してください。

**対応内容:** `getInitialLink()` と `uriLinkStream` の両方が同じURIを処理することで二重呼び出しが発生していた。Streamのリスナーで受信したURIが初期リンクと一致する場合は `return` でスキップするよう修正。

## 9. prompts.mdへの自動追記ルール化

**プロンプト:**
> 私のプロンプトと対応のタイトルをprompts.mdに自動追記しておいてくださいね。もし記述忘れがあったら、振り返れる分、全て記録しておいてください。

**対応内容:** ## 8（二重表示バグ）と ## 9（本項目）を追記。以降はプロンプトへの対応ごとに自動で記録する。

## 10. App2のリストを2026年全日付に拡張・Deep Linkでスクロール

**プロンプト:**
> app2を2026年全てのリスト（2026-01-01 -> 2026-12-31）にしてください。
> app1からは「2026-02-01」のように引数が渡されるので、app2のリストをその位置までスクロールするようにしてください。

**対応内容:** `februaryDates` を廃止し `_buildAllDates()` に置き換え（`DateTime` で1/1〜12/31を生成）。スクロール用に `ScrollController` を追加。`ListView.separated` → `ListView.builder`（`itemExtent: 57.0`）に変更し、インデックス×固定高さでオフセットを正確に計算。`_scrollToDate()` を新設し `_handleUri()` 内でダイアログ表示前に呼び出す。コールドスタート時も `addPostFrameCallback` でスクロールが正常動作。

## 11. App2個別起動時に本日の日付へ自動スクロール

**プロンプト:**
> app2を個別起動した時にも本日までスクロールするようにしてください。

**対応内容:** `_initDeepLink()` で `getInitialLink()` が `null`（Deep Linkなし）だった場合、`addPostFrameCallback` で `_scrollToToday()` を呼ぶよう修正。`_scrollToToday()` は `DateTime.now()` から今日の日付文字列を生成し `_scrollToDate()` に渡す。Deep Link起動時は従来通り引数の日付へスクロール。

---

## OSによるスキーム解決の仕組み

`↓ OSがスキームを解決` という部分の詳細。

### スキームはいつ・何を登録するのか？

「アプリの名前」ではなく、**そのアプリが処理できるスキームの文字列**を、**インストール時**にOSに登録する。

### 登録方法

**Android（AndroidManifest.xml）**

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="app2" />  <!-- ← "app2://" をこのアプリが処理する -->
</intent-filter>
```

**iOS（Info.plist）**

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>app2</string>  <!-- ← "app2://" をこのアプリが処理する -->
</array>
```

### 全体の流れ

```
① アプリをインストール
      ↓
② OSがManifest / Info.plistを読み込み
      ↓
③ 「app2:// → このアプリ」をOS内部のテーブルに登録
      ↓
④ 誰かが app2://... を開こうとする（url_launcherなど）
      ↓
⑤ OSがテーブルを検索 → 対応アプリを起動
```

### スキームが競合したら？

同じスキームを複数のアプリが登録した場合：

| OS | 挙動 |
|---|---|
| Android | 選択ダイアログが表示される |
| iOS | 先にインストールしたアプリが優先（後から入れたアプリは無視される） |

→ これがカスタムスキームの欠点。本番アプリでは `https://` ベースの **App Links（Android）/ Universal Links（iOS）** が推奨される。

---

## 既存アプリへの Deep Link 追加方法

> **注意:** 以下は汎用的な手順であり、このプロジェクトの app1・app2 とは関係しない。
> 実運用での「既存アプリ2本にDeep Linkを追加する」ケースを想定した内容。

---

### 登場人物の整理

| 役割 | 説明 |
|---|---|
| **送信側アプリ** | Deep Linkを生成して他のアプリを起動する側 |
| **受信側アプリ** | Deep Linkを受け取って処理する側 |

2本のアプリで役割が固定される。送信側だけ・受信側だけを改修する場合も手順は同じ。

---

### 全体の作業マップ

```
送信側アプリ                        受信側アプリ
─────────────────────────           ──────────────────────────────
① url_launcher を追加          ④ app_links を追加
② AndroidManifest に            ⑤ AndroidManifest に
   <queries> を追記                 <intent-filter> を追記
③ launchUrl を呼ぶコードを追加  ⑥（iOS）Info.plist に
                                    CFBundleURLTypes を追記
                                ⑦ _initDeepLink() を実装
                                ⑧ _handleUri() を実装
```

---

### 送信側アプリへの追加

#### ① url_launcher を追加

```yaml
# pubspec.yaml
dependencies:
  url_launcher: ^6.x.x
```

#### ② AndroidManifest.xml の `<queries>` に追記

既存の `<queries>` ブロックがあれば、**その中に追記する**（新しいブロックを作らない）。

```xml
<queries>
    <!-- 既存の <intent> はそのまま残す -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <!-- ↓ 追加: 受信側アプリのスキームを申告 -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="受信側のスキーム名"/>
    </intent>
</queries>
```

> **なぜ必要か:** Android 11（API 30）以降、他アプリへのアクセスにはパッケージの可視性申告が必須。
> これがないと `launchUrl` が `false` を返して起動できない。

#### ③ launchUrl を呼ぶコードを追加

```dart
Future<void> _openOtherApp(String param) async {
  final Uri uri = Uri(
    scheme: '受信側のスキーム名',  // 例: 'myapp-receiver'
    host: 'path-name',             // 例: 'date'
    path: '/$param',               // 例: '/2026-02-15'
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $uri');
  }
}
```

> **`LaunchMode.externalApplication` を指定する理由:**
> これを省略するとWebViewやブラウザで開こうとする。
> 別アプリを起動したい場合は必ず指定する。

---

### 受信側アプリへの追加

#### ④ app_links を追加

```yaml
# pubspec.yaml
dependencies:
  app_links: ^6.x.x
```

#### ⑤ AndroidManifest.xml の既存 `<activity>` に `<intent-filter>` を追記

**新しい `<activity>` を作るのではなく、既存の `.MainActivity` の中に追記する。**

```xml
<activity android:name=".MainActivity" ...>

    <!-- 既存の LAUNCHER intent-filter はそのまま残す -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- ↓ 追加: Deep Link受信用 -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="受信側のスキーム名" android:host="path-name"/>
    </intent-filter>

</activity>
```

> **`DEFAULT` と `BROWSABLE` が両方必要な理由:**
> - `DEFAULT`: 明示的なIntentで起動できるようにする
> - `BROWSABLE`: ブラウザや他アプリからのリンクで起動できるようにする
> この2つが揃って初めて外部から呼び出せる。

#### ⑥ iOS: Info.plist に CFBundleURLTypes を追加

`ios/Runner/Info.plist` に追記する。

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>受信側のスキーム名</string>
        </array>
    </dict>
</array>
```

#### ⑦ `_initDeepLink()` を実装

**アプリの状態は3パターンある。それぞれで処理が変わる。**

| アプリの状態 | 取得方法 |
|---|---|
| **コールドスタート**（完全終了状態から起動） | `getInitialLink()` |
| **フォアグラウンド / バックグラウンド**（起動中に受信） | `uriLinkStream.listen()` |

この2つを必ず両方実装する。どちらか1つだけでは対応できないケースが生まれる。

```dart
final AppLinks _appLinks = AppLinks();
StreamSubscription<Uri>? _linkSub;

@override
void initState() {
  super.initState();
  _initDeepLink(); // ← initState で必ず呼ぶ
}

Future<void> _initDeepLink() async {
  // ── コールドスタート ──
  final Uri? initialUri = await _appLinks.getInitialLink();
  if (initialUri != null) {
    // Widgetのビルドが完了してから処理する（ビルド前に setState 等を呼ぶとエラー）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleUri(initialUri);
    });
  } else {
    // Deep Linkなし（個別起動）の場合の処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _defaultAction(); // 例: 本日の日付へスクロール など
    });
  }

  // ── フォアグラウンド / バックグラウンド ──
  _linkSub = _appLinks.uriLinkStream.listen((Uri uri) {
    // getInitialLink と同じURIがStreamにも流れることがある → 二重処理を防ぐ
    if (uri.toString() == initialUri?.toString()) return;
    _handleUri(uri);
  });
}

@override
void dispose() {
  _linkSub?.cancel(); // ← 必ずキャンセルする（メモリリーク防止）
  super.dispose();
}
```

> **`addPostFrameCallback` が必要な理由:**
> `initState` の時点ではWidgetがまだ画面に描画されていない。
> この状態でスクロールやダイアログを呼ぶとエラーになる。
> `addPostFrameCallback` で「最初のフレーム描画完了後」に実行を遅らせる。

#### ⑧ `_handleUri()` を実装

```dart
void _handleUri(Uri uri) {
  // URIのパス部分からパラメータを取り出す
  // 例: myapp-receiver://date/2026-02-15 → pathSegments = ['2026-02-15']
  final List<String> segments = uri.pathSegments;
  if (segments.isNotEmpty) {
    final String param = segments.first;
    // 取り出した値で画面を操作する
    _doSomething(param);
  }
}
```

---

### スキーム名の命名ルール

URIスキームで使える文字はRFC 3986で定められている。

```
scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
```

| 記号 | 使用可否 |
|---|---|
| ハイフン `-` | 使用可 |
| ドット `.` | 使用可 |
| プラス `+` | 使用可 |
| アンダースコア `_` | **使用不可** |

```
NG: my_app_name    （アンダースコアは仕様外）
OK: my-app-name    （ハイフン区切り）
OK: myappname      （繋げる）
```

---

### 変更後に必要な作業

Deep Linkの設定はネイティブコード（AndroidManifest / Info.plist）の変更を含む。
**ホットリロードでは反映されない。必ず `flutter run` でフルリビルドする。**

```
# 両アプリ共通の手順
flutter pub get          # パッケージ追加後
flutter run              # フルリビルド＆再インストール
```

---

### よくある失敗パターン

| 症状 | 原因 | 対処 |
|---|---|---|
| `launchUrl` が `false` を返す | 送信側の `<queries>` 申告漏れ | AndroidManifest の `<queries>` にスキームを追加 |
| 受信側アプリが起動しない | 受信側の `<intent-filter>` 設定漏れ、またはアプリ未インストール | AndroidManifest を確認・両アプリを同一デバイスにインストール |
| ダイアログ等が二重表示される | `getInitialLink()` と `uriLinkStream` が同じURIを二重処理 | Stream側で `initialUri` と一致したら `return` でスキップ |
| パッケージ追加後にクラッシュ | `flutter run` でのフルリビルド不足 | `flutter run` を実行して再インストール |
| コールドスタート時にスクロール等が動かない | `initState` でWidgetがまだビルドされていない状態で呼び出している | `addPostFrameCallback` で遅延実行する |
