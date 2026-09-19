# FlutterKaigi mini エンディング

アンケート回答用のQRコードだけを表示する、16:9・全1枚のデッキです。
[LT](../20260919_flutterkaigi_mini_lt/README.md)のMaterialテーマ、Noto Sans JP、静止した幾何学背景を使用しています。

## 起動・確認

```sh
cd slides/20260919_flutterkaigi_mini_ed
flutter run -d chrome
dart analyze
flutter build web
```

公開先: https://yakitama5.github.io/flutter_deck_slides/20260919_flutterkaigi_mini_ed/

## QRコード

提供されたアンケートQR画像から読み取った次のURLを、`lib/main.dart`の`surveyUrl`に設定しています。
`qr_flutter`で描画し、投影時の鮮明さと周囲の白い余白を確保しています。

https://docs.google.com/forms/d/e/1FAIpQLSeWm5oxZdUvKWsszeu-KE_zff9TVDovJK7wd876L0MZ3hHvvA/viewform?pli=1

## テーマ・素材

`lib/theme.dart`と`lib/backdrop.dart`はLT側と同じ実装です。
文字・ページ番号・進行バー・発表者ツールバーはスライド上に表示しません。
Noto Sans JPには[SIL Open Font License](assets/fonts/OFL.txt)を同梱しています。
