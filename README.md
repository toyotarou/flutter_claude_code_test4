# Flutter Deep Link 学習プロジェクト（Claude Code テスト4）

Flutter における **アプリ間 Deep Link 通信** を学習するための Claude Code テストプロジェクトです。  
カスタム URL スキームを用いて、app1（送信側）から app2（受信側）へ日付データを渡す仕組みを実装します。

---

## リポジトリ構成

```
flutter_claude_code_test4/
├── app1/          # 送信側アプリ（url_launcher で Deep Link を発行）
├── app2/          # 受信側アプリ（app_links で Deep Link を受信）
├── prompts.md     # 11 プロンプトによる開発履歴
└── memo.md        # 既存アプリへの Deep Link 追加手順・添削内容
```

---

## アプリ概要

### app1 — 送信側

| 項目 | 内容 |
|------|------|
| 主な機能 | 日付リストを表示し、タップすると app2 へ Deep Link を送信 |
| 使用パッケージ | `url_launcher ^6.3.1` |
| URL スキーム | `app2://date/{date}` |

**実装ポイント**

- `ListView` で日付一覧を表示
- セルタップ時に `url_launcher` の `launchUrl` で `app2://date/2026-01-01` 形式の URI を発行
- OS がスキームを解決し、app2 を起動（または前面に持ってくる）

### app2 — 受信側

| 項目 | 内容 |
|------|------|
| 主な機能 | 2026年全日付リストを表示し、Deep Link 受信時に該当日付へスクロール＋ダイアログ表示 |
| 使用パッケージ | `app_links ^6.4.0` |
| URL スキーム | `app2://date/{date}` |

**実装ポイント**

- `AppLinks().getInitialLink()` — コールドスタート時のリンク取得
- `AppLinks().uriLinkStream.listen()` — ホットスタート時（バックグラウンドから復帰）のリンク受信
- `addPostFrameCallback` — ビルド完了後にダイアログ表示・スクロールを実行
- `_launchedFromDeepLink` フラグ — Deep Link 経由起動時のみ「✕ 閉じる」ボタンを表示

---

## カスタム URL スキームの設定

### Android（app2/android/app/src/main/AndroidManifest.xml）

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="app2" />
</intent-filter>
```

app1 側の `<queries>` ブロックにもスキームを追加：

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="app2" />
    </intent>
</queries>
```

### iOS（app2/ios/Runner/Info.plist）

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>app2</string>
        </array>
    </dict>
</array>
```

---

## Deep Link の全体フロー

```
[app1] タップ
   ↓ launchUrl("app2://date/2026-03-15")
[OS] スキーム解決
   ↓ intent-filter / CFBundleURLTypes でマッチ
[app2] 起動 or 前面化
   ↓ getInitialLink() or uriLinkStream
[app2] パスから日付を抽出
   ↓ addPostFrameCallback
[app2] 該当日付へスクロール + ダイアログ表示
```

---

## 開発履歴（11 プロンプト）

`prompts.md` に全プロンプトと対応内容が記録されています。主な段階：

1. app1 の基本画面（日付リスト）を作成
2. app2 の基本画面（2026年全日付リスト）を作成
3. app1 に `url_launcher` を導入し Deep Link 送信を実装
4. app2 に `app_links` を導入し Deep Link 受信を実装
5. コールドスタート・ホットスタート両対応
6. `addPostFrameCallback` によるビルド完了後処理
7. `_launchedFromDeepLink` フラグで UI を制御
8. Android `<queries>` ブロック追加
9. iOS `CFBundleURLTypes` 設定
10. スキーム名のルール確認（アンダースコア不可・ハイフン使用）
11. 全体の動作確認・コード整理

---

## よくある失敗パターン・注意事項

| 問題 | 原因 | 対処 |
|------|------|------|
| Android で `launchUrl` がエラー | `<queries>` 未設定 | AndroidManifest.xml に `<queries>` を追加 |
| iOS でリンクが開かない | `CFBundleURLTypes` 未設定 | Info.plist に URL スキームを追加 |
| ダイアログが表示されない | ビルド前に `showDialog` を呼んでいる | `addPostFrameCallback` 内で呼び出す |
| スキーム名が認識されない | アンダースコアを含む名前 | RFC 3986 に従いハイフンを使用 |
| コールドスタート時に受信できない | `uriLinkStream` のみ使用 | `getInitialLink()` も必ず呼び出す |

---

## セットアップ

### 前提条件

- Flutter SDK（最新安定版）
- Android Studio または Xcode

### 手順

```bash
# app1 のセットアップ
cd app1
flutter pub get
flutter run

# app2 のセットアップ（別デバイスまたはシミュレーター）
cd app2
flutter pub get
flutter run
```

---

## 参考

- `memo.md` — 既存アプリへ Deep Link を追加する際の手順書（添削内容含む）
- `prompts.md` — Claude Code との開発セッション全プロンプト
