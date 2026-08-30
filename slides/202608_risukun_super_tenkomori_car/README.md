# リスくんのスーパーてんこもりカー

10枚の完成画像を、共通のFlutterDeck Storybook演出で連続してめくる絵本デックです。

## ページ構成

画像は入力番号を数値順に固定し、`assets/risukun_super_tenkomori_car/`へPNGで統一しています。
各画像のページ番号とspeaker noteは`lib/main.dart`と`lib/speaker_notes.dart`で同じ順番に管理しています。

- 01: タイトル
- 02: レースの夢
- 03: 車をつくる
- 04: てんこもりカー完成
- 05: レースで故障
- 06: フクロウ博士
- 07: 新しい車
- 08: ゴール
- 09: YAGNIのくらべっこ
- 10: おしまいとエンジニア向け解説

前後のカバー、薄紙ページめくり、ページ描画音・効果音は`flutter_deck_storybook`を再利用しています。
