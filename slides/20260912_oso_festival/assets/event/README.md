# イベント案内素材

## 必須バナー

添付された公式バナー（660x371）をこのディレクトリの `banner.png` として配置します。`pubspec.yaml` には `assets/event/banner.png` を必須アセットとして登録済みです。11枚目のEventPageが `Image.asset` で読み込み、`BoxFit.contain` で縦横比を保って表示します。

差し替える場合もファイル名とパスを変えません。追加・差し替え後はリポジトリのルートで `dart pub get` と再ビルド（開発中は再起動）を行います。

## QRコード

QR画像ファイルは配置しません。12枚目のEventQrCardが、`lib/pages.dart` の `eventUrl`（https://flutterkaigi.connpass.com/event/401279/）を `qr_flutter` の `QrImageView(data: eventUrl)` に渡して実行時に生成します。同じURLを `url_launcher` の `Link` でクリックできます。

`qr.png`、`OptionalEventImage`、未配置時のフォールバックは使用しません。
